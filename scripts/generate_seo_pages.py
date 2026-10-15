import html
import json
import os
import sys
import urllib.parse
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET

from pathlib import Path
from datetime import datetime, timezone


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


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def texto_seguro(valor):
    if valor is None:
        return ""

    return str(valor).strip()


def escapar(valor):
    return html.escape(texto_seguro(valor), quote=True)


def descricao_seo(descricao, titulo, autor):
    descricao = " ".join(
        texto_seguro(descricao).split()
    )

    if not descricao:
        descricao = (
            f"Consulte a obra académica {titulo}"
        )

        if autor:
            descricao += f", de {autor}"

    if len(descricao) > 160:
        descricao = (
            descricao[:157].rsplit(" ", 1)[0] + "..."
        )

    return descricao


def url_absoluta(url):
    url = texto_seguro(url)

    if not url:
        return ""

    if url.startswith(("https://", "http://")):
        return url

    if url.startswith("/"):
        return BASE_URL + url

    return BASE_URL + "/" + url


def nome_arquivo_pdf(titulo):
    nome = texto_seguro(titulo)

    for caractere in '\\/:*?"<>|':
        nome = nome.replace(caractere, "")

    nome = "-".join(nome.split())
    nome = nome.strip(".-")

    if not nome:
        nome = "obra"

    if not nome.lower().endswith(".pdf"):
        nome += ".pdf"

    return nome


def url_download_pdf(url_pdf, titulo):
    """
    Acrescenta o parâmetro download aos endereços
    públicos do Supabase Storage.

    Para outros servidores, conserva o URL original.
    O descarregamento depende do suporte do servidor.
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
            "Authorization": (
                f"Bearer {SUPABASE_ANON_KEY}"
            ),
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
                "conteudo_texto,created_at"
            ),
            "order": "created_at.desc",
        },
    )


# ============================================================
# SECÇÕES DA OBRA
# ============================================================

def obter_secoes(obra_id):
    try:
        return consultar_tabela(
            "obra_secoes",
            {
                "select": "*",
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar "
            f"as secções da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


def gerar_html_secoes(secoes):
    blocos = []

    secoes_ordenadas = sorted(
        secoes,
        key=lambda item: int(item.get("ordem") or 0),
    )

    for secao in secoes_ordenadas:
        titulo = texto_seguro(secao.get("titulo"))
        conteudo = texto_seguro(secao.get("conteudo"))

        try:
            nivel = int(secao.get("nivel") or 2)
        except (TypeError, ValueError):
            nivel = 2

        nivel = max(2, min(nivel, 6))

        if titulo:
            blocos.append(
                f"<h{nivel}>{escapar(titulo)}</h{nivel}>"
            )

        if conteudo:
            paragrafos = conteudo.split("\n\n")

            for paragrafo in paragrafos:
                paragrafo = paragrafo.strip()

                if not paragrafo:
                    continue

                conteudo_html = escapar(paragrafo).replace(
                    "\n",
                    "<br>",
                )

                blocos.append(
                    f"<p>{conteudo_html}</p>"
                )

    return "\n".join(blocos)


# ============================================================
# IMAGENS DA OBRA
# ============================================================

def obter_imagens(obra_id):
    try:
        return consultar_tabela(
            "obras_imagens",
            {
                "select": "*",
                "obra_id": f"eq.{obra_id}",
            },
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar "
            f"as imagens da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


def gerar_html_imagens(imagens):
    blocos = []

    imagens_ordenadas = sorted(
        imagens,
        key=lambda item: (
            int(item.get("paragrafo_ordem") or 999999),
            int(item.get("ordem") or 0),
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

        legenda = (
            imagem.get("legenda")
            or imagem.get("descricao")
            or imagem.get("titulo")
            or ""
        )

        blocos.append(
            "<figure>"
            f'<img src="{escapar(url_imagem)}" '
            f'alt="{escapar(legenda)}" '
            'loading="lazy">'
            f"<figcaption>{escapar(legenda)}</figcaption>"
            "</figure>"
        )

    return "\n".join(blocos)


# ============================================================
# TAMANHO DO FICHEIRO
# ============================================================

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


# ============================================================
# GERAR PÁGINA SEO INDIVIDUAL
# ============================================================

def gerar_pagina_obra(obra):
    obra_id = texto_seguro(obra.get("id"))
    titulo = texto_seguro(obra.get("titulo"))

    if not obra_id or not titulo:
        print(
            "Aviso: obra sem ID ou título; ignorada.",
            file=sys.stderr,
        )
        return None

    autor = texto_seguro(obra.get("autor"))
    categoria = texto_seguro(obra.get("categoria"))
    descricao = texto_seguro(obra.get("descricao"))
    ano = texto_seguro(obra.get("ano_obra"))

    url_pdf_original = texto_seguro(
        obra.get("url_documento")
    )

    url_pdf_leitura = url_absoluta(
        url_pdf_original
    )

    url_pdf_download = url_download_pdf(
        url_pdf_original,
        titulo,
    )

    url_pagina = (
        BASE_URL
        + "/obra/"
        + urllib.parse.quote(obra_id, safe="")
        + "/"
    )

    descricao_meta = descricao_seo(
        descricao,
        titulo,
        autor,
    )

    secoes = obter_secoes(obra_id)
    imagens = obter_imagens(obra_id)

    html_secoes = gerar_html_secoes(secoes)
    html_imagens = gerar_html_imagens(imagens)

    numero_paginas = texto_seguro(
        obra.get("numero_paginas")
    )

    tamanho_arquivo = formatar_tamanho(
        obra.get("tamanho_arquivo_bytes")
    )

    data_publicacao = texto_seguro(
        obra.get("data_publicacao")
    )

    conteudo_texto = texto_seguro(
        obra.get("conteudo_texto")
    )

    if url_pdf_leitura:
        botoes_pdf = f"""
        <div class="botoes-pdf">
            <a class="botao"
               href="{escapar(url_pdf_leitura)}"
               target="_blank"
               rel="noopener">
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

    metadados = {
        "@context": "https://schema.org",
        "@type": "ScholarlyArticle",
        "headline": titulo,
        "name": titulo,
        "description": descricao_meta,
        "url": url_pagina,
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

    if ano:
        metadados["datePublished"] = ano

    if categoria:
        metadados["genre"] = categoria

    if url_pdf_leitura:
        metadados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": url_pdf_leitura,
            "encodingFormat": "application/pdf",
        }

    json_ld = json.dumps(
        metadados,
        ensure_ascii=False,
    ).replace("</", "<\\/")

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

    <meta property="og:title"
          content="{escapar(titulo)}">

    <meta property="og:description"
          content="{escapar(descricao_meta)}">

    <meta property="og:url"
          content="{escapar(url_pagina)}">

    <meta property="og:site_name"
          content="{escapar(NOME_SITE)}">

    <script type="application/ld+json">
    {json_ld}
    </script>

    <style>
        * {{
            box-sizing: border-box;
        }}

        body {{
            margin: 0;
            background: #f4f7fb;
            color: #243247;
            font-family: Arial, Helvetica, sans-serif;
            line-height: 1.7;
        }}

        header {{
            background: #eaf4ff;
            border-bottom: 1px solid #d5e5f5;
            padding: 18px 20px;
        }}

        header a {{
            color: #124f86;
            text-decoration: none;
            font-weight: bold;
        }}

        main {{
            width: 100%;
            max-width: 1000px;
            margin: 28px auto;
            padding: 28px;
            background: #ffffff;
            border: 1px solid #e1e8f0;
            border-radius: 10px;
        }}

        h1 {{
            margin-top: 0;
            line-height: 1.35;
            overflow-wrap: anywhere;
        }}

        h2, h3, h4, h5, h6 {{
            margin-top: 28px;
            color: #183e62;
        }}

        .metadados {{
            padding: 16px;
            background: #f6f9fc;
            border-radius: 8px;
            margin: 22px 0;
        }}

        .metadados p {{
            margin: 6px 0;
        }}

        .descricao {{
            white-space: pre-wrap;
        }}

        .botoes-pdf {{
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin: 24px 0;
        }}

        .botao {{
            display: inline-block;
            padding: 12px 18px;
            border-radius: 6px;
            background: #145da0;
            color: white;
            text-decoration: none;
            font-weight: bold;
        }}

        .botao-secundario {{
            background: #167447;
        }}

        figure {{
            margin: 24px 0;
        }}

        figure img {{
            display: block;
            max-width: 100%;
            height: auto;
            margin: auto;
        }}

        figcaption {{
            margin-top: 8px;
            text-align: center;
            color: #526273;
            font-size: 0.9rem;
        }}

        .rodape {{
            margin-top: 35px;
            padding-top: 20px;
            border-top: 1px solid #e1e8f0;
            font-size: 0.95rem;
        }}

        a {{
            overflow-wrap: anywhere;
        }}

        @media (max-width: 600px) {{
            main {{
                margin: 12px;
                padding: 18px;
                width: auto;
            }}

            header {{
                padding: 14px;
            }}
        }}
    </style>
</head>

<body>

<header>
    <a href="{PROJECT_BASE}">
        {escapar(NOME_SITE)}
    </a>
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

            {"<p><strong>Número de páginas:</strong> " + escapar(numero_paginas) + "</p>" if numero_paginas else ""}

            {"<p><strong>Tamanho do ficheiro:</strong> " + escapar(tamanho_arquivo) + "</p>" if tamanho_arquivo else ""}

            {"<p><strong>Data de publicação:</strong> " + escapar(data_publicacao) + "</p>" if data_publicacao else ""}
        </section>

        <section>
            <h2>Descrição da obra</h2>

            <div class="descricao">
                {escapar(descricao) if descricao else "Não foi fornecida uma descrição para esta obra."}
            </div>
        </section>

        {f'''
        <section>
            <h2>Conteúdo da obra</h2>
            <div class="descricao">{escapar(conteudo_texto)}</div>
        </section>
        ''' if conteudo_texto else ""}

        {f'''
        <section>
            <h2>Secções da obra</h2>
            {html_secoes}
        </section>
        ''' if html_secoes else ""}

        {f'''
        <section>
            <h2>Imagens da obra</h2>
            {html_imagens}
        </section>
        ''' if html_imagens else ""}

        <section>
            <h2>Documento completo</h2>

            <p>
                Pode abrir o documento PDF para leitura
                ou utilizar a opção de descarregamento.
            </p>

            {botoes_pdf}
        </section>

    </article>

    <footer class="rodape">
        <p>
            Publicado na plataforma
            <a href="{PROJECT_BASE}">
                {escapar(NOME_SITE)}
            </a>.
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
# SITEMAP
# ============================================================

def gerar_sitemap(urls):
    namespace = (
        "http://www.sitemaps.org/schemas/sitemap/0.9"
    )

    ET.register_namespace("", namespace)

    raiz = ET.Element(
        f"{{{namespace}}}urlset"
    )

    hoje = datetime.now(
        timezone.utc
    ).date().isoformat()

    urls_unicas = list(
        dict.fromkeys(urls)
    )

    for url in urls_unicas:
        # O sitemap contém apenas URLs do próprio site.
        if not url.startswith(BASE_URL + "/"):
            continue

        elemento_url = ET.SubElement(
            raiz,
            f"{{{namespace}}}url",
        )

        elemento_loc = ET.SubElement(
            elemento_url,
            f"{{{namespace}}}loc",
        )

        elemento_loc.text = url

        elemento_lastmod = ET.SubElement(
            elemento_url,
            f"{{{namespace}}}lastmod",
        )

        elemento_lastmod.text = hoje

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


# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

def main():
    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    urls_sitemap = [
        BASE_URL + rota
        for rota in URLS_FIXAS
    ]

    obras = obter_obras()

    print(f"Obras encontradas: {len(obras)}")

    for obra in obras:
        url = gerar_pagina_obra(obra)

        if url:
            urls_sitemap.append(url)

    gerar_sitemap(urls_sitemap)

    print("Geração SEO concluída com sucesso.")


if __name__ == "__main__":
    main()
