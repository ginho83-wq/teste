# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 1 DE 3
#
# Configuracao, Supabase e consulta dos dados.
# ============================================================

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
# 1. CONFIGURACAO GERAL
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

BASE_URL = "https://ginho83-wq.github.io/teste"

PROJECT_BASE = "/teste/"

OUTPUT_DIR = BASE_DIR / "build" / "web"

SITE_NAME = "Obra Livre — Obras Académicas"

SITE_DESCRIPTION = (
    "Plataforma de consulta e publicação de obras académicas, "
    "teses, monografias e artigos científicos."
)

FAVICON_URL = f"{BASE_URL}/OL.png"

SITEMAP_URL = f"{BASE_URL}/sitemap.xml"

ROBOTS_URL = f"{BASE_URL}/robots.txt"

TIMEOUT_HTTP = 30

LIMITE_DESCRICAO_SEO = 300

LIMITE_OBRAS_RELACIONADAS = 5


# ============================================================
# 2. TABELAS DO SUPABASE
# ============================================================

TABELA_OBRAS = "obras"

TABELA_SECOES = "teste_secoes"

TABELA_IMAGENS = "teste_imagens"


# ============================================================
# 3. COLUNAS CONSULTADAS
# ============================================================

COLUNAS_OBRAS = (
    "id,"
    "titulo,"
    "descricao,"
    "autor,"
    "categoria,"
    "url_documento,"
    "ano_obra,"
    "data_publicacao,"
    "numero_paginas,"
    "tamanho_arquivo_bytes,"
    "conteudo_texto,"
    "created_at,"
    "updated_at"
)

COLUNAS_SECOES = (
    "id,"
    "obra_id,"
    "titulo,"
    "conteudo,"
    "ordem,"
    "nivel,"
    "paragrafo_ordem"
)

COLUNAS_IMAGENS = (
    "id,"
    "obra_id,"
    "url_imagem,"
    "legenda,"
    "posicao,"
    "ordem,"
    "fonte,"
    "paragrafo_ordem"
)


# ============================================================
# 4. CREDENCIAIS DO SUPABASE
# ============================================================

SUPABASE_URL = ""

SUPABASE_KEY = ""


# ============================================================
# 5. NORMALIZAR URL
# ============================================================

def normalizar_url(url):
    """Valida e normaliza uma URL."""

    if not url:
        return ""

    url = str(url).strip().rstrip("/")

    if not url:
        return ""

    if not url.startswith(("https://", "http://")):
        return ""

    return url


# ============================================================
# 6. LER VARIAVEIS DOS FICHEIROS DART
# ============================================================

def extrair_valor_dart(texto, nomes_variaveis):
    """
    Procura valores em declaracoes Dart.

    Exemplos:
        static const String url = '...';
        static const String publishableKey = '...';
    """

    for nome in nomes_variaveis:

        padrao = (
            r"\b"
            + re.escape(nome)
            + r"\b\s*=\s*"
            r"(['\"])(.*?)\1"
        )

        resultado = re.search(
            padrao,
            texto,
            flags=re.DOTALL
        )

        if resultado:

            valor = resultado.group(2).strip()

            if valor:
                return valor

    return ""


# ============================================================
# 7. DESCOBRIR A CONFIGURACAO FLUTTER
# ============================================================

def carregar_configuracao_flutter():
    """
    Procura a URL e a chave publica nos ficheiros Dart.

    Suporta os nomes:
        url
        supabaseUrl
        publishableKey
        supabasePublishableKey
        anonKey
        supabaseAnonKey
    """

    pasta_lib = BASE_DIR / "lib"

    if not pasta_lib.exists():

        return "", ""

    try:

        ficheiros = list(
            pasta_lib.rglob("*.dart")
        )

    except OSError:

        return "", ""

    url_encontrada = ""

    chave_encontrada = ""

    for ficheiro in ficheiros:

        try:

            texto = ficheiro.read_text(
                encoding="utf-8",
                errors="ignore"
            )

        except OSError:

            continue

        # Procurar URL.

        if not url_encontrada:

            url_encontrada = extrair_valor_dart(
                texto,
                [
                    "supabaseUrl",
                    "SUPABASE_URL",
                    "url",
                ]
            )

        # Procurar chave publica.

        if not chave_encontrada:

            chave_encontrada = extrair_valor_dart(
                texto,
                [
                    "publishableKey",
                    "supabasePublishableKey",
                    "anonKey",
                    "supabaseAnonKey",
                    "SUPABASE_ANON_KEY",
                ]
            )

        if url_encontrada and chave_encontrada:

            break

    return (
        normalizar_url(url_encontrada),
        chave_encontrada.strip()
    )


# ============================================================
# 8. CARREGAR CONFIGURACAO
# ============================================================

def carregar_configuracao():

    global SUPABASE_URL

    global SUPABASE_KEY

    url_ambiente = os.environ.get(
        "SUPABASE_URL",
        ""
    ).strip()

    chave_ambiente = os.environ.get(
        "SUPABASE_ANON_KEY",
        ""
    ).strip()

    if not chave_ambiente:

        chave_ambiente = os.environ.get(
            "SUPABASE_PUBLISHABLE_KEY",
            ""
        ).strip()

    # Preferir uma configuracao completa do ambiente.

    if url_ambiente and chave_ambiente:

        SUPABASE_URL = normalizar_url(
            url_ambiente
        )

        SUPABASE_KEY = chave_ambiente

    else:

        url_flutter, chave_flutter = (
            carregar_configuracao_flutter()
        )

        SUPABASE_URL = normalizar_url(
            url_ambiente or url_flutter
        )

        SUPABASE_KEY = (
            chave_ambiente or chave_flutter
        ).strip()

    if not SUPABASE_URL:

        raise RuntimeError(
            "URL do Supabase nao encontrada. "
            "Verifica SUPABASE_URL ou a configuracao Dart."
        )

    if not SUPABASE_KEY:

        raise RuntimeError(
            "Chave publica do Supabase nao encontrada. "
            "Verifica publishableKey ou as variaveis de ambiente."
        )

    if SUPABASE_KEY.lower().startswith("sb_secret_"):

        raise RuntimeError(
            "Foi encontrada uma chave secreta. "
            "Utiliza uma chave publica compativel com o Supabase."
        )

    print("Configuracao do Supabase carregada.")

    print(f"Projeto: {SUPABASE_URL}")


# ============================================================
# 9. CABECALHOS HTTP DO SUPABASE
# ============================================================

def obter_cabecalhos_supabase():

    if not SUPABASE_URL or not SUPABASE_KEY:

        raise RuntimeError(
            "Executa carregar_configuracao() primeiro."
        )

    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "ObraLivre-SEO-Generator/1.0",
    }


# ============================================================
# 10. CONSULTAR A API REST
# ============================================================

def obter_json(url, timeout=TIMEOUT_HTTP):
    """
    Executa um pedido GET e devolve o JSON recebido.

    Erros HTTP e problemas de ligacao sao apresentados
    com mensagens compreensiveis.
    """

    pedido = urllib.request.Request(
        url,
        headers=obter_cabecalhos_supabase(),
        method="GET"
    )

    try:

        with urllib.request.urlopen(
            pedido,
            timeout=timeout
        ) as resposta:

            conteudo = resposta.read().decode(
                "utf-8",
                errors="replace"
            )

            if not conteudo.strip():

                return []

            return json.loads(conteudo)

    except urllib.error.HTTPError as erro:

        detalhe = erro.read().decode(
            "utf-8",
            errors="replace"
        )

        raise RuntimeError(
            f"Erro HTTP {erro.code} ao consultar o Supabase: "
            f"{detalhe[:1000]}"
        ) from erro

    except urllib.error.URLError as erro:

        raise RuntimeError(
            f"Nao foi possivel ligar ao Supabase: {erro.reason}"
        ) from erro

    except json.JSONDecodeError as erro:

        raise RuntimeError(
            "O Supabase devolveu uma resposta JSON invalida."
        ) from erro


# ============================================================
# 11. CONSULTAR UMA TABELA
# ============================================================

def consultar_tabela(
    tabela,
    colunas="*",
    filtros=None,
    limite=None,
    ordenar=None
):
    """
    Consulta uma tabela publica atraves da API REST.

    Os filtros devem ser fornecidos como um dicionario.

    Exemplo:
        filtros={"obra_id": "eq.UUID"}
    """

    parametros = {
        "select": colunas
    }

    if filtros:

        parametros.update(filtros)

    if limite is not None:

        parametros["limit"] = str(limite)

    if ordenar:

        parametros["order"] = ordenar

    query = urllib.parse.urlencode(
        parametros,
        doseq=True
    )

    url = (
        f"{SUPABASE_URL}/rest/v1/"
        f"{urllib.parse.quote(tabela, safe='')}"
        f"?{query}"
    )

    resultado = obter_json(url)

    if not isinstance(resultado, list):

        raise RuntimeError(
            f"A tabela {tabela} nao devolveu uma lista de registos."
        )

    return resultado


# ============================================================
# 12. OBTER OBRAS PUBLICADAS
# ============================================================

def obter_obras():

    print("A consultar obras...")

    obras = consultar_tabela(
        tabela=TABELA_OBRAS,
        colunas=COLUNAS_OBRAS,
        ordenar="created_at.desc"
    )

    # Ignorar registos sem identificador ou titulo.

    obras_validas = []

    for obra in obras:

        if not isinstance(obra, dict):

            continue

        if not obra.get("id"):

            continue

        if not str(obra.get("titulo") or "").strip():

            continue

        obras_validas.append(obra)

    print(
        f"Obras encontradas: {len(obras_validas)}"
    )

    return obras_validas


# ============================================================
# 13. OBTER SECOES DE UMA OBRA
# ============================================================

def obter_secoes(obra_id):

    if not obra_id:

        return []

    secoes = consultar_tabela(
        tabela=TABELA_SECOES,
        colunas=COLUNAS_SECOES,
        filtros={
            "obra_id": f"eq.{obra_id}"
        },
        ordenar="ordem.asc"
    )

    # Ordenar de forma estavel.

    secoes.sort(
        key=lambda secao: (
            secao.get("ordem")
            if isinstance(secao.get("ordem"), (int, float))
            else 999999
        )
    )

    return secoes


# ============================================================
# 14. OBTER IMAGENS DE UMA OBRA
# ============================================================

def obter_imagens(obra_id):

    if not obra_id:

        return []

    imagens = consultar_tabela(
        tabela=TABELA_IMAGENS,
        colunas=COLUNAS_IMAGENS,
        filtros={
            "obra_id": f"eq.{obra_id}"
        }
    )

    def chave_ordenacao(imagem):

        paragrafo = imagem.get(
            "paragrafo_ordem"
        )

        ordem = imagem.get(
            "ordem"
        )

        if not isinstance(paragrafo, (int, float)):

            paragrafo = 999999

        if not isinstance(ordem, (int, float)):

            ordem = 999999

        return paragrafo, ordem

    imagens.sort(
        key=chave_ordenacao
    )

    return imagens


# ============================================================
# FIM DA PARTE 1 DE 3
# ============================================================
# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 2 DE 3
#
# Preparacao do conteudo, SEO e HTML das obras.
# ============================================================


# ============================================================
# 15. FUNCOES DE TEXTO E HTML
# ============================================================

def texto_seguro(valor):
    """
    Converte um valor para texto e remove espacos desnecessarios.
    """

    if valor is None:
        return ""

    return str(valor).strip()


def escapar_html(valor):
    """
    Escapa caracteres especiais antes de inserir texto no HTML.
    """

    return html.escape(
        texto_seguro(valor),
        quote=True
    )


def limpar_html(texto):
    """
    Remove etiquetas HTML e normaliza o texto.
    """

    if not texto:
        return ""

    texto = str(texto)

    texto = re.sub(
        r"<script\b[^>]*>.*?</script>",
        " ",
        texto,
        flags=re.IGNORECASE | re.DOTALL
    )

    texto = re.sub(
        r"<style\b[^>]*>.*?</style>",
        " ",
        texto,
        flags=re.IGNORECASE | re.DOTALL
    )

    texto = re.sub(
        r"<[^>]+>",
        " ",
        texto
    )

    texto = html.unescape(texto)

    texto = re.sub(
        r"\s+",
        " ",
        texto
    )

    return texto.strip()


def limitar_texto(texto, limite):
    """
    Limita o comprimento de um texto sem cortar uma palavra.
    """

    texto = limpar_html(texto)

    if len(texto) <= limite:
        return texto

    trecho = texto[:limite]

    ultimo_espaco = trecho.rfind(" ")

    if ultimo_espaco > limite * 0.7:
        trecho = trecho[:ultimo_espaco]

    return trecho.rstrip(" ,.;:") + "..."


def slug_texto(texto):
    """
    Cria uma representação simples de texto para comparação.
    """

    texto = texto_seguro(texto).lower()

    substituicoes = {
        "á": "a",
        "à": "a",
        "ã": "a",
        "â": "a",
        "é": "e",
        "ê": "e",
        "í": "i",
        "ó": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        "ç": "c",
    }

    for original, substituto in substituicoes.items():
        texto = texto.replace(original, substituto)

    texto = re.sub(
        r"[^a-z0-9\s-]",
        " ",
        texto
    )

    texto = re.sub(
        r"\s+",
        " ",
        texto
    )

    return texto.strip()


# ============================================================
# 16. VALIDAR O IDENTIFICADOR DA OBRA
# ============================================================

def id_valido(obra_id):
    """
    Verifica se o identificador tem formato UUID.
    """

    if not obra_id:
        return False

    padrao = (
        r"^[0-9a-fA-F]{8}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{12}$"
    )

    return bool(
        re.fullmatch(
            padrao,
            str(obra_id).strip()
        )
    )


# ============================================================
# 17. CONSTRUIR O URL CANONICAL
# ============================================================

def url_obra(obra_id):
    """
    Constrói o URL público de uma obra.
    """

    return (
        f"{BASE_URL}/obra/"
        f"{urllib.parse.quote(str(obra_id), safe='')}/"
    )


# ============================================================
# 18. PREPARAR O TITULO SEO
# ============================================================

def gerar_titulo_seo(obra):
    """
    Gera um titulo especifico para cada obra.

    Evita repetir apenas o nome geral do site.
    """

    titulo = texto_seguro(
        obra.get("titulo")
    )

    autor = texto_seguro(
        obra.get("autor")
    )

    categoria = texto_seguro(
        obra.get("categoria")
    )

    if not titulo:
        titulo = "Obra académica"

    # Evitar repetir o mesmo titulo se ja incluir a marca.
    titulo_normalizado = slug_texto(titulo)

    if "obra livre" in titulo_normalizado:
        return titulo

    partes = [titulo]

    if autor:
        partes.append(autor)

    resultado = " — ".join(partes)

    if len(resultado) > 100:
        resultado = titulo

        if autor and len(titulo) < 65:
            resultado = f"{titulo} — {autor}"

    if categoria and len(resultado) < 65:
        resultado = f"{resultado} | {categoria}"

    if len(resultado) > 100:
        resultado = resultado[:97].rstrip() + "..."

    return resultado


# ============================================================
# 19. PREPARAR O NOME DO AUTOR
# ============================================================

def obter_autor(obra):
    """
    Devolve o nome do autor sem inventar informacao.
    """

    autor = texto_seguro(
        obra.get("autor")
    )

    return autor or "Autor não identificado"


# ============================================================
# 20. GERAR A DESCRICAO SEO
# ============================================================

def gerar_descricao_seo(obra, secoes=None):
    """
    Gera uma descricao especifica para cada obra.

    Prioridade:
        1. Descricao da obra.
        2. Conteudo textual da obra.
        3. Texto de uma secao.
        4. Descricao geral do site.
    """

    descricao = limpar_html(
        obra.get("descricao")
    )

    conteudo = limpar_html(
        obra.get("conteudo_texto")
    )

    if descricao and len(descricao) >= 40:
        origem = descricao

    elif conteudo:
        origem = conteudo

    else:
        origem = ""

        for secao in (secoes or []):

            texto_secao = limpar_html(
                secao.get("conteudo")
            )

            if len(texto_secao) >= 40:
                origem = texto_secao
                break

        if not origem:
            origem = descricao

    if not origem:
        titulo = texto_seguro(
            obra.get("titulo")
        )

        autor = texto_seguro(
            obra.get("autor")
        )

        categoria = texto_seguro(
            obra.get("categoria")
        )

        partes = []

        if titulo:
            partes.append(titulo)

        if autor:
            partes.append(f"de {autor}")

        if categoria:
            partes.append(
                f"na área de {categoria}"
            )

        origem = (
            "Consulte esta obra académica "
            + " ".join(partes)
            + " na plataforma Obra Livre."
        )

    return limitar_texto(
        origem,
        LIMITE_DESCRICAO_SEO
    )


# ============================================================
# 21. PREPARAR A DATA DE PUBLICACAO
# ============================================================

def obter_data_iso(obra):
    """
    Devolve uma data ISO quando existe uma data valida.

    Nao inventa uma data de publicacao.
    """

    for campo in [
        "data_publicacao",
        "created_at",
        "updated_at",
    ]:

        valor = texto_seguro(
            obra.get(campo)
        )

        if not valor:
            continue

        try:

            data = datetime.fromisoformat(
                valor.replace("Z", "+00:00")
            )

            return data.date().isoformat()

        except ValueError:
            continue

    return ""


# ============================================================
# 22. GERAR JSON-LD
# ============================================================

def gerar_json_ld(obra, titulo_seo, descricao, canonical):
    """
    Produz dados estruturados para identificar a pagina.

    Utiliza CreativeWork, um tipo adequado para trabalhos
    e conteudos academicos.

    Os campos opcionais so sao incluidos quando existem.
    """

    dados = {
        "@context": "https://schema.org",
        "@type": "CreativeWork",
        "name": texto_seguro(
            obra.get("titulo")
        ),
        "url": canonical,
        "description": descricao,
        "inLanguage": "pt",
        "publisher": {
            "@type": "Organization",
            "name": "Obra Livre",
            "url": BASE_URL + "/",
        },
    }

    autor = texto_seguro(
        obra.get("autor")
    )

    categoria = texto_seguro(
        obra.get("categoria")
    )

    ano = texto_seguro(
        obra.get("ano_obra")
    )

    if autor:
        dados["author"] = {
            "@type": "Person",
            "name": autor,
        }

    if categoria:
        dados["about"] = categoria

    if ano and re.fullmatch(r"\d{4}", ano):
        dados["dateCreated"] = ano

    data_iso = obter_data_iso(obra)

    if data_iso:
        dados["datePublished"] = data_iso

    documento = texto_seguro(
        obra.get("url_documento")
    )

    if documento and documento.startswith(
        ("https://", "http://")
    ):
        dados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": documento,
            "encodingFormat": "application/pdf",
        }

    return json.dumps(
        dados,
        ensure_ascii=False
    )


# ============================================================
# 23. GERAR METADADOS OPEN GRAPH E TWITTER
# ============================================================

def gerar_metadados_social(
    titulo,
    descricao,
    canonical
):
    """
    Prepara metadados para partilha nas redes sociais.
    """

    titulo_html = escapar_html(titulo)

    descricao_html = escapar_html(descricao)

    canonical_html = escapar_html(canonical)

    favicon_html = escapar_html(
        FAVICON_URL
    )

    return f"""
    <meta property="og:type" content="article">
    <meta property="og:site_name"
          content="{escapar_html(SITE_NAME)}">
    <meta property="og:title"
          content="{titulo_html}">
    <meta property="og:description"
          content="{descricao_html}">
    <meta property="og:url"
          content="{canonical_html}">
    <meta property="og:image"
          content="{favicon_html}">

    <meta name="twitter:card"
          content="summary">
    <meta name="twitter:title"
          content="{titulo_html}">
    <meta name="twitter:description"
          content="{descricao_html}">
    <meta name="twitter:image"
          content="{favicon_html}">
    """


# ============================================================
# 24. PREPARAR O TEXTO PRINCIPAL DA OBRA
# ============================================================

def obter_texto_principal(obra, secoes):
    """
    Escolhe um texto representativo da obra.

    Evita apresentar todas as secoes completas nesta pagina,
    reduzindo a duplicacao de conteudo.
    """

    conteudo = limpar_html(
        obra.get("conteudo_texto")
    )

    descricao = limpar_html(
        obra.get("descricao")
    )

    candidatos = []

    if descricao:
        candidatos.append(descricao)

    if conteudo:
        candidatos.append(conteudo)

    for secao in secoes or []:

        texto_secao = limpar_html(
            secao.get("conteudo")
        )

        if texto_secao:
            candidatos.append(texto_secao)

    # Selecionar o primeiro texto suficientemente informativo.
    for candidato in candidatos:

        if len(candidato) >= 80:

            return limitar_texto(
                candidato,
                1200
            )

    # Se existir pouco texto, utiliza o melhor disponivel.
    if candidatos:

        return limitar_texto(
            candidatos[0],
            1200
        )

    return ""


# ============================================================
# 25. PREPARAR OS LINKS PARA O DOCUMENTO
# ============================================================

def obter_url_documento(obra):
    """
    Devolve o URL do documento quando existe.
    """

    documento = texto_seguro(
        obra.get("url_documento")
    )

    if not documento:
        return ""

    if not documento.startswith(
        ("https://", "http://")
    ):
        return ""

    return documento


# ============================================================
# 26. PREPARAR AS IMAGENS
# ============================================================

def gerar_html_imagens(imagens):
    """
    Gera HTML para as imagens da obra.

    So apresenta imagens com URL HTTP ou HTTPS.
    """

    elementos = []

    for imagem in imagens or []:

        if not isinstance(imagem, dict):
            continue

        url_imagem = texto_seguro(
            imagem.get("url_imagem")
        )

        if not url_imagem.startswith(
            ("https://", "http://")
        ):
            continue

        legenda = texto_seguro(
            imagem.get("legenda")
        )

        fonte = texto_seguro(
            imagem.get("fonte")
        )

        alt = legenda or "Imagem da obra académica"

        legenda_html = ""

        if legenda:

            legenda_html = (
                "<figcaption>"
                f"{escapar_html(legenda)}"
                "</figcaption>"
            )

        if fonte:

            legenda_html += (
                "<p class='fonte-imagem'>Fonte: "
                f"{escapar_html(fonte)}"
                "</p>"
            )

        elementos.append(
            "<figure class='imagem-obra'>"
            f"<img src='{escapar_html(url_imagem)}' "
            f"alt='{escapar_html(alt)}' "
            "loading='lazy' "
            "decoding='async'>"
            f"{legenda_html}"
            "</figure>"
        )

    return "\n".join(elementos)


# ============================================================
# 27. ENCONTRAR OBRAS RELACIONADAS
# ============================================================

def encontrar_obras_relacionadas(obra, todas_obras):
    """
    Identifica obras com titulos ou categorias semelhantes.

    A comparacao e simples e nao utiliza dados inventados.
    """

    obra_id = texto_seguro(
        obra.get("id")
    )

    titulo_atual = slug_texto(
        obra.get("titulo")
    )

    categoria_atual = slug_texto(
        obra.get("categoria")
    )

    palavras_atuais = {
        palavra
        for palavra in titulo_atual.split()
        if len(palavra) >= 4
    }

    resultados = []

    for candidata in todas_obras:

        if not isinstance(candidata, dict):
            continue

        if texto_seguro(
            candidata.get("id")
        ) == obra_id:
            continue

        titulo_candidato = slug_texto(
            candidata.get("titulo")
        )

        categoria_candidata = slug_texto(
            candidata.get("categoria")
        )

        palavras_candidatas = {
            palavra
            for palavra in titulo_candidato.split()
            if len(palavra) >= 4
        }

        intersecao = (
            palavras_atuais & palavras_candidatas
        )

        uniao = (
            palavras_atuais | palavras_candidatas
        )

        pontuacao = 0

        if uniao:
            pontuacao += (
                len(intersecao) / len(uniao)
            )

        if (
            categoria_atual
            and categoria_candidata
            and categoria_atual == categoria_candidata
        ):
            pontuacao += 0.5

        if pontuacao > 0:
            resultados.append(
                (pontuacao, candidata)
            )

    resultados.sort(
        key=lambda item: item[0],
        reverse=True
    )

    return [
        candidata
        for _, candidata in resultados[
            :LIMITE_OBRAS_RELACIONADAS
        ]
    ]


# ============================================================
# 28. GERAR HTML DAS OBRAS RELACIONADAS
# ============================================================

def gerar_html_obras_relacionadas(
    obra,
    todas_obras
):
    """
    Cria links internos para outras obras relevantes.
    """

    relacionadas = encontrar_obras_relacionadas(
        obra,
        todas_obras
    )

    if not relacionadas:
        return ""

    elementos = []

    for relacionada in relacionadas:

        obra_id = texto_seguro(
            relacionada.get("id")
        )

        titulo = texto_seguro(
            relacionada.get("titulo")
        )

        if not id_valido(obra_id) or not titulo:
            continue

        link = url_obra(obra_id)

        autor = texto_seguro(
            relacionada.get("autor")
        )

        resumo = ""

        if autor:
            resumo = (
                "<span class='autor-relacionado'>"
                f"{escapar_html(autor)}"
                "</span>"
            )

        elementos.append(
            "<li>"
            f"<a href='{escapar_html(link)}'>"
            f"{escapar_html(titulo)}"
            "</a>"
            f"{resumo}"
            "</li>"
        )

    if not elementos:
        return ""

    return (
        "<section class='relacionadas'>"
        "<h2>Obras relacionadas</h2>"
        "<ul>"
        + "\n".join(elementos)
        + "</ul>"
        "</section>"
    )


# ============================================================
# 29. GERAR BOTOES DE PARTILHA
# ============================================================

def gerar_html_partilha(titulo, canonical):
    """
    Cria botoes para copiar e partilhar a pagina.
    """

    titulo_js = json.dumps(
        titulo,
        ensure_ascii=False
    )

    url_js = json.dumps(
        canonical,
        ensure_ascii=False
    )

    return f"""
    <section class="partilha">
      <h2>Partilhar esta obra</h2>

      <button type="button" id="copiar-link">
        Copiar link
      </button>

      <button type="button" id="partilhar-link">
        Partilhar
      </button>
    </section>

    <script>
    (() => {{
      const titulo = {titulo_js};
      const url = {url_js};

      const botaoCopiar =
        document.getElementById("copiar-link");

      const botaoPartilhar =
        document.getElementById("partilhar-link");

      if (botaoCopiar) {{
        botaoCopiar.addEventListener("click", async () => {{
          try {{
            await navigator.clipboard.writeText(url);
            botaoCopiar.textContent = "Link copiado!";
          }} catch (erro) {{
            window.prompt("Copia o link da obra:", url);
          }}
        }});
      }}

      if (botaoPartilhar) {{
        botaoPartilhar.addEventListener("click", async () => {{
          if (navigator.share) {{
            try {{
              await navigator.share({{
                title: titulo,
                url: url
              }});
            }} catch (erro) {{
              // O utilizador pode cancelar a partilha.
            }}
          }} else {{
            try {{
              await navigator.clipboard.writeText(url);
              botaoPartilhar.textContent = "Link copiado!";
            }} catch (erro) {{
              window.prompt("Copia o link da obra:", url);
            }}
          }}
        }});
      }}
    }})();
    </script>
    """


# ============================================================
# 30. GERAR A PAGINA HTML COMPLETA
# ============================================================

def gerar_pagina_obra(obra, todas_obras):
    """
    Gera a pagina HTML individual de uma obra.

    O HTML inclui:
        - Titulo SEO individual.
        - Meta description.
        - Canonical.
        - Open Graph e Twitter.
        - Dados estruturados JSON-LD.
        - Texto representativo da obra.
        - Imagens.
        - Link para o documento.
        - Obras relacionadas.
        - Botoes de partilha.
    """

    obra_id = texto_seguro(
        obra.get("id")
    )

    if not id_valido(obra_id):

        print(
            f"Identificador invalido: {obra_id}"
        )

        return False

    titulo = texto_seguro(
        obra.get("titulo")
    )

    if not titulo:
        return False

    autor = obter_autor(obra)

    categoria = texto_seguro(
        obra.get("categoria")
    )

    ano = texto_seguro(
        obra.get("ano_obra")
    )

    canonical = url_obra(
        obra_id
    )

    # Consultar os dados associados a esta obra.

    try:

        secoes = obter_secoes(
            obra_id
        )

    except Exception as erro:

        print(
            f"Aviso: nao foi possivel consultar secoes "
            f"da obra {obra_id}: {erro}"
        )

        secoes = []

    try:

        imagens = obter_imagens(
            obra_id
        )

    except Exception as erro:

        print(
            f"Aviso: nao foi possivel consultar imagens "
            f"da obra {obra_id}: {erro}"
        )

        imagens = []

    titulo_seo = gerar_titulo_seo(
        obra
    )

    descricao_seo = gerar_descricao_seo(
        obra,
        secoes
    )

    texto_principal = obter_texto_principal(
        obra,
        secoes
    )

    documento = obter_url_documento(
        obra
    )

    json_ld = gerar_json_ld(
        obra,
        titulo_seo,
        descricao_seo,
        canonical
    )

    metadados_social = gerar_metadados_social(
        titulo_seo,
        descricao_seo,
        canonical
    )

    html_imagens = gerar_html_imagens(
        imagens
    )

    html_relacionadas = gerar_html_obras_relacionadas(
        obra,
        todas_obras
    )

    html_partilha = gerar_html_partilha(
        titulo_seo,
        canonical
    )

    # Informacao bibliografica apresentada na pagina.

    metadados_obra = [
        "<dl class='metadados-obra'>",
        "<dt>Titulo</dt>",
        f"<dd>{escapar_html(titulo)}</dd>",
        "<dt>Autor</dt>",
        f"<dd>{escapar_html(autor)}</dd>",
    ]

    if categoria:

        metadados_obra.extend([
            "<dt>Categoria</dt>",
            f"<dd>{escapar_html(categoria)}</dd>",
        ])

    if ano:

        metadados_obra.extend([
            "<dt>Ano</dt>",
            f"<dd>{escapar_html(ano)}</dd>",
        ])

    numero_paginas = obra.get(
        "numero_paginas"
    )

    if numero_paginas is not None:

        metadados_obra.extend([
            "<dt>Numero de paginas</dt>",
            f"<dd>{escapar_html(numero_paginas)}</dd>",
        ])

    metadados_obra.append("</dl>")

    html_metadados = "\n".join(
        metadados_obra
    )

    # Texto representativo, sem duplicar todas as secoes.

    html_conteudo = ""

    if texto_principal:

        html_conteudo = (
            "<section class='resumo-obra'>"
            "<h2>Sobre esta obra</h2>"
            f"<p>{escapar_html(texto_principal)}</p>"
            "</section>"
        )

    # Botao de acesso ao documento.

    html_documento = ""

    if documento:

        documento_seguro = escapar_html(
            documento
        )

        html_documento = f"""
        <section class="documento">
          <h2>Consultar documento</h2>

          <p>
            Pode abrir o documento original para consultar
            o conteudo completo da obra.
          </p>

          <p>
            <a class="botao"
               href="{documento_seguro}"
               target="_blank"
               rel="noopener noreferrer">
               Ler documento
            </a>

            <a class="botao secundario"
               href="{documento_seguro}"
               target="_blank"
               rel="noopener noreferrer">
               Abrir PDF
            </a>
          </p>
        </section>
        """

    # Construir o HTML final.

    pagina = f"""<!DOCTYPE html>
<html lang="pt">
<head>
  <meta charset="UTF-8">

  <meta name="viewport"
        content="width=device-width, initial-scale=1">

  <title>{escapar_html(titulo_seo)}</title>

  <meta name="description"
        content="{escapar_html(descricao_seo)}">

  <meta name="robots"
        content="index, follow, max-image-preview:large">

  <link rel="canonical"
        href="{escapar_html(canonical)}">

  <link rel="icon"
        href="{escapar_html(FAVICON_URL)}">

  {metadados_social}

  <script type="application/ld+json">{json_ld}</script>

  <style>
    * {{
      box-sizing: border-box;
    }}

    body {{
      margin: 0;
      padding: 0;
      color: #222;
      background: #f5f7fa;
      font-family: Arial, Helvetica, sans-serif;
      font-size: 18px;
      line-height: 1.8;
    }}

    header {{
      background: #ffffff;
      border-bottom: 1px solid #dddddd;
      padding: 18px 5%;
    }}

    header a {{
      color: #174ea6;
      font-weight: bold;
      text-decoration: none;
    }}

    main {{
      max-width: 1000px;
      margin: 30px auto;
      padding: 30px;
      background: #ffffff;
      border-radius: 10px;
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
    }}

    h1 {{
      color: #17365d;
      font-size: clamp(26px, 4vw, 36px);
      line-height: 1.35;
      overflow-wrap: anywhere;
    }}

    h2 {{
      margin-top: 32px;
      color: #17365d;
      font-size: 24px;
      line-height: 1.4;
    }}

    p {{
      text-align: justify;
      overflow-wrap: anywhere;
    }}

    .metadados-obra {{
      display: grid;
      grid-template-columns: minmax(120px, 200px) 1fr;
      gap: 8px 16px;
      padding: 20px;
      background: #f7f9fc;
      border-radius: 8px;
    }}

    .metadados-obra dt {{
      font-weight: bold;
    }}

    .metadados-obra dd {{
      margin: 0;
      overflow-wrap: anywhere;
    }}

    .botao,
    .partilha button {{
      display: inline-block;
      margin: 5px 5px 5px 0;
      padding: 11px 18px;
      border: none;
      border-radius: 6px;
      background: #1769aa;
      color: white;
      font-size: 16px;
      font-weight: bold;
      text-decoration: none;
      cursor: pointer;
    }}

    .botao.secundario {{
      background: #465566;
    }}

    .partilha {{
      margin-top: 35px;
      padding: 20px;
      background: #f7f9fc;
      border-radius: 8px;
    }}

    .relacionadas li {{
      margin-bottom: 12px;
    }}

    .relacionadas a {{
      color: #1759a6;
      font-weight: bold;
    }}

    .autor-relacionado {{
      display: block;
      color: #555;
      font-size: 15px;
    }}

    .imagem-obra {{
      margin: 25px 0;
      text-align: center;
    }}

    .imagem-obra img {{
      display: block;
      max-width: 100%;
      height: auto;
      margin: auto;
      border-radius: 5px;
    }}

    .imagem-obra figcaption,
    .fonte-imagem {{
      font-size: 14px;
      color: #555;
      text-align: center;
    }}

    footer {{
      max-width: 1000px;
      margin: 20px auto;
      padding: 20px;
      text-align: center;
      color: #555;
      font-size: 14px;
    }}

    footer a {{
      color: #1759a6;
    }}

    @media (max-width: 650px) {{
      body {{
        font-size: 17px;
      }}

      main {{
        margin: 12px;
        padding: 18px;
      }}

      .metadados-obra {{
        grid-template-columns: 1fr;
        gap: 3px;
      }}

      .metadados-obra dd {{
        margin-bottom: 12px;
      }}
    }}
  </style>
</head>

<body>

  <header>
    <a href="{escapar_html(BASE_URL + '/')}"
       aria-label="Pagina inicial do Obra Livre">
       Obra Livre — Obras Académicas
    </a>
  </header>

  <main>

    <nav aria-label="Navegacao">
      <a href="{escapar_html(BASE_URL + '/')}">
        Página inicial
      </a>
      &rsaquo;
      <span>Obra académica</span>
    </nav>

    <article>

      <h1>{escapar_html(titulo)}</h1>

      {html_metadados}

      <p>
        Esta página apresenta informação sobre a obra
        publicada na plataforma Obra Livre.
      </p>

      {html_conteudo}

      {html_imagens}

      {html_documento}

      {html_relacionadas}

      {html_partilha}

    </article>

  </main>

  <footer>
    <p>
      <a href="{escapar_html(BASE_URL + '/')}">
        Obra Livre
      </a>
      — Plataforma de consulta e publicação de obras académicas.
    </p>

    <p>
      <a href="{escapar_html(BASE_URL + '/ajuda/')}">
        Ajuda
      </a>
      |
      <a href="{escapar_html(BASE_URL + '/contacto/')}">
        Contacto
      </a>
      |
      <a href="{escapar_html(BASE_URL + '/politica-privacidade/')}">
        Política de privacidade
      </a>
    </p>
  </footer>

</body>
</html>
"""

    # Guardar cada obra numa pasta individual.

    pasta_obra = OUTPUT_DIR / "obra" / obra_id

    pasta_obra.mkdir(
        parents=True,
        exist_ok=True
    )

    caminho_html = pasta_obra / "index.html"

    caminho_html.write_text(
        pagina,
        encoding="utf-8"
    )

    print(
        f"Pagina SEO gerada: {caminho_html}"
    )

    return True


# ============================================================
# FIM DA PARTE 2 DE 3
# ============================================================
# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 3 DE 3
#
# Sitemap XML, robots.txt, validacoes e execucao.
# ============================================================


# ============================================================
# 31. OBTER DATA DE MODIFICACAO DA OBRA
# ============================================================

def obter_data_modificacao(obra):
    """
    Devolve a data de modificacao da obra.

    Utiliza updated_at, created_at ou data_publicacao,
    quando existe uma data valida.
    """

    for campo in [
        "updated_at",
        "created_at",
        "data_publicacao",
    ]:

        valor = texto_seguro(
            obra.get(campo)
        )

        if not valor:
            continue

        try:

            data = datetime.fromisoformat(
                valor.replace("Z", "+00:00")
            )

            return data.date().isoformat()

        except ValueError:
            continue

    return date.today().isoformat()


# ============================================================
# 32. LISTA DE PAGINAS PRINCIPAIS
# ============================================================

def obter_paginas_principais():
    """
    Devolve os URLs principais do site.

    Estas paginas devem existir publicamente.
    """

    caminhos = [
        "/",
        "/acervo/",
        "/categorias/",
        "/termos/",
        "/politica-privacidade/",
        "/cookies/",
        "/contacto/",
        "/ajuda/",
    ]

    return [
        BASE_URL.rstrip("/") + caminho
        for caminho in caminhos
    ]


# ============================================================
# 33. GERAR SITEMAP XML
# ============================================================

def gerar_sitemap(obras):
    """
    Gera sitemap.xml com as paginas principais e as obras.

    Cada URL e acrescentado uma unica vez.
    """

    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"

    ET.register_namespace("", namespace)

    elemento_urlset = ET.Element(
        f"{{{namespace}}}urlset"
    )

    urls_adicionados = set()

    def adicionar_url(url, data_modificacao=None):

        if not url:
            return

        url = url.strip()

        if not url.startswith(
            ("https://", "http://")
        ):
            return

        if url in urls_adicionados:
            return

        urls_adicionados.add(url)

        elemento_url = ET.SubElement(
            elemento_urlset,
            f"{{{namespace}}}url"
        )

        elemento_loc = ET.SubElement(
            elemento_url,
            f"{{{namespace}}}loc"
        )

        elemento_loc.text = url

        if data_modificacao:

            elemento_lastmod = ET.SubElement(
                elemento_url,
                f"{{{namespace}}}lastmod"
            )

            elemento_lastmod.text = (
                data_modificacao
            )

    # Paginas principais.

    for url in obter_paginas_principais():

        adicionar_url(
            url,
            date.today().isoformat()
        )

    # Paginas individuais das obras.

    for obra in obras:

        if not isinstance(obra, dict):
            continue

        obra_id = texto_seguro(
            obra.get("id")
        )

        if not id_valido(obra_id):
            continue

        adicionar_url(
            url_obra(obra_id),
            obter_data_modificacao(obra)
        )

    # Escrever o XML.

    arvore = ET.ElementTree(
        elemento_urlset
    )

    caminho_sitemap = (
        OUTPUT_DIR / "sitemap.xml"
    )

    arvore.write(
        caminho_sitemap,
        encoding="utf-8",
        xml_declaration=True
    )

    print(
        f"Sitemap gerado: {caminho_sitemap}"
    )

    print(
        f"URLs no sitemap: {len(urls_adicionados)}"
    )

    return caminho_sitemap


# ============================================================
# 34. GERAR ROBOTS.TXT
# ============================================================

def gerar_robots():
    """
    Gera robots.txt para orientar os motores de pesquisa.

    Nao bloqueia a indexacao das paginas publicas.
    """

    conteudo = f"""User-agent: *
Allow: /

Sitemap: {SITEMAP_URL}
"""

    caminho_robots = OUTPUT_DIR / "robots.txt"

    caminho_robots.write_text(
        conteudo,
        encoding="utf-8"
    )

    print(
        f"robots.txt gerado: {caminho_robots}"
    )

    return caminho_robots


# ============================================================
# 35. VALIDAR O HTML GERADO
# ============================================================

def validar_pagina_html(caminho_html):
    """
    Verifica a presenca dos elementos SEO fundamentais.

    Esta verificacao nao substitui os testes do Google.
    """

    try:

        conteudo = caminho_html.read_text(
            encoding="utf-8"
        )

    except OSError as erro:

        print(
            f"Erro ao ler {caminho_html}: {erro}"
        )

        return False

    verificacoes = {
        "DOCTYPE": "<!DOCTYPE html>" in conteudo,
        "Idioma": '<html lang="pt">' in conteudo,
        "Titulo": "<title>" in conteudo,
        "Descricao SEO": (
            'name="description"' in conteudo
        ),
        "Canonical": (
            'rel="canonical"' in conteudo
        ),
        "Robots": (
            'name="robots"' in conteudo
        ),
        "JSON-LD": (
            'application/ld+json' in conteudo
        ),
        "H1": (
            "<h1>" in conteudo
        ),
    }

    falhas = [
        nome
        for nome, valido in verificacoes.items()
        if not valido
    ]

    if falhas:

        print(
            f"Validacao incompleta: {caminho_html}"
        )

        for falha in falhas:

            print(
                f"  - Falta: {falha}"
            )

        return False

    return True


# ============================================================
# 36. GERAR TODAS AS PAGINAS
# ============================================================

def gerar_todas_as_paginas(obras):
    """
    Gera as paginas SEO de todas as obras validas.
    """

    total = 0

    sucessos = 0

    erros = 0

    for obra in obras:

        total += 1

        try:

            gerada = gerar_pagina_obra(
                obra,
                obras
            )

            if gerada:

                caminho_html = (
                    OUTPUT_DIR
                    / "obra"
                    / str(obra["id"])
                    / "index.html"
                )

                if validar_pagina_html(
                    caminho_html
                ):

                    sucessos += 1

                else:

                    erros += 1

            else:

                erros += 1

        except Exception as erro:

            erros += 1

            print(
                f"Erro ao gerar a obra "
                f"{obra.get('id', 'sem ID')}: {erro}"
            )

    print("")
    print("Resumo da geracao de paginas SEO")
    print("--------------------------------")
    print(f"Total de obras: {total}")
    print(f"Paginas geradas e validadas: {sucessos}")
    print(f"Erros: {erros}")

    return sucessos, erros


# ============================================================
# 37. EXECUCAO PRINCIPAL
# ============================================================

def main():
    """
    Executa o processo completo.

    Ordem:
        1. Preparar a pasta de destino.
        2. Carregar configuracao.
        3. Consultar obras.
        4. Gerar paginas HTML.
        5. Gerar sitemap.
        6. Gerar robots.txt.
    """

    print("")
    print("=" * 60)
    print("OBRA LIVRE — GERADOR DE PAGINAS SEO")
    print("=" * 60)
    print("")

    # Criar pasta de destino.

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    # Carregar configuracao.

    try:

        carregar_configuracao()

    except Exception as erro:

        print("")
        print("ERRO DE CONFIGURACAO")
        print(str(erro))
        print("")
        print(
            "Confirma a URL e a chave publica do Supabase."
        )

        return 1

    # Consultar as obras.

    try:

        obras = obter_obras()

    except Exception as erro:

        print("")
        print("ERRO AO CONSULTAR O SUPABASE")
        print(str(erro))
        print("")

        return 1

    if not obras:

        print(
            "Aviso: nao foram encontradas obras."
        )

        print(
            "O sitemap nao sera substituido para evitar "
            "publicar um sitemap vazio por engano."
        )

        return 1

    # Gerar paginas.

    _, erros = gerar_todas_as_paginas(
        obras
    )

    # Gerar sitemap.

    try:

        gerar_sitemap(
            obras
        )

    except Exception as erro:

        print(
            f"Erro ao gerar sitemap: {erro}"
        )

        return 1

    # Gerar robots.txt.

    try:

        gerar_robots()

    except Exception as erro:

        print(
            f"Erro ao gerar robots.txt: {erro}"
        )

        return 1

    print("")
    print("=" * 60)
    print("PROCESSO SEO CONCLUIDO")
    print("=" * 60)

    print("")
    print(
        f"Paginas publicas: {BASE_URL}/obra/"
    )

    print(
        f"Sitemap: {SITEMAP_URL}"
    )

    print(
        f"Robots: {ROBOTS_URL}"
    )

    if erros:

        print("")
        print(
            "Aviso: algumas paginas precisam de verificacao."
        )

        return 1

    print("")
    print(
        "Verifica os ficheiros gerados antes de publicar."
    )

    return 0


# ============================================================
# 38. INICIAR O PROGRAMA
# ============================================================

if __name__ == "__main__":

    try:

        codigo_saida = main()

    except KeyboardInterrupt:

        print("")
        print(
            "Execucao interrompida pelo utilizador."
        )

        codigo_saida = 130

    except Exception as erro:

        print("")
        print(
            f"Erro inesperado: {erro}"
        )

        codigo_saida = 1

    sys.exit(codigo_saida)


# ============================================================
# FIM DO FICHEIRO
# ============================================================
