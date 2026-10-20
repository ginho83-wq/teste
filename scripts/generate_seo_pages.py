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

BASE_DIR = Path(__file__).resolve().parent.parent

BASE_URL = "https://ginho83-wq.github.io/teste"
PROJECT_BASE = "/teste/"

OUTPUT_DIR = BASE_DIR / "build" / "web"
SITEMAP_PATH = OUTPUT_DIR / "sitemap.xml"

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
# CONFIGURAÇÃO SUPABASE
# ============================================================

SUPABASE_URL = os.getenv(
    "SUPABASE_URL", ""
).strip().rstrip("/")

SUPABASE_ANON_KEY = os.getenv(
    "SUPABASE_ANON_KEY", ""
).strip()


def carregar_configuracao_flutter():
    """
    Procura as configurações públicas do Supabase
    nos ficheiros Dart do projeto Flutter.
    """

    global SUPABASE_URL
    global SUPABASE_ANON_KEY

    if SUPABASE_URL and SUPABASE_ANON_KEY:
        return

    pasta_lib = BASE_DIR / "lib"

    if not pasta_lib.exists():
        return

    for ficheiro in pasta_lib.rglob("*.dart"):
        try:
            conteudo = ficheiro.read_text(
                encoding="utf-8-sig"
            )
        except (OSError, UnicodeError):
            continue

        if not SUPABASE_URL:
            correspondencia_url = re.search(
                r"""(?:url|supabaseUrl)\s*=\s*['"]([^'"]+)['"]""",
                conteudo,
                re.IGNORECASE,
            )

            if correspondencia_url:
                valor = correspondencia_url.group(1).strip()

                if valor.startswith("https://"):
                    SUPABASE_URL = valor.rstrip("/")

        if not SUPABASE_ANON_KEY:
            correspondencia_chave = re.search(
                r"""(?:publishableKey|anonKey|supabaseAnonKey)\s*=\s*['"]([^'"]+)['"]""",
                conteudo,
                re.IGNORECASE,
            )

            if correspondencia_chave:
                SUPABASE_ANON_KEY = (
                    correspondencia_chave.group(1).strip()
                )

        if SUPABASE_URL and SUPABASE_ANON_KEY:
            return


carregar_configuracao_flutter()


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
    return (
        BASE_URL
        + "/obra/"
        + urllib.parse.quote(texto_seguro(obra_id), safe="")
        + "/"
    )


def valor_inteiro(valor, padrao=0):
    try:
        return int(valor or padrao)
    except (TypeError, ValueError):
        return padrao


def data_iso_valida(valor):
    valor = texto_seguro(valor)

    if not valor:
        return None

    try:
        return datetime.fromisoformat(
            valor.replace("Z", "+00:00")
        ).date()
    except (ValueError, TypeError):
        try:
            return date.fromisoformat(valor[:10])
        except (ValueError, TypeError):
            return None


def formatar_data(valor):
    data_convertida = data_iso_valida(valor)

    if not data_convertida:
        return texto_seguro(valor)

    return data_convertida.strftime("%d/%m/%Y")


def descricao_seo(descricao, titulo, autor):
    descricao = " ".join(texto_seguro(descricao).split())

    if not descricao:
        descricao = f"Consulte a obra académica «{titulo}»"

        if autor:
            descricao += f", de {autor}"

        descricao += ", na plataforma Obra Livre."

    if len(descricao) > 160:
        descricao = descricao[:157].rsplit(" ", 1)[0] + "..."

    return descricao


def nome_arquivo_pdf(titulo):
    nome = texto_seguro(titulo)

    nome = re.sub(r'[\\/:*?"<>|]', "", nome)

    nome = "-".join(nome.split()).strip(".-")

    if not nome:
        nome = "obra"

    if not nome.lower().endswith(".pdf"):
        nome += ".pdf"

    return nome


def url_download_pdf(url_pdf, titulo):
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
    return " ".join(texto_seguro(valor).split()).casefold()


def obter_data_atual():
    return datetime.now(timezone.utc).date().isoformat()


# ============================================================
# CONSULTA AO SUPABASE
# ============================================================

def obter_json(url):
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Não foi possível obter as configurações do Supabase. "
            "Verifique SUPABASE_URL e SUPABASE_ANON_KEY "
            "ou o ficheiro SupabaseConfig do projeto Flutter."
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
    conteudos_processados = set()

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

        nivel = max(
            2,
            min(valor_inteiro(secao.get("nivel"), 2), 6),
        )

        chave_conteudo = normalizar_texto(conteudo)

        if conteudo and chave_conteudo in conteudos_processados:
            continue

        if conteudo:
            conteudos_processados.add(chave_conteudo)

        if titulo:
            blocos.append(
                f"<h{nivel}>{escapar(titulo)}</h{nivel}>"
            )

        if conteudo:
            paragrafos = re.split(r"\n\s*\n", conteudo)

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
                f"Fonte: {escapar(fonte)}"
                "</p>"
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

        if (
            categoria
            and texto_seguro(
                outra.get("categoria")
            ).casefold() == categoria
        ):
            pontos += 2

        if (
            autor
            and texto_seguro(
                outra.get("autor")
            ).casefold() == autor
        ):
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

    ids_existentes = {
        texto_seguro(item.get("id"))
        for item in selecionadas
    }

    if len(selecionadas) < limite:
        for outra in todas_obras:
            outro_id = texto_seguro(outra.get("id"))

            if (
                not outro_id
                or outro_id == obra_id
                or outro_id in ids_existentes
            ):
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
        detalhes = []

        autor = texto_seguro(obra.get("autor"))
        categoria = texto_seguro(obra.get("categoria"))

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
    categoria = texto_seguro(categoria).casefold()

    if "artigo" in categoria or "comunica" in categoria:
        return "ScholarlyArticle"

    if "tese" in categoria or "disserta" in categoria:
        return "Thesis"

    if "relatório" in categoria or "relatorio" in categoria:
        return "Report"

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

    data_convertida = data_iso_valida(data_publicacao)

    if data_convertida:
        metadados["datePublished"] = (
            data_convertida.isoformat()
        )

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
# ESTATÍSTICAS SEO — JAVASCRIPT
# ============================================================

def gerar_javascript_estatisticas(obra_id):
    """
    Regista eventos na função RPC:
    public.registar_obra_evento(p_obra_id, p_tipo_evento).

    Regista:
    - visualizacao
    - clique_pdf

    Utiliza apenas a chave pública do Supabase.
    """

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        print(
            "[SEO] AVISO: configuração Supabase incompleta. "
            "As estatísticas não serão ativadas.",
            file=sys.stderr,
        )
        return ""

    configuracao = json.dumps(
        {
            "supabaseUrl": SUPABASE_URL,
            "supabaseAnonKey": SUPABASE_ANON_KEY,
            "obraId": obra_id,
        },
        ensure_ascii=False,
    ).replace("</", "<\\/")

    return f"""
<script>
(function () {{
    "use strict";

    const config = {configuracao};

    const endpoint =
        config.supabaseUrl +
        "/rest/v1/rpc/registar_obra_evento";

    async function registarEvento(tipoEvento) {{
        try {{
            const resposta = await fetch(endpoint, {{
                method: "POST",
                headers: {{
                    "Content-Type": "application/json",
                    "apikey": config.supabaseAnonKey,
                    "Authorization": "Bearer " + config.supabaseAnonKey
                }},
                body: JSON.stringify({{
                    p_obra_id: config.obraId,
                    p_tipo_evento: tipoEvento
                }}),
                keepalive: true
            }});

            if (!resposta.ok) {{
                console.error(
                    "[Obra Livre] Erro ao registar evento:",
                    tipoEvento,
                    resposta.status,
                    await resposta.text()
                );
            }}
        }} catch (erro) {{
            console.error(
                "[Obra Livre] Falha de comunicação com Supabase:",
                erro
            );
        }}
    }}

    // Registar a visualização da página SEO.
    registarEvento("visualizacao");

    // Registar os cliques nos botões do PDF.
    document.addEventListener("click", function (evento) {{
        const link = evento.target.closest("[data-evento-pdf]");

        if (!link) {{
            return;
        }}

        registarEvento("clique_pdf");
    }});
}})();
</script>
"""


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

    if not re.fullmatch(
        r"[0-9a-fA-F]{8}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{12}",
        obra_id,
    ):
        print(
            f"Aviso: ID de obra não é UUID válido: {obra_id}",
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

    existe_conteudo_secoes = any(
        texto_seguro(secao.get("conteudo"))
        for secao in secoes
    )

    if existe_conteudo_secoes:
        html_conteudo_final = html_secoes

    elif conteudo_texto:
        paragrafos = re.split(
            r"\n\s*\n",
            conteudo_texto,
        )

        blocos_conteudo = []

        for paragrafo in paragrafos:
            paragrafo = paragrafo.strip()

            if paragrafo:
                blocos_conteudo.append(
                    "<p>"
                    + escapar(paragrafo).replace(
                        "\n",
                        "<br>\n",
                    )
                    + "</p>"
                )

        html_conteudo_final = "\n".join(
            blocos_conteudo
        )

    else:
        html_conteudo_final = ""

    if html_imagens:
        html_imagens_completo = f"""
        <section class="imagens-obra">
            <h2>Imagens da obra</h2>
            {html_imagens}
        </section>
        """
    else:
        html_imagens_completo = ""

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
               data-evento-pdf="ler"
               href="{escapar(url_pdf_leitura)}"
               target="_blank"
               rel="noopener noreferrer">
                Ler PDF
            </a>

            <a class="botao botao-secundario"
               data-evento-pdf="descarregar"
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

    informacoes_tecnicas = []

    if numero_paginas:
        informacoes_tecnicas.append(
            '<div class="item-tecnico">'
            '<span>Número de páginas</span>'
            f"<strong>{escapar(numero_paginas)}</strong>"
            "</div>"
        )

    if tamanho_arquivo:
        informacoes_tecnicas.append(
            '<div class="item-tecnico">'
            '<span>Tamanho do ficheiro</span>'
            f"<strong>{escapar(tamanho_arquivo)}</strong>"
            "</div>"
        )

    if url_pdf_leitura:
        informacoes_tecnicas.append(
            '<div class="item-tecnico">'
            '<span>Formato do documento</span>'
            "<strong>PDF</strong>"
            "</div>"
        )

    if informacoes_tecnicas:
        html_tecnico = (
            '<section class="informacoes-tecnicas">'
            "<h2>Informações técnicas</h2>"
            '<div class="grelha-tecnica">'
            + "".join(informacoes_tecnicas)
            + "</div></section>"
        )
    else:
        html_tecnico = ""

    data_publicacao_html = ""

    if data_publicacao:
        data_publicacao_html = (
            "<p><strong>Data de publicação:</strong> "
            + escapar(formatar_data(data_publicacao))
            + "</p>"
        )

    json_ld = gerar_json_ld(
        titulo=titulo,
        descricao=descricao_meta,
        url_pagina=url_pagina,
        autor=autor,
        categoria=categoria,
        data_publicacao=data_publicacao,
        url_pdf=url_pdf_leitura,
    )

    javascript_estatisticas = (
        gerar_javascript_estatisticas(obra_id)
    )

    html_pagina = f"""<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>{escapar(titulo)} — {escapar(NOME_SITE)}</title>

    <meta name="description" content="{escapar(descricao_meta)}">
    <meta name="robots" content="index, follow">

    <link rel="canonical" href="{escapar(url_pagina)}">
    <link rel="icon" type="image/png" href="{PROJECT_BASE}OL.png">

    <meta property="og:type" content="article">
    <meta property="og:title" content="{escapar(titulo)}">
    <meta property="og:description" content="{escapar(descricao_meta)}">
    <meta property="og:url" content="{escapar(url_pagina)}">
    <meta property="og:site_name" content="{escapar(NOME_SITE)}">

    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="{escapar(titulo)}">
    <meta name="twitter:description" content="{escapar(descricao_meta)}">

    <script type="application/ld+json">{json_ld}</script>

    {javascript_estatisticas}

    <style>
        * {{ box-sizing: border-box; }}

        html {{ scroll-behavior: smooth; }}

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

        main {{
            width: calc(100% - 32px);
            max-width: 1000px;
            margin: 28px auto;
            padding: 30px;
            background: #fff;
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
            text-align: justify;
        }}

        .metadados {{
            padding: 18px;
            background: #f6f9fc;
            border: 1px solid #e5edf5;
            border-radius: 8px;
            margin: 22px 0 28px;
        }}

        .metadados p {{ margin: 5px 0; }}

        .descricao {{
            white-space: pre-wrap;
            overflow-wrap: anywhere;
        }}

        .descricao-obra,
        .imagens-obra,
        .informacoes-tecnicas {{
            margin-top: 30px;
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
            color: #fff;
            text-decoration: none;
            font-weight: bold;
            text-align: center;
        }}

        .botao:hover {{ background: #0d477e; }}

        .botao-secundario {{ background: #167447; }}

        .botao-secundario:hover {{ background: #105a36; }}

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
        .item-tecnico strong {{ display: block; }}

        .item-tecnico span {{
            color: #526273;
            font-size: .9rem;
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
            font-size: .92rem;
        }}

        .fonte-imagem {{
            margin-top: 4px;
            color: #65758a;
            font-size: .85rem;
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
            font-size: .9rem;
        }}

        .rodape {{
            margin-top: 35px;
            padding-top: 20px;
            border-top: 1px solid #e1e8f0;
            color: #526273;
            font-size: .95rem;
        }}

        .rodape a {{ color: #145da0; }}

        a {{ overflow-wrap: anywhere; }}

        @media (max-width: 600px) {{
            header {{ padding: 14px; }}

            main {{
                width: calc(100% - 20px);
                margin: 12px auto;
                padding: 18px;
                border-radius: 8px;
            }}

            .botoes-pdf {{ flex-direction: column; }}

            .botao {{ width: 100%; }}

            .metadados {{ padding: 14px; }}
        }}
    </style>
</head>

<body>
<header>
    <div class="cabecalho-interior">
        <a href="{PROJECT_BASE}">{escapar(NOME_SITE)}</a>
        <a href="{PROJECT_BASE}acervo/">Explorar acervo</a>
    </div>
</header>

<main>
    <article>
        <h1>{escapar(titulo)}</h1>

        <section class="metadados" aria-label="Informações da obra">
            <p><strong>Autor:</strong> {escapar(autor or "Não indicado")}</p>
            <p><strong>Categoria:</strong> {escapar(categoria or "Não indicada")}</p>
            <p><strong>Ano:</strong> {escapar(ano or "Não indicado")}</p>
            {data_publicacao_html}
        </section>

        <section class="descricao-obra">
            <h2>Descrição da obra</h2>
            <div class="descricao">{escapar(descricao) if descricao else "Não foi fornecida uma descrição para esta obra."}</div>
        </section>

        <div class="texto-principal-obra">
            {html_conteudo_final}
        </div>

        {html_imagens_completo}

        {html_tecnico}

        <section class="documento-completo">
            <h2>Documento completo</h2>
            <p>Pode abrir o documento PDF para leitura ou utilizar a opção de descarregamento.</p>
            {botoes_pdf}
        </section>

        {html_relacionadas}
    </article>

    <footer class="rodape">
        <p>Publicado na plataforma <a href="{PROJECT_BASE}">{escapar(NOME_SITE)}</a>.</p>
        <p><a href="{PROJECT_BASE}acervo/">Regressar ao acervo</a></p>
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
        data_convertida = (
            data_iso_valida(obra.get("updated_at"))
            or data_iso_valida(obra.get("created_at"))
            or data_iso_valida(obra.get("data_publicacao"))
        )

        if data_convertida:
            datas_por_url[url] = data_convertida.isoformat()

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

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Configuração do Supabase em falta. "
            "Verifique o ficheiro Dart que contém "
            "SupabaseConfig ou defina SUPABASE_URL "
            "e SUPABASE_ANON_KEY."
        )

    print("=" * 65)
    print("GERAÇÃO DAS PÁGINAS SEO — OBRA LIVRE")
    print("=" * 65)

    print(f"Supabase URL: {SUPABASE_URL}")
    print("Chave pública Supabase: configurada")

    obras = obter_obras()

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
                f"Erro ao gerar a página da obra "
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

