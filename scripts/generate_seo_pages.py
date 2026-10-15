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
from datetime import datetime, timezone


# ============================================================
# CONFIGURAÇÃO
# ============================================================

NOME_SITE = "Obra Livre"

BASE_URL = "https://ginho83-wq.github.io/teste"

SUPABASE_URL = os.environ.get(
    "SUPABASE_URL",
    "https://umyuzhzffqvmhphwjysd.supabase.co",
).rstrip("/")

SUPABASE_ANON_KEY = os.environ.get(
    "SUPABASE_ANON_KEY",
    "",
)

DIRETORIO_PROJETO = Path(__file__).resolve().parent.parent

DIRETORIO_WEB = DIRETORIO_PROJETO / "build" / "web"

DIRETORIO_OBRAS = DIRETORIO_WEB / "obra"

SITEMAP_PATH = DIRETORIO_WEB / "sitemap.xml"

ROBOTS_PATH = DIRETORIO_WEB / "robots.txt"

TIMEOUT = 30


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def escapar(valor):
    """Escapa texto para utilização segura em HTML."""

    if valor is None:
        return ""

    return html.escape(str(valor), quote=True)


def texto(valor):
    """Converte um valor para texto sem produzir None."""

    if valor is None:
        return ""

    return str(valor).strip()


def primeiro_valor(dados, *nomes, default=""):
    """Devolve o primeiro campo existente e não vazio."""

    if not isinstance(dados, dict):
        return default

    for nome in nomes:
        valor = dados.get(nome)

        if valor is not None and str(valor).strip() != "":
            return valor

    return default


def limpar_html(valor):
    """Remove etiquetas HTML quando necessário."""

    valor = texto(valor)

    valor = re.sub(
        r"<script\b[^>]*>.*?</script>",
        "",
        valor,
        flags=re.IGNORECASE | re.DOTALL,
    )

    valor = re.sub(
        r"<style\b[^>]*>.*?</style>",
        "",
        valor,
        flags=re.IGNORECASE | re.DOTALL,
    )

    valor = re.sub(
        r"<[^>]+>",
        " ",
        valor,
    )

    valor = html.unescape(valor)

    return re.sub(r"\s+", " ", valor).strip()


def limitar_texto(valor, limite=300):
    """Limita o tamanho de um texto."""

    valor = limpar_html(valor)

    if len(valor) <= limite:
        return valor

    trecho = valor[:limite].rsplit(" ", 1)[0]

    return trecho + "..."


def formatar_data(valor):
    """Formata datas para apresentação."""

    valor = texto(valor)

    if not valor:
        return ""

    try:
        data = datetime.fromisoformat(
            valor.replace("Z", "+00:00")
        )

        return data.strftime("%d/%m/%Y")

    except (ValueError, TypeError):
        return valor


def url_absoluta(url):
    """Transforma caminhos relativos em URLs absolutas."""

    url = texto(url)

    if not url:
        return ""

    if url.startswith(("https://", "http://", "data:")):
        return url

    if url.startswith("/"):
        return BASE_URL + url

    return BASE_URL + "/" + url


def escapar_url(url):
    """Escapa uma URL para inclusão num atributo HTML."""

    return escapar(url)


def nome_ficheiro_url(url):
    """Verifica se uma URL pode ser utilizada num link."""

    url = texto(url)

    if not url:
        return ""

    return escapar_url(url)


# ============================================================
# COMUNICAÇÃO COM O SUPABASE
# ============================================================

def consultar_tabela(tabela, parametros=None):
    """
    Consulta uma tabela através da API REST do Supabase.

    Utiliza a chave pública configurada em SUPABASE_ANON_KEY.
    Não utilizar uma secret key no site.
    """

    if not SUPABASE_URL:
        raise RuntimeError(
            "A variável SUPABASE_URL não está configurada."
        )

    if not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "A variável SUPABASE_ANON_KEY não está configurada."
        )

    parametros = parametros or {}

    query = urllib.parse.urlencode(
        parametros,
        doseq=True,
        safe="*,().",
    )

    endpoint = (
        f"{SUPABASE_URL}/rest/v1/"
        f"{urllib.parse.quote(tabela, safe='')}"
    )

    if query:
        endpoint += "?" + query

    pedido = urllib.request.Request(
        endpoint,
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
            timeout=TIMEOUT,
        ) as resposta:

            conteudo = resposta.read().decode("utf-8")

            dados = json.loads(conteudo)

            if isinstance(dados, list):
                return dados

            return []

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

    except json.JSONDecodeError as erro:
        raise RuntimeError(
            "O Supabase devolveu uma resposta JSON inválida."
        ) from erro


# ============================================================
# OBRAS PUBLICADAS
# ============================================================

def obter_obras():
    """Obtém as obras publicadas."""

    try:
        obras = consultar_tabela(
            "obras",
            {
                "select": "*",
                "order": "created_at.desc",
            },
        )

        print(f"Obras encontradas: {len(obras)}")

        return obras

    except Exception as erro:
        print(
            f"Erro ao consultar as obras: {erro}",
            file=sys.stderr,
        )

        return []


# ============================================================
# SECÇÕES DAS OBRAS
# ============================================================

def obter_secoes(obra_id):
    """
    Consulta as secções na tabela teste_secoes.

    Campos esperados:
    id, obra_id, titulo, conteudo, ordem, nivel,
    criado_at, atualizado_at e paragrafo_ordem.
    """

    try:
        secoes = consultar_tabela(
            "teste_secoes",
            {
                "select": "*",
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

        print(
            f"Secções encontradas para a obra "
            f"{obra_id}: {len(secoes)}"
        )

        return secoes

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar "
            f"as secções da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


# ============================================================
# IMAGENS DAS OBRAS
# ============================================================

def obter_imagens(obra_id):
    """Consulta as imagens na tabela teste_imagens."""

    try:
        imagens = consultar_tabela(
            "teste_imagens",
            {
                "select": "*",
                "obra_id": f"eq.{obra_id}",
            },
        )

        print(
            f"Imagens encontradas para a obra "
            f"{obra_id}: {len(imagens)}"
        )

        return imagens

    except Exception as erro:
        print(
            f"Aviso: não foi possível consultar "
            f"as imagens da obra {obra_id}: {erro}",
            file=sys.stderr,
        )

        return []


# ============================================================
# EXTRAÇÃO DOS DADOS DA OBRA
# ============================================================

def obter_titulo(obra):
    return limpar_html(
        primeiro_valor(
            obra,
            "titulo",
            "title",
            default="Obra académica",
        )
    )


def obter_autor(obra):
    return limpar_html(
        primeiro_valor(
            obra,
            "autor",
            "nome_autor",
            "author",
            default="Autor não indicado",
        )
    )


def obter_categoria(obra):
    return limpar_html(
        primeiro_valor(
            obra,
            "categoria",
            "tipo_obra",
            default="Obra académica",
        )
    )


def obter_ano(obra):
    ano = primeiro_valor(
        obra,
        "ano_obra",
        "ano_publicacao",
        "ano",
        default="",
    )

    if ano:
        return texto(ano)

    data = primeiro_valor(
        obra,
        "data_publicacao",
        "created_at",
        default="",
    )

    if data:
        correspondencia = re.search(
            r"\b(19|20)\d{2}\b",
            str(data),
        )

        if correspondencia:
            return correspondencia.group(0)

    return ""


def obter_descricao(obra):
    return limpar_html(
        primeiro_valor(
            obra,
            "descricao",
            "resumo",
            "abstract",
            default="",
        )
    )


def obter_pdf(obra):
    return texto(
        primeiro_valor(
            obra,
            "url_documento",
            "url_pdf",
            "urlDocumento",
            "pdf_url",
            "document_url",
            default="",
        )
    )


def obter_numero_paginas(obra):
    return texto(
        primeiro_valor(
            obra,
            "numero_paginas",
            "total_paginas",
            default="",
        )
    )


def obter_tamanho_arquivo(obra):
    return primeiro_valor(
        obra,
        "tamanho_arquivo_bytes",
        "tamanho_bytes",
        "file_size",
        default="",
    )


def formatar_tamanho_arquivo(valor):
    """Converte bytes em KB ou MB para apresentação."""

    try:
        tamanho = int(valor)

        if tamanho <= 0:
            return ""

        if tamanho < 1024 * 1024:
            return f"{tamanho / 1024:.1f} KB"

        return f"{tamanho / (1024 * 1024):.2f} MB"

    except (ValueError, TypeError):
        return texto(valor)


# ============================================================
# HTML DAS SECÇÕES
# ============================================================

def gerar_html_secoes(secoes):
    """Produz HTML com todas as secções disponíveis."""

    if not secoes:
        return ""

    def obter_ordem(secao):
        try:
            return int(
                primeiro_valor(
                    secao,
                    "ordem",
                    default=0,
                ) or 0
            )
        except (ValueError, TypeError):
            return 0

    secoes_ordenadas = sorted(
        secoes,
        key=obter_ordem,
    )

    blocos = []

    for secao in secoes_ordenadas:
        titulo = limpar_html(
            primeiro_valor(
                secao,
                "titulo",
                "nome",
                default="",
            )
        )

        conteudo = texto(
            primeiro_valor(
                secao,
                "conteudo",
                "texto",
                "conteudo_texto",
                default="",
            )
        )

        nivel_original = primeiro_valor(
            secao,
            "nivel",
            default=2,
        )

        try:
            nivel = int(nivel_original)
        except (ValueError, TypeError):
            nivel = 2

        nivel = max(2, min(6, nivel))

        if not titulo and not conteudo:
            continue

        bloco = []

        if titulo:
            bloco.append(
                f"<h{nivel}>{escapar(titulo)}</h{nivel}>"
            )

        if conteudo:
            paragrafos = re.split(
                r"\n\s*\n",
                conteudo.strip(),
            )

            for paragrafo in paragrafos:
                paragrafo = paragrafo.strip()

                if not paragrafo:
                    continue

                linhas = paragrafo.splitlines()

                texto_paragrafo = "<br>".join(
                    escapar(linha)
                    for linha in linhas
                )

                bloco.append(
                    '<p class="texto-obra">'
                    f"{texto_paragrafo}"
                    "</p>"
                )

        blocos.append("\n".join(bloco))

    return "\n".join(blocos)


# ============================================================
# HTML DAS IMAGENS
# ============================================================

def gerar_html_imagens(imagens):
    """Produz HTML com as imagens associadas à obra."""

    if not imagens:
        return ""

    def obter_ordem(imagem):
        try:
            return int(
                primeiro_valor(
                    imagem,
                    "paragrafo_ordem",
                    "ordem",
                    default=999999,
                ) or 999999
            )
        except (ValueError, TypeError):
            return 999999

    imagens_ordenadas = sorted(
        imagens,
        key=obter_ordem,
    )

    blocos = []

    for imagem in imagens_ordenadas:
        url = texto(
            primeiro_valor(
                imagem,
                "url_imagem",
                "url",
                "imagem_url",
                "caminho",
                "path",
                "public_url",
                default="",
            )
        )

        if not url:
            continue

        url = url_absoluta(url)

        legenda = limpar_html(
            primeiro_valor(
                imagem,
                "legenda",
                "descricao",
                "titulo",
                "fonte",
                default="",
            )
        )

        alt = legenda or "Imagem da obra académica"

        bloco = [
            '<figure class="figura-obra">',
            (
                f'<img src="{escapar_url(url)}" '
                f'alt="{escapar(alt)}" '
                'loading="lazy">'
            ),
        ]

        if legenda:
            bloco.append(
                f"<figcaption>{escapar(legenda)}</figcaption>"
            )

        bloco.append("</figure>")

        blocos.append("\n".join(bloco))

    return "\n".join(blocos)


# ============================================================
# OBRAS RELACIONADAS
# ============================================================

def gerar_html_relacionadas(obra, todas_obras):
    """Apresenta outras obras da mesma categoria."""

    categoria_atual = obter_categoria(obra)

    obra_id = texto(
        primeiro_valor(
            obra,
            "id",
            default="",
        )
    )

    relacionadas = []

    for outra in todas_obras:
        outro_id = texto(
            primeiro_valor(
                outra,
                "id",
                default="",
            )
        )

        if outro_id == obra_id:
            continue

        if obter_categoria(outra) == categoria_atual:
            relacionadas.append(outra)

        if len(relacionadas) >= 5:
            break

    if not relacionadas:
        return ""

    blocos = [
        '<section class="cartao">',
        "<h2>Obras relacionadas</h2>",
        '<ul class="lista-relacionadas">',
    ]

    for relacionada in relacionadas:
        outro_id = texto(
            primeiro_valor(
                relacionada,
                "id",
                default="",
            )
        )

        titulo = obter_titulo(relacionada)
        autor = obter_autor(relacionada)

        if not outro_id:
            continue

        link = f"{BASE_URL}/obra/{outro_id}/"

        blocos.append(
            "<li>"
            f'<a href="{escapar_url(link)}">'
            f"{escapar(titulo)}"
            "</a>"
            f"<span> — {escapar(autor)}</span>"
            "</li>"
        )

    blocos.extend([
        "</ul>",
        "</section>",
    ])

    return "\n".join(blocos)


# ============================================================
# DADOS ESTRUTURADOS JSON-LD
# ============================================================

def gerar_json_ld(obra, url_pagina, descricao):
    """Gera dados estruturados para mecanismos de pesquisa."""

    titulo = obter_titulo(obra)
    autor = obter_autor(obra)
    categoria = obter_categoria(obra)
    ano = obter_ano(obra)

    dados = {
        "@context": "https://schema.org",
        "@type": "ScholarlyArticle",
        "headline": titulo,
        "name": titulo,
        "url": url_pagina,
        "author": {
            "@type": "Person",
            "name": autor,
        },
        "publisher": {
            "@type": "Organization",
            "name": NOME_SITE,
        },
        "isAccessibleForFree": True,
    }

    if descricao:
        dados["description"] = limitar_texto(
            descricao,
            500,
        )

    if categoria:
        dados["genre"] = categoria

    if ano:
        dados["datePublished"] = ano

    pdf = obter_pdf(obra)

    if pdf:
        dados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": url_absoluta(pdf),
            "encodingFormat": "application/pdf",
        }

    return json.dumps(
        dados,
        ensure_ascii=False,
    ).replace("</", "<\\/")


# ============================================================
# CSS DAS PÁGINAS SEO
# ============================================================

CSS_PAGINA = """
:root {
    color-scheme: light;
    font-family: Arial, Helvetica, sans-serif;
    line-height: 1.7;
    color: #263445;
    background: #f5f8fc;
}

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    background: #f5f8fc;
}

header {
    background: #eaf4ff;
    border-bottom: 1px solid #d5e5f5;
    padding: 20px;
}

.cabecalho {
    max-width: 1100px;
    margin: auto;
}

.logo {
    color: #123e69;
    font-size: 25px;
    font-weight: bold;
    text-decoration: none;
}

nav {
    margin-top: 12px;
}

nav a {
    color: #174f80;
    margin-right: 18px;
    text-decoration: none;
}

nav a:hover {
    text-decoration: underline;
}

main {
    max-width: 1000px;
    margin: 30px auto;
    padding: 0 18px;
}

.cartao {
    background: white;
    border: 1px solid #e0e8f0;
    border-radius: 12px;
    padding: 28px;
    margin-bottom: 22px;
    overflow-wrap: anywhere;
}

h1 {
    line-height: 1.3;
    color: #173f68;
    font-size: clamp(27px, 4vw, 38px);
}

h2 {
    color: #173f68;
    margin-top: 28px;
}

h3, h4, h5, h6 {
    color: #244e76;
}

.metadados {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin: 20px 0;
}

.etiqueta {
    background: #eaf4ff;
    color: #174f80;
    border-radius: 20px;
    padding: 5px 12px;
    font-size: 14px;
}

.descricao {
    font-size: 18px;
    color: #394c60;
}

.acoes {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin: 22px 0;
}

.botao {
    display: inline-block;
    background: #145b96;
    color: white;
    padding: 11px 18px;
    border-radius: 7px;
    text-decoration: none;
    font-weight: bold;
}

.botao:hover {
    opacity: 0.9;
}

.botao-secundario {
    background: #eaf4ff;
    color: #174f80;
    border: 1px solid #c7dff4;
}

.texto-obra {
    text-align: justify;
    white-space: normal;
    overflow-wrap: anywhere;
    margin: 0 0 18px;
}

.figura-obra {
    margin: 28px auto;
    text-align: center;
}

.figura-obra img {
    max-width: 100%;
    height: auto;
    border-radius: 6px;
}

figcaption {
    font-size: 14px;
    color: #64748b;
    margin-top: 8px;
}

.dados-tecnicos {
    width: 100%;
    border-collapse: collapse;
}

.dados-tecnicos th,
.dados-tecnicos td {
    text-align: left;
    border-bottom: 1px solid #e5edf5;
    padding: 10px;
    vertical-align: top;
}

.dados-tecnicos th {
    width: 35%;
    color: #244e76;
}

.lista-relacionadas {
    padding-left: 22px;
}

.lista-relacionadas li {
    margin: 10px 0;
}

.lista-relacionadas a {
    color: #145b96;
}

footer {
    border-top: 1px solid #d5e5f5;
    background: #eaf4ff;
    padding: 24px 18px;
    text-align: center;
    color: #52677d;
}

footer a {
    color: #174f80;
}

.aviso {
    background: #f0f7ff;
    border-left: 4px solid #6b9fcf;
    padding: 12px 16px;
    border-radius: 4px;
}

@media (max-width: 650px) {
    .cartao {
        padding: 18px;
    }

    nav a {
        display: inline-block;
        margin-bottom: 8px;
    }

    .dados-tecnicos th {
        width: 40%;
    }
}
"""


# ============================================================
# PÁGINA HTML INDIVIDUAL DE CADA OBRA
# ============================================================

def gerar_pagina_obra(obra, todas_obras=None):
    """
    Gera uma página HTML estática para uma obra.

    Apresenta os metadados, descrição, PDF, secções,
    imagens e obras relacionadas, sem blocos duplicados.
    """

    todas_obras = todas_obras or []

    obra_id = texto(
        primeiro_valor(
            obra,
            "id",
            default="",
        )
    )

    if not obra_id:
        print(
            "Aviso: obra sem identificador; página ignorada.",
            file=sys.stderr,
        )
        return None

    titulo = obter_titulo(obra)
    autor = obter_autor(obra)
    categoria = obter_categoria(obra)
    ano = obter_ano(obra)
    descricao = obter_descricao(obra)
    pdf = obter_pdf(obra)

    paginas = obter_numero_paginas(obra)

    tamanho = formatar_tamanho_arquivo(
        obter_tamanho_arquivo(obra)
    )

    data_publicacao = formatar_data(
        primeiro_valor(
            obra,
            "data_publicacao",
            "created_at",
            default="",
        )
    )

    url_pagina = f"{BASE_URL}/obra/{obra_id}/"

    titulo_html = f"{titulo} | {NOME_SITE}"

    descricao_seo = (
        limitar_texto(descricao, 250)
        if descricao
        else (
            f"Consulte a obra académica "
            f"{titulo}, de {autor}, no {NOME_SITE}."
        )
    )

    secoes = obter_secoes(obra_id)
    imagens = obter_imagens(obra_id)

    html_secoes = gerar_html_secoes(secoes)
    html_imagens = gerar_html_imagens(imagens)

    html_relacionadas = gerar_html_relacionadas(
        obra,
        todas_obras,
    )

    json_ld = gerar_json_ld(
        obra,
        url_pagina,
        descricao,
    )

    # --------------------------------------------------------
    # METADADOS SEO
    # --------------------------------------------------------

    blocos_head = [
        "<!DOCTYPE html>",
        '<html lang="pt">',
        "<head>",
        '<meta charset="UTF-8">',
        (
            '<meta name="viewport" '
            'content="width=device-width, initial-scale=1.0">'
        ),
        f"<title>{escapar(titulo_html)}</title>",
        (
            '<meta name="description" '
            f'content="{escapar(descricao_seo)}">'
        ),
        (
            '<link rel="canonical" '
            f'href="{escapar_url(url_pagina)}">'
        ),
        '<meta name="robots" content="index, follow">',
        '<meta property="og:type" content="article">',
        (
            '<meta property="og:site_name" '
            f'content="{escapar(NOME_SITE)}">'
        ),
        (
            '<meta property="og:title" '
            f'content="{escapar(titulo)}">'
        ),
        (
            '<meta property="og:description" '
            f'content="{escapar(descricao_seo)}">'
        ),
        (
            '<meta property="og:url" '
            f'content="{escapar_url(url_pagina)}">'
        ),
        '<meta name="twitter:card" content="summary">',
        (
            '<meta name="twitter:title" '
            f'content="{escapar(titulo)}">'
        ),
        (
            '<meta name="twitter:description" '
            f'content="{escapar(descricao_seo)}">'
        ),
        '<link rel="icon" href="/teste/OL.png">',
        "<style>",
        CSS_PAGINA,
        "</style>",
        (
            '<script type="application/ld+json">'
            f"{json_ld}"
            "</script>"
        ),
        "</head>",
    ]

    # --------------------------------------------------------
    # CABEÇALHO
    # --------------------------------------------------------

    cabecalho = f"""
<body>
    <header>
        <div class="cabecalho">
            <a class="logo" href="{BASE_URL}/">
                Obra Livre
            </a>

            <nav aria-label="Navegação principal">
                <a href="{BASE_URL}/">Início</a>
                <a href="{BASE_URL}/acervo/">Acervo</a>
                <a href="{BASE_URL}/categorias/">Categorias</a>
                <a href="{BASE_URL}/termos/">Termos</a>
            </nav>
        </div>
    </header>

    <main>
"""

    # --------------------------------------------------------
    # INFORMAÇÃO PRINCIPAL DA OBRA
    # --------------------------------------------------------

    principal = f"""
        <article class="cartao">
            <h1>{escapar(titulo)}</h1>

            <div class="metadados">
                <span class="etiqueta">
                    Autor: {escapar(autor)}
                </span>

                <span class="etiqueta">
                    Categoria: {escapar(categoria)}
                </span>

                {
                    (
                        '<span class="etiqueta">'
                        f'Ano: {escapar(ano)}'
                        '</span>'
                    )
                    if ano else ""
                }
            </div>
"""

    if descricao:
        principal += f"""
            <section>
                <h2>Descrição</h2>
                <p class="descricao">{escapar(descricao)}</p>
            </section>
"""

    # --------------------------------------------------------
    # DOCUMENTO PDF
    # --------------------------------------------------------
    # Mantém os botões e remove o iframe com scroll interno.

    if pdf:
        url_pdf = url_absoluta(pdf)

        principal += f"""
            <section>
                <h2>Documento PDF</h2>

                <p>
                    Consulte ou descarregue o documento
                    completo desta obra académica.
                </p>

                <div class="acoes">
                    <a
                        class="botao"
                        href="{escapar_url(url_pdf)}"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        Abrir PDF
                    </a>

                    <a
                        class="botao botao-secundario"
                        href="{escapar_url(url_pdf)}"
                        download
                    >
                        Descarregar PDF
                    </a>
                </div>

                <p class="aviso">
                    O documento é disponibilizado em PDF.
                    Utilize os botões acima para abrir ou
                    descarregar o ficheiro.
                </p>
            </section>
"""

    else:
        principal += """
            <p class="aviso">
                O documento PDF não está disponível através
                dos campos consultados para esta obra.
            </p>
"""

    principal += """
        </article>
"""

    # --------------------------------------------------------
    # INFORMAÇÕES ADICIONAIS
    # --------------------------------------------------------
    # Autor, categoria e ano não são repetidos aqui.

    linhas_tecnicas = []

    if paginas:
        linhas_tecnicas.append(
            "<tr><th>Número de páginas</th>"
            f"<td>{escapar(paginas)}</td></tr>"
        )

    if tamanho:
        linhas_tecnicas.append(
            "<tr><th>Tamanho do ficheiro</th>"
            f"<td>{escapar(tamanho)}</td></tr>"
        )

    if data_publicacao:
        linhas_tecnicas.append(
            "<tr><th>Data de publicação</th>"
            f"<td>{escapar(data_publicacao)}</td></tr>"
        )

    html_tecnicos = ""

    if linhas_tecnicas:
        html_tecnicos = f"""
        <section class="cartao">
            <h2>Informações adicionais</h2>

            <table class="dados-tecnicos">
                {"".join(linhas_tecnicas)}
            </table>
        </section>
"""

    # --------------------------------------------------------
    # SECÇÕES DA OBRA
    # --------------------------------------------------------
    # O bloco "Conteúdo textual" foi removido para evitar
    # duplicação com as secções guardadas em teste_secoes.

    html_secoes_completo = ""

    if html_secoes:
        html_secoes_completo = f"""
        <section class="cartao">
            <h2>Conteúdo da obra</h2>

            {html_secoes}
        </section>
"""

    # --------------------------------------------------------
    # IMAGENS DA OBRA
    # --------------------------------------------------------

    html_imagens_completo = ""

    if html_imagens:
        html_imagens_completo = f"""
        <section class="cartao">
            <h2>Imagens da obra</h2>

            {html_imagens}
        </section>
"""

    # --------------------------------------------------------
    # RODAPÉ E MONTAGEM FINAL
    # --------------------------------------------------------

    rodape = f"""
        {html_tecnicos}
        {html_secoes_completo}
        {html_imagens_completo}
        {html_relacionadas}

    </main>

    <footer>
        <p>
            © {datetime.now().year}
            <a href="{BASE_URL}/">Obra Livre</a>
            — Plataforma de consulta e publicação
            de obras académicas.
        </p>
    </footer>
</body>
</html>
"""

    documento = (
        "\n".join(blocos_head)
        + cabecalho
        + principal
        + rodape
    )

    # --------------------------------------------------------
    # GRAVAR PÁGINA
    # --------------------------------------------------------

    diretorio_obra = DIRETORIO_OBRAS / obra_id

    diretorio_obra.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho_html = diretorio_obra / "index.html"

    caminho_html.write_text(
        documento,
        encoding="utf-8",
    )

    print(f"Página SEO gerada: {caminho_html}")

    return url_pagina


# ============================================================
# GERAÇÃO DO SITEMAP
# ============================================================

def gerar_sitemap(obras):
    """Gera o sitemap com páginas gerais e páginas das obras."""

    ET.register_namespace(
        "",
        "http://www.sitemaps.org/schemas/sitemap/0.9",
    )

    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"

    urlset = ET.Element(
        f"{{{namespace}}}urlset"
    )

    data_atual = datetime.now(
        timezone.utc
    ).date().isoformat()

    paginas_estaticas = [
        "/",
        "/acervo/",
        "/categorias/",
        "/termos/",
        "/politica-privacidade/",
        "/cookies/",
        "/contacto/",
        "/ajuda/",
    ]

    urls_adicionadas = set()

    def adicionar_url(
        url,
        data=None,
        frequencia="weekly",
        prioridade="0.7",
    ):
        if url in urls_adicionadas:
            return

        urls_adicionadas.add(url)

        elemento_url = ET.SubElement(
            urlset,
            f"{{{namespace}}}url",
        )

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}loc",
        ).text = url

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}lastmod",
        ).text = data or data_atual

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}changefreq",
        ).text = frequencia

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}priority",
        ).text = prioridade

    # Páginas gerais do site.

    for pagina in paginas_estaticas:
        adicionar_url(
            BASE_URL + pagina,
            frequencia="weekly",
            prioridade="1.0" if pagina == "/" else "0.7",
        )

    # Páginas individuais das obras.

    for obra in obras:
        obra_id = texto(
            primeiro_valor(
                obra,
                "id",
                default="",
            )
        )

        if not obra_id:
            continue

        url_obra = f"{BASE_URL}/obra/{obra_id}/"

        data = primeiro_valor(
            obra,
            "updated_at",
            "atualizado_at",
            "created_at",
            "criado_at",
            "data_publicacao",
            default=data_atual,
        )

        data = texto(data)

        if data:
            try:
                data = datetime.fromisoformat(
                    data.replace("Z", "+00:00")
                ).date().isoformat()

            except ValueError:
                data = data_atual

        adicionar_url(
            url_obra,
            data=data or data_atual,
            frequencia="monthly",
            prioridade="0.8",
        )

    arvore = ET.ElementTree(urlset)

    DIRETORIO_WEB.mkdir(
        parents=True,
        exist_ok=True,
    )

    arvore.write(
        SITEMAP_PATH,
        encoding="utf-8",
        xml_declaration=True,
    )

    print(f"Sitemap gerado: {SITEMAP_PATH}")

    return SITEMAP_PATH


# ============================================================
# GERAÇÃO DO ROBOTS.TXT
# ============================================================

def gerar_robots():
    """Gera um robots.txt com referência ao sitemap."""

    conteudo = f"""User-agent: *
Allow: /

Sitemap: {BASE_URL}/sitemap.xml
"""

    DIRETORIO_WEB.mkdir(
        parents=True,
        exist_ok=True,
    )

    ROBOTS_PATH.write_text(
        conteudo,
        encoding="utf-8",
    )

    print(f"Robots.txt gerado: {ROBOTS_PATH}")


# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

def main():
    """Executa a geração das páginas SEO e do sitemap."""

    print("=" * 60)
    print("GERADOR SEO — OBRA LIVRE")
    print("=" * 60)

    print(f"URL base: {BASE_URL}")
    print(f"Diretório web: {DIRETORIO_WEB}")

    if not SUPABASE_ANON_KEY:
        print(
            "\nERRO: a variável SUPABASE_ANON_KEY "
            "não está configurada.",
            file=sys.stderr,
        )

        print(
            "Configure a chave pública do Supabase "
            "no PowerShell e volte a executar o script.",
            file=sys.stderr,
        )

        sys.exit(1)

    DIRETORIO_WEB.mkdir(
        parents=True,
        exist_ok=True,
    )

    obras = obter_obras()

    if not obras:
        print(
            "\nAviso: não foram encontradas obras. "
            "Verifique a tabela obras, a chave pública "
            "e as permissões de leitura do Supabase.",
            file=sys.stderr,
        )

    paginas_geradas = 0

    for obra in obras:
        try:
            url = gerar_pagina_obra(
                obra,
                obras,
            )

            if url:
                paginas_geradas += 1

        except Exception as erro:
            obra_id = texto(
                primeiro_valor(
                    obra,
                    "id",
                    default="sem-id",
                )
            )

            print(
                f"Erro ao gerar a página da obra "
                f"{obra_id}: {erro}",
                file=sys.stderr,
            )

    gerar_sitemap(obras)

    gerar_robots()

    print()
    print("=" * 60)
    print("GERAÇÃO SEO CONCLUÍDA")
    print(f"Obras consultadas: {len(obras)}")
    print(f"Páginas geradas: {paginas_geradas}")
    print(f"Sitemap: {SITEMAP_PATH}")
    print(f"Robots: {ROBOTS_PATH}")
    print("=" * 60)


if __name__ == "__main__":
    main()
