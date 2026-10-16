import html
import json
import os
import re
import sys
import urllib.parse
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET

from pathlib import Path
from datetime import datetime, timezone, date


# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_URL = "https://ginho83-wq.github.io/teste"
PROJECT_BASE = "/teste/"

OUTPUT_DIR = Path("build/web")
SITEMAP_PATH = OUTPUT_DIR / "sitemap.xml"

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

NOME_SITE = "Obra Livre — Obras Académicas"

URLS_FIXAS = [
    "/",
    "/acervo/",
    "/categorias/",
    "/termos/",
    "/politica-privacidade/",
    "/cookies/",
    "/contacto/",
    "/ajuda/",
]

NAMESPACE_SITEMAP = "http://www.sitemaps.org/schemas/sitemap/0.9"


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def texto_seguro(valor):
    if valor is None:
        return ""

    return str(valor).strip()


def escapar(valor):
    return html.escape(texto_seguro(valor), quote=True)


def url_absoluta(url):
    url = texto_seguro(url)

    if not url:
        return ""

    if url.startswith(("https://", "http://")):
        return url

    if url.startswith("//"):
        return "https:" + url

    if url.startswith("/"):
        return BASE_URL + url

    return BASE_URL + "/" + url


def url_pagina_obra(obra_id):
    obra_id = texto_seguro(obra_id)

    return (
        BASE_URL
        + "/obra/"
        + urllib.parse.quote(obra_id, safe="")
        + "/"
    )


def valor_inteiro(valor, padrao=0):
    try:
        return int(valor or padrao)
    except (TypeError, ValueError):
        return padrao


def data_iso_valida(valor):
    """
    Converte uma data ISO para YYYY-MM-DD.
    Devolve None quando o valor não é uma data válida.
    """
    valor = texto_seguro(valor)

    if not valor:
        return None

    try:
        data = datetime.fromisoformat(
            valor.replace("Z", "+00:00")
        )

        return data.date()

    except (ValueError, TypeError):
        try:
            return date.fromisoformat(valor[:10])
        except (ValueError, TypeError):
            return None


def formatar_data(valor):
    data = data_iso_valida(valor)

    if not data:
        return texto_seguro(valor)

    return data.strftime("%d/%m/%Y")


def descricao_seo(descricao, titulo, autor):
    """
    Gera uma descrição SEO com tamanho adequado.
    """
    descricao = " ".join(texto_seguro(descricao).split())

    if not descricao:
        descricao = f"Consulte a obra académica {titulo}"

        if autor:
            descricao += f", de {autor}"

        descricao += ", na plataforma Obra Livre."

    if len(descricao) > 160:
        descricao = descricao[:157].rsplit(" ", 1)[0] + "..."

    return descricao


def nome_arquivo_pdf(titulo):
    nome = texto_seguro(titulo)

    nome = re.sub(r'[\\/:*?"<>|]', "", nome)
    nome = "-".join(nome.split())
    nome = nome.strip(".-")

    if not nome:
        nome = "obra"

    if not nome.lower().endswith(".pdf"):
        nome += ".pdf"

    return nome


def url_download_pdf(url_pdf, titulo):
    """
    Acrescenta o parâmetro download aos URLs públicos
    do Supabase Storage, conservando os restantes
    parâmetros da consulta.
    """
    url_pdf = texto_seguro(url_pdf)

    if not url_pdf:
        return ""

    partes = urllib.parse.urlsplit(url_pdf)
    dominio = (partes.hostname or "").lower()

    armazenamento_supabase = (
        dominio.endswith(".supabase.co")
        and "/storage/v1/object/" in partes.path
    )

    if not armazenamento_supabase:
        return url_pdf

    parametros = urllib.parse.parse_qsl(
        partes.query,
        keep_blank_values=True,
    )

    parametros = [
        (chave, valor)
        for chave, valor in parametros
        if chave.lower() != "download"
    ]

    parametros.append(
        ("download", nome_arquivo_pdf(titulo))
    )

    return urllib.parse.urlunsplit(
        (
            partes.scheme,
            partes.netloc,
            partes.path,
            urllib.parse.urlencode(parametros),
            partes.fragment,
        )
    )


def formatar_tamanho(valor):
    try:
        tamanho = int(valor or 0)
    except (TypeError, ValueError):
        return ""

    if tamanho <= 0:
        return ""

    if tamanho < 1024:
        return f"{tamanho} bytes"

    if tamanho < 1024 * 1024:
        return f"{tamanho / 1024:.1f} KB"

    return f"{tamanho / (1024 * 1024):.2f} MB"


def normalizar_texto(valor):
    """
    Normaliza espaços para permitir comparar conteúdos.
    """
    return " ".join(texto_seguro(valor).split()).casefold()


def obter_data_atual():
    return datetime.now(timezone.utc).date().isoformat()


# ============================================================
# CONSULTA AO SUPABASE
# ============================================================

def obter_json(url):
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Configure SUPABASE_URL e SUPABASE_ANON_KEY."
        )

    pedido = urllib.request.Request(
        url,
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Accept": "application/json",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(
            pedido,
            timeout=60,
        ) as resposta:
            conteudo = resposta.read().decode("utf-8")
            return json.loads(conteudo)

    except urllib.error.HTTPError as erro:
        detalhe = erro.read().decode(
            "utf-8",
            errors="replace",
        )

        raise RuntimeError(
            f"Erro HTTP {erro.code}: {detalhe}"
        ) from erro

    except urllib.error.URLError as erro:
        raise RuntimeError(
            f"Não foi possível contactar o Supabase: {erro}"
        ) from erro


def consultar_tabela(tabela, parametros):
    query = urllib.parse.urlencode(
        parametros,
        doseq=True,
    )

    url = (
        f"{SUPABASE_URL}/rest/v1/"
        f"{tabela}?{query}"
    )

    resultado = obter_json(url)

    if not isinstance(resultado, list):
        raise RuntimeError(
            f"A consulta à tabela {tabela} "
            "não devolveu uma lista."
        )

    return resultado


# ============================================================
# OBRAS PUBLICADAS
# ============================================================

def obter_obras():
    return consultar_tabela(
        "obras",
        {
            "select": (
                "id,titulo,descricao,autor,categoria,"
                "url_documento,ano_obra,data_publicacao,"
                "numero_paginas,tamanho_arquivo_bytes,"
                "conteudo_texto,created_at,updated_at"
            ),
            "order": "created_at.desc",
        },
    )


# ============================================================
# SECÇÕES DA OBRA
# TABELA: public.teste_secoes
# ============================================================

def obter_secoes(obra_id):
    try:
        return consultar_tabela(
            "teste_secoes",
            {
                "select": (
                    "id,obra_id,titulo,conteudo,"
                    "ordem,nivel,paragrafo_ordem"
                ),
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar as secções "
            f"da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


def gerar_html_secoes(secoes):
    blocos = []

    secoes_ordenadas = sorted(
        secoes,
        key=lambda item: (
            valor_inteiro(item.get("ordem")),
            valor_inteiro(item.get("paragrafo_ordem")),
        ),
    )

    for secao in secoes_ordenadas:
        titulo = texto_seguro(secao.get("titulo"))
        conteudo = texto_seguro(secao.get("conteudo"))

        nivel = valor_inteiro(
            secao.get("nivel"),
            2,
        )

        nivel = max(2, min(nivel, 6))

        if titulo:
            blocos.append(
                f"<h{nivel}>{escapar(titulo)}</h{nivel}>"
            )

        if conteudo:
            paragrafos = re.split(
                r"\n\s*\n",
                conteudo,
            )

            for paragrafo in paragrafos:
                paragrafo = paragrafo.strip()

                if not paragrafo:
                    continue

                conteudo_html = escapar(paragrafo).replace(
                    "\n",
                    "<br>\n",
                )

                blocos.append(
                    f"<p>{conteudo_html}</p>"
                )

    return "\n".join(blocos)


# ============================================================
# IMAGENS DA OBRA
# TABELA: public.teste_imagens
# ============================================================

def obter_imagens(obra_id):
    try:
        return consultar_tabela(
            "teste_imagens",
            {
                "select": (
                    "id,obra_id,url_imagem,legenda,"
                    "posicao,ordem,fonte,paragrafo_ordem"
                ),
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar as imagens "
            f"da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


def gerar_html_imagens(imagens):
    blocos = []

    imagens_ordenadas = sorted(
        imagens,
        key=lambda item: (
            valor_inteiro(
                item.get("paragrafo_ordem"),
                999999,
            ),
            valor_inteiro(item.get("ordem")),
        ),
    )

    for imagem in imagens_ordenadas:
        url_imagem = (
            imagem.get("url_imagem")
            or imagem.get("url")
            or imagem.get("imagem_url")
        )

        if not url_imagem:
            continue

        url_imagem = url_absoluta(url_imagem)

        legenda = texto_seguro(
            imagem.get("legenda")
            or imagem.get("descricao")
            or imagem.get("titulo")
        )

        fonte = texto_seguro(imagem.get("fonte"))

        bloco = (
            "<figure>"
            f'<img src="{escapar(url_imagem)}" '
            f'alt="{escapar(legenda or "Imagem da obra")}" '
            'loading="lazy">'
        )

        if legenda:
            bloco += (
                f"<figcaption>{escapar(legenda)}</figcaption>"
            )

        if fonte:
            bloco += (
                '<p class="fonte-imagem">'
                f"Fonte: {escapar(fonte)}</p>"
            )

        bloco += "</figure>"

        blocos.append(bloco)

    return "\n".join(blocos)


# ============================================================
# OBRAS RELACIONADAS
# ============================================================

def obter_obras_relacionadas(
    obra,
    todas_obras,
    limite=5,
):
    obra_id = texto_seguro(obra.get("id"))

    categoria = texto_seguro(
        obra.get("categoria")
    ).casefold()

    autor = texto_seguro(
        obra.get("autor")
    ).casefold()

    relacionadas = []

    for outra in todas_obras:
        outro_id = texto_seguro(outra.get("id"))

        if not outro_id or outro_id == obra_id:
            continue

        pontos = 0

        outra_categoria = texto_seguro(
            outra.get("categoria")
        ).casefold()

        outro_autor = texto_seguro(
            outra.get("autor")
        ).casefold()

        if categoria and outra_categoria == categoria:
            pontos += 2

        if autor and outro_autor == autor:
            pontos += 3

        if pontos > 0:
            relacionadas.append((pontos, outra))

    relacionadas.sort(
        key=lambda item: (
            -item[0],
            texto_seguro(
                item[1].get("titulo")
            ).casefold(),
        )
    )

    selecionadas = [
        item[1]
        for item in relacionadas[:limite]
    ]

    if len(selecionadas) < limite:
        ids_existentes = {
            texto_seguro(item.get("id"))
            for item in selecionadas
        }

        for outra in todas_obras:
            outro_id = texto_seguro(outra.get("id"))

            if not outro_id or outro_id == obra_id:
                continue

            if outro_id in ids_existentes:
                continue

            selecionadas.append(outra)
            ids_existentes.add(outro_id)

            if len(selecionadas) >= limite:
                break

    return selecionadas


def gerar_html_relacionadas(obras_relacionadas):
    if not obras_relacionadas:
        return ""

    blocos = []

    for obra in obras_relacionadas:
        obra_id = texto_seguro(obra.get("id"))
        titulo = texto_seguro(obra.get("titulo"))

        if not obra_id or not titulo:
            continue

        url = url_pagina_obra(obra_id)

        autor = texto_seguro(obra.get("autor"))
        categoria = texto_seguro(obra.get("categoria"))

        detalhes = []

        if autor:
            detalhes.append(
                f"Autor: {escapar(autor)}"
            )

        if categoria:
            detalhes.append(
                f"Categoria: {escapar(categoria)}"
            )

        detalhes_html = ""

        if detalhes:
            detalhes_html = (
                '<p class="relacionada-detalhes">'
                + " • ".join(detalhes)
                + "</p>"
            )

        blocos.append(
            '<article class="obra-relacionada">'
            f'<h3><a href="{escapar(url)}">'
            f"{escapar(titulo)}</a></h3>"
            f"{detalhes_html}"
            "</article>"
        )

    if not blocos:
        return ""

    return (
        '<section class="relacionadas">'
        "<h2>Obras relacionadas</h2>"
        + "\n".join(blocos)
        + "</section>"
    )


# ============================================================
# DADOS ESTRUTURADOS
# ============================================================

def tipo_schema(categoria):
    """
    Escolhe um tipo Schema.org conservador para cada categoria.
    """
    categoria = texto_seguro(categoria).casefold()

    if "artigo" in categoria:
        return "ScholarlyArticle"

    if "comunica" in categoria:
        return "ScholarlyArticle"

    if "tese" in categoria:
        return "Thesis"

    if "disserta" in categoria:
        return "Thesis"

    if "monografia" in categoria:
        return "CreativeWork"

    if "relatório" in categoria or "relatorio" in categoria:
        return "Report"

    if "poster" in categoria or "pôster" in categoria:
        return "CreativeWork"

    return "CreativeWork"


def gerar_json_ld(
    titulo,
    descricao,
    url_pagina,
    autor,
    categoria,
    data_publicacao,
    url_pdf,
):
    metadados = {
        "@context": "https://schema.org",
        "@type": tipo_schema(categoria),
        "name": titulo,
        "headline": titulo,
        "description": descricao,
        "url": url_pagina,
        "inLanguage": "pt",
        "publisher": {
            "@type": "Organization",
            "name": NOME_SITE,
            "url": BASE_URL + "/",
        },
    }

    if autor:
        metadados["author"] = {
            "@type": "Person",
            "name": autor,
        }

    if categoria:
        metadados["genre"] = categoria

    data = data_iso_valida(data_publicacao)

    if data:
        metadados["datePublished"] = data.isoformat()

    if url_pdf:
        metadados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": url_pdf,
            "encodingFormat": "application/pdf",
        }

    return json.dumps(
        metadados,
        ensure_ascii=False,
    ).replace("</", "<\\/")


# ============================================================
# GERAR PÁGINA SEO INDIVIDUAL
# ============================================================

def gerar_pagina_obra(obra, todas_obras):
    obra_id = texto_seguro(obra.get("id"))
    titulo = texto_seguro(obra.get("titulo"))

    if not obra_id or not titulo:
        print(
            "Aviso: obra sem ID ou título; ignorada.",
            file=sys.stderr,
        )
        return None

    if not re.fullmatch(r"[A-Za-z0-9_-]+", obra_id):
        print(
            f"Aviso: ID de obra inválido: {obra_id}",
            file=sys.stderr,
        )
        return None

    autor = texto_seguro(obra.get("autor"))
    categoria = texto_seguro(obra.get("categoria"))
    descricao = texto_seguro(obra.get("descricao"))
    ano = texto_seguro(obra.get("ano_obra"))

    data_publicacao = texto_seguro(
        obra.get("data_publicacao")
    )

    url_pdf_original = texto_seguro(
        obra.get("url_documento")
    )

    url_pdf_leitura = url_absoluta(url_pdf_original)

    url_pdf_download = url_download_pdf(
        url_pdf_original,
        titulo,
    )

    url_pagina = url_pagina_obra(obra_id)

    descricao_meta = descricao_seo(
        descricao,
        titulo,
        autor,
    )

    secoes = obter_secoes(obra_id)
    imagens = obter_imagens(obra_id)

    print(
        f"[SEO] {titulo} | "
        f"Secções: {len(secoes)} | "
        f"Imagens: {len(imagens)}"
    )

    html_secoes = gerar_html_secoes(secoes)
    html_imagens = gerar_html_imagens(imagens)

    conteudo_texto = texto_seguro(
        obra.get("conteudo_texto")
    )

    # Evita apresentar o mesmo conteúdo duas vezes.
    conteudo_secoes = "\n".join(
        texto_seguro(secao.get("conteudo"))
        for secao in secoes
    )

    if (
        conteudo_texto
        and conteudo_secoes
        and normalizar_texto(conteudo_texto)
        == normalizar_texto(conteudo_secoes)
    ):
        conteudo_texto = ""

    numero_paginas = texto_seguro(
        obra.get("numero_paginas")
    )

    tamanho_arquivo = formatar_tamanho(
        obra.get("tamanho_arquivo_bytes")
    )

    obras_relacionadas = obter_obras_relacionadas(
        obra,
        todas_obras,
    )

    html_relacionadas = gerar_html_relacionadas(
        obras_relacionadas
    )

    # --------------------------------------------------------
    # BOTÕES DO PDF
    # --------------------------------------------------------

    if url_pdf_leitura:
        botoes_pdf = f"""
        <div class="botoes-pdf">
            <a class="botao"
               href="{escapar(url_pdf_leitura)}"
               target="_blank"
               rel="noopener noreferrer">
                Ler PDF
            </a>

            <a class="botao botao-secundario"
               href="{escapar(url_pdf_download)}">
                Descarregar PDF
            </a>
        </div>
        """
    else:
        botoes_pdf = """
        <p class="aviso">
            O documento PDF não está disponível.
        </p>
        """

    # --------------------------------------------------------
    # CONTEÚDO TEXTUAL
    # --------------------------------------------------------

    if conteudo_texto:
        html_conteudo = f"""
        <section class="conteudo-obra">
            <h2>Conteúdo da obra</h2>
            <div class="texto-obra">{escapar(conteudo_texto)}</div>
        </section>
        """
    else:
        html_conteudo = ""

    if html_secoes:
        html_secoes_completo = f"""
        <section class="secoes-obra">
            <h2>Secções da obra</h2>
            {html_secoes}
        </section>
        """
    else:
        html_secoes_completo = ""

    if html_imagens:
        html_imagens_completo = f"""
        <section class="imagens-obra">
            <h2>Imagens da obra</h2>
            {html_imagens}
        </section>
        """
    else:
        html_imagens_completo = ""

    # --------------------------------------------------------
    # INFORMAÇÕES TÉCNICAS
    # --------------------------------------------------------

    informacoes_tecnicas = []

    if numero_paginas:
        informacoes_tecnicas.append(
            f"""
            <div class="item-tecnico">
                <span>Número de páginas</span>
                <strong>{escapar(numero_paginas)}</strong>
            </div>
            """
        )

    if tamanho_arquivo:
        informacoes_tecnicas.append(
            f"""
            <div class="item-tecnico">
                <span>Tamanho do ficheiro</span>
                <strong>{escapar(tamanho_arquivo)}</strong>
            </div>
            """
        )

    if url_pdf_leitura:
        informacoes_tecnicas.append(
            """
            <div class="item-tecnico">
                <span>Formato do documento</span>
                <strong>PDF</strong>
            </div>
            """
        )

    if informacoes_tecnicas:
        html_tecnico = f"""
        <section class="informacoes-tecnicas">
            <h2>Informações técnicas</h2>
            <div class="grelha-tecnica">
                {"".join(informacoes_tecnicas)}
            </div>
        </section>
        """
    else:
        html_tecnico = ""

    data_publicacao_html = ""

    if data_publicacao:
        data_publicacao_html = f"""
        <p>
            <strong>Data de publicação:</strong>
            {escapar(formatar_data(data_publicacao))}
        </p>
        """

    # --------------------------------------------------------
    # DADOS ESTRUTURADOS JSON-LD
    # --------------------------------------------------------

    json_ld = gerar_json_ld(
        titulo=titulo,
        descricao=descricao_meta,
        url_pagina=url_pagina,
        autor=autor,
        categoria=categoria,
        data_publicacao=data_publicacao,
        url_pdf=url_pdf_leitura,
    )

    # --------------------------------------------------------
    # HTML FINAL
    # --------------------------------------------------------

    html_pagina = f"""<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>{escapar(titulo)} — {escapar(NOME_SITE)}</title>

    <meta name="description"
          content="{escapar(descricao_meta)}">

    <meta name="robots" content="index, follow">

    <link rel="canonical"
          href="{escapar(url_pagina)}">

    <link rel="icon"
          type="image/png"
          href="{PROJECT_BASE}OL.png">

    <meta property="og:type" content="article">
    <meta property="og:title" content="{escapar(titulo)}">
    <meta property="og:description"
          content="{escapar(descricao_meta)}">
    <meta property="og:url" content="{escapar(url_pagina)}">
    <meta property="og:site_name" content="{escapar(NOME_SITE)}">

    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="{escapar(titulo)}">
    <meta name="twitter:description"
          content="{escapar(descricao_meta)}">

    <script type="application/ld+json">
    {json_ld}
    </script>

    <style>
        * {{
            box-sizing: border-box;
        }}

        html {{
            scroll-behavior: smooth;
        }}

        body {{
            margin: 0;
            background: #f4f7fb;
            color: #243247;
            font-family: Arial, Helvetica, sans-serif;
            line-height: 1.75;
        }}

        header {{
            background: #eaf4ff;
            border-bottom: 1px solid #d5e5f5;
            padding: 18px 20px;
        }}

        .cabecalho-interior {{
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
        }}

        header a {{
            color: #124f86;
            text-decoration: none;
            font-weight: bold;
        }}

        .link-acervo {{
            font-size: 0.95rem;
        }}

        main {{
            width: calc(100% - 32px);
            max-width: 1000px;
            margin: 28px auto;
            padding: 30px;
            background: #ffffff;
            border: 1px solid #e1e8f0;
            border-radius: 12px;
            box-shadow: 0 3px 14px rgba(25, 55, 85, 0.04);
        }}

        h1 {{
            margin-top: 0;
            color: #183e62;
            line-height: 1.35;
            overflow-wrap: anywhere;
            font-size: clamp(1.7rem, 4vw, 2.3rem);
        }}

        h2, h3, h4, h5, h6 {{
            margin-top: 28px;
            margin-bottom: 12px;
            color: #183e62;
            line-height: 1.45;
            overflow-wrap: anywhere;
        }}

        p {{
            margin-top: 0;
            margin-bottom: 16px;
            overflow-wrap: anywhere;
        }}

        .metadados {{
            padding: 18px;
            background: #f6f9fc;
            border: 1px solid #e5edf5;
            border-radius: 8px;
            margin: 22px 0 28px;
        }}

        .metadados p {{
            margin: 5px 0;
        }}

        .descricao, .texto-obra {{
            white-space: pre-wrap;
            overflow-wrap: anywhere;
        }}

        .conteudo-obra,
        .secoes-obra,
        .imagens-obra,
        .informacoes-tecnicas {{
            margin-top: 30px;
        }}

        .secoes-obra p,
        .conteudo-obra p {{
            text-align: justify;
        }}

        .botoes-pdf {{
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin: 22px 0;
        }}

        .botao {{
            display: inline-block;
            padding: 12px 19px;
            border-radius: 7px;
            background: #145da0;
            color: #ffffff;
            text-decoration: none;
            font-weight: bold;
            text-align: center;
            transition: background 0.2s;
        }}

        .botao:hover {{
            background: #0d477e;
        }}

        .botao-secundario {{
            background: #167447;
        }}

        .botao-secundario:hover {{
            background: #105a36;
        }}

        .aviso {{
            padding: 14px;
            background: #fff7e6;
            border-radius: 7px;
            color: #795500;
        }}

        .grelha-tecnica {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
        }}

        .item-tecnico {{
            padding: 15px;
            background: #f6f9fc;
            border: 1px solid #e5edf5;
            border-radius: 8px;
        }}

        .item-tecnico span,
        .item-tecnico strong {{
            display: block;
        }}

        .item-tecnico span {{
            color: #526273;
            font-size: 0.9rem;
        }}

        figure {{
            margin: 26px 0;
            text-align: center;
        }}

        figure img {{
            display: block;
            max-width: 100%;
            max-height: 750px;
            height: auto;
            margin: auto;
            border-radius: 5px;
        }}

        figcaption {{
            margin-top: 8px;
            color: #526273;
            font-size: 0.92rem;
        }}

        .fonte-imagem {{
            margin-top: 4px;
            color: #65758a;
            font-size: 0.85rem;
        }}

        .relacionadas {{
            margin-top: 38px;
            padding-top: 20px;
            border-top: 1px solid #e1e8f0;
        }}

        .obra-relacionada {{
            padding: 15px 0;
            border-bottom: 1px solid #edf1f5;
        }}

        .obra-relacionada h3 {{
            margin: 0 0 5px;
            font-size: 1.05rem;
        }}

        .obra-relacionada h3 a {{
            color: #145da0;
            text-decoration: none;
        }}

        .obra-relacionada h3 a:hover {{
            text-decoration: underline;
        }}

        .relacionada-detalhes {{
            margin: 0;
            color: #526273;
            font-size: 0.9rem;
        }}

        .rodape {{
            margin-top: 35px;
            padding-top: 20px;
            border-top: 1px solid #e1e8f0;
            color: #526273;
            font-size: 0.95rem;
        }}

        .rodape a {{
            color: #145da0;
        }}

        a {{
            overflow-wrap: anywhere;
        }}

        @media (max-width: 600px) {{
            header {{
                padding: 14px;
            }}

            main {{
                width: calc(100% - 20px);
                margin: 12px auto;
                padding: 18px;
                border-radius: 8px;
            }}

            .botoes-pdf {{
                flex-direction: column;
            }}

            .botao {{
                width: 100%;
            }}

            .metadados {{
                padding: 14px;
            }}
        }}
    </style>
</head>

<body>

<header>
    <div class="cabecalho-interior">
        <a href="{PROJECT_BASE}">
            {escapar(NOME_SITE)}
        </a>

        <a class="link-acervo" href="{PROJECT_BASE}acervo/">
            Explorar acervo
        </a>
    </div>
</header>

<main>
    <article>
        <h1>{escapar(titulo)}</h1>

        <section class="metadados"
                 aria-label="Informações da obra">

            <p>
                <strong>Autor:</strong>
                {escapar(autor or "Não indicado")}
            </p>

            <p>
                <strong>Categoria:</strong>
                {escapar(categoria or "Não indicada")}
            </p>

            <p>
                <strong>Ano:</strong>
                {escapar(ano or "Não indicado")}
            </p>

            {data_publicacao_html}
        </section>

        <section class="descricao-obra">
            <h2>Descrição da obra</h2>
            <div class="descricao">{escapar(descricao) if descricao else "Não foi fornecida uma descrição para esta obra."}</div>
        </section>

        {html_conteudo}
        {html_secoes_completo}
        {html_imagens_completo}
        {html_tecnico}

        <section class="documento-completo">
            <h2>Documento completo</h2>

            <p>
                Pode abrir o documento PDF para leitura
                ou utilizar a opção de descarregamento.
            </p>

            {botoes_pdf}
        </section>

        {html_relacionadas}

    </article>

    <footer class="rodape">
        <p>
            Publicado na plataforma
            <a href="{PROJECT_BASE}">{escapar(NOME_SITE)}</a>.
        </p>

        <p>
            <a href="{PROJECT_BASE}acervo/">
                Regressar ao acervo
            </a>
        </p>
    </footer>
</main>

</body>
</html>
"""

    pasta = OUTPUT_DIR / "obra" / obra_id

    pasta.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho = pasta / "index.html"

    caminho.write_text(
        html_pagina,
        encoding="utf-8",
    )

    print(f"Página SEO gerada: {caminho}")

    return url_pagina


# ============================================================
# SITEMAP XML
# ============================================================

def gerar_sitemap(obras, urls_obras):
    ET.register_namespace("", NAMESPACE_SITEMAP)

    raiz = ET.Element(
        f"{{{NAMESPACE_SITEMAP}}}urlset"
    )

    hoje = obter_data_atual()

    datas_por_url = {}

    for obra, url in zip(obras, urls_obras):
        data = (
            data_iso_valida(obra.get("updated_at"))
            or data_iso_valida(obra.get("created_at"))
            or data_iso_valida(obra.get("data_publicacao"))
        )

        if data:
            datas_por_url[url] = data.isoformat()

    urls = [
        BASE_URL + rota
        for rota in URLS_FIXAS
    ]

    urls.extend(urls_obras)

    urls_unicas = list(dict.fromkeys(urls))

    for url in urls_unicas:
        if not url.startswith(BASE_URL + "/"):
            continue

        elemento_url = ET.SubElement(
            raiz,
            f"{{{NAMESPACE_SITEMAP}}}url",
        )

        elemento_loc = ET.SubElement(
            elemento_url,
            f"{{{NAMESPACE_SITEMAP}}}loc",
        )

        elemento_loc.text = url

        elemento_lastmod = ET.SubElement(
            elemento_url,
            f"{{{NAMESPACE_SITEMAP}}}lastmod",
        )

        # Nas páginas fixas, a data é a data de geração.
        # Nas obras, utiliza-se a data de atualização disponível.
        elemento_lastmod.text = datas_por_url.get(
            url,
            hoje,
        )

    arvore = ET.ElementTree(raiz)

    SITEMAP_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    arvore.write(
        SITEMAP_PATH,
        encoding="utf-8",
        xml_declaration=True,
    )

    print(f"Sitemap gerado: {SITEMAP_PATH}")
    print(f"URLs incluídos: {len(urls_unicas)}")


# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

def main():
    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    obras = obter_obras()

    print("=" * 65)
    print("GERAÇÃO DAS PÁGINAS SEO — OBRA LIVRE")
    print("=" * 65)
    print(f"Obras encontradas: {len(obras)}")

    urls_obras = []
    obras_processadas = []
    erros = 0

    for obra in obras:
        try:
            url = gerar_pagina_obra(
                obra,
                obras,
            )

            if url:
                urls_obras.append(url)
                obras_processadas.append(obra)

        except Exception as erro:
            erros += 1

            print(
                "Erro ao gerar a página da obra "
                f"{texto_seguro(obra.get('id'))}: {erro}",
                file=sys.stderr,
            )

    gerar_sitemap(
        obras_processadas,
        urls_obras,
    )

    print("-" * 65)
    print(f"Obras consultadas: {len(obras)}")
    print(f"Páginas geradas: {len(urls_obras)}")
    print(f"Erros de geração: {erros}")
    print("Geração SEO concluída.")
    print("=" * 65)


if __name__ == "__main__":
    try:
        main()

    except Exception as erro:
        print(
            f"ERRO FATAL: {erro}",
            file=sys.stderr,
        )
        sys.exit(1)

