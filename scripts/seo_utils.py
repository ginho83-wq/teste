"""Funções utilitárias e metadados SEO."""
import html
import json
import re
import urllib.parse
from datetime import datetime, timezone, date

from seo_config import BASE_URL, SITE_NAME, SITE_DESCRIPTION

def texto_seguro(valor, padrao=""):
    """
    Converte um valor em texto de forma segura.
    """
    if valor is None:
        return padrao

    try:
        return str(valor).strip()
    except Exception:
        return padrao

def escapar_html(valor):
    """
    Protege textos antes de os inserir no HTML.
    """
    return html.escape(texto_seguro(valor), quote=True)

def limpar_html(valor):
    """
    Remove etiquetas HTML e normaliza o texto.
    """
    texto = texto_seguro(valor)

    texto = re.sub(
        r"(?is)<(script|style).*?>.*?</\1>",
        " ",
        texto,
    )

    texto = re.sub(
        r"(?s)<[^>]*>",
        " ",
        texto,
    )

    texto = html.unescape(texto)

    texto = re.sub(r"\s+", " ", texto).strip()

    return texto

def limitar_texto(texto, limite=300):
    """
    Limita o comprimento de um texto sem cortar
    uma palavra a meio.
    """
    texto = limpar_html(texto)

    if len(texto) <= limite:
        return texto

    resultado = texto[:limite].rsplit(" ", 1)[0].strip()

    if not resultado:
        resultado = texto[:limite].strip()

    return resultado.rstrip(".,;: ") + "..."

def slug_texto(texto):
    """
    Produz uma versao simplificada de um texto.
    """
    texto = texto_seguro(texto).lower()

    substituicoes = {
        "á": "a",
        "à": "a",
        "ã": "a",
        "â": "a",
        "ä": "a",
        "é": "e",
        "è": "e",
        "ê": "e",
        "ë": "e",
        "í": "i",
        "ì": "i",
        "î": "i",
        "ï": "i",
        "ó": "o",
        "ò": "o",
        "õ": "o",
        "ô": "o",
        "ö": "o",
        "ú": "u",
        "ù": "u",
        "û": "u",
        "ü": "u",
        "ç": "c",
        "ñ": "n",
    }

    for origem, destino in substituicoes.items():
        texto = texto.replace(origem, destino)

    texto = re.sub(r"[^a-z0-9]+", "-", texto)

    return texto.strip("-")

def id_valido(valor):
    """
    Verifica se o identificador parece ser um UUID.
    """
    valor = texto_seguro(valor)

    return bool(
        re.fullmatch(
            r"[0-9a-fA-F]{8}-"
            r"[0-9a-fA-F]{4}-"
            r"[0-9a-fA-F]{4}-"
            r"[0-9a-fA-F]{4}-"
            r"[0-9a-fA-F]{12}",
            valor,
        )
    )

def url_obra(obra_id):
    """
    Gera o endereco publico da obra.
    Mantem a estrutura atual do site.
    """
    obra_id = urllib.parse.quote(
        texto_seguro(obra_id),
        safe="-",
    )

    return f"{BASE_URL}/obra/{obra_id}/"

def gerar_titulo_seo(obra):
    """
    Gera o titulo SEO da obra.
    """
    titulo = texto_seguro(obra.get("titulo"))

    if not titulo:
        titulo = "Obra académica"

    nome_site = "Obra Livre"

    limite_titulo = 65

    sufixo = f" | {nome_site}"

    espaco_disponivel = limite_titulo - len(sufixo)

    if len(titulo) > espaco_disponivel:
        titulo = limitar_texto(
            titulo,
            espaco_disponivel,
        ).rstrip(".")

    return f"{titulo}{sufixo}"

def obter_autor(obra):
    """
    Obtem o nome do autor.
    """
    autor = texto_seguro(obra.get("autor"))

    return autor if autor else "Autor não informado"

def gerar_descricao_seo(obra):
    """
    Cria uma descricao SEO com base nos dados da obra.
    """
    titulo = texto_seguro(obra.get("titulo"))

    descricao = limpar_html(
        obra.get("descricao")
        or obra.get("conteudo_texto")
        or ""
    )

    categoria = texto_seguro(obra.get("categoria"))

    autor = texto_seguro(obra.get("autor"))

    partes = []

    if titulo:
        partes.append(titulo)

    if descricao:
        partes.append(limitar_texto(descricao, 190))

    if categoria:
        partes.append(f"Categoria: {categoria}")

    if autor:
        partes.append(f"Autor: {autor}")

    resultado = " ".join(partes)

    if not resultado:
        resultado = SITE_DESCRIPTION

    return limitar_texto(resultado, 300)

def obter_data_iso(valor):
    """
    Converte uma data para o formato ISO quando possivel.
    """
    valor = texto_seguro(valor)

    if not valor:
        return ""

    try:
        data = datetime.fromisoformat(
            valor.replace("Z", "+00:00")
        )

        return data.isoformat()
    except (ValueError, TypeError):
        pass

    try:
        data = date.fromisoformat(valor[:10])

        return data.isoformat()
    except (ValueError, TypeError):
        return ""

def gerar_json_ld(obra):
    """
    Gera dados estruturados para mecanismos de pesquisa.
    """
    titulo = texto_seguro(obra.get("titulo"))

    autor = texto_seguro(obra.get("autor"))

    descricao = gerar_descricao_seo(obra)

    obra_id = texto_seguro(obra.get("id"))

    data_publicacao = obter_data_iso(
        obra.get("data_publicacao")
        or obra.get("created_at")
    )

    documento = obter_url_documento(obra)

    dados = {
        "@context": "https://schema.org",
        "@type": "ScholarlyArticle",
        "headline": titulo,
        "description": descricao,
        "url": url_obra(obra_id),
        "publisher": {
            "@type": "Organization",
            "name": SITE_NAME,
            "url": BASE_URL,
        },
    }

    if autor:
        dados["author"] = {
            "@type": "Person",
            "name": autor,
        }

    if data_publicacao:
        dados["datePublished"] = data_publicacao

    if documento:
        dados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": documento,
            "encodingFormat": "application/pdf",
        }

    ano = texto_seguro(obra.get("ano_obra"))

    if ano.isdigit() and len(ano) == 4:
        dados["dateCreated"] = ano

    categoria = texto_seguro(obra.get("categoria"))

    if categoria:
        dados["about"] = categoria

    return json.dumps(
        dados,
        ensure_ascii=False,
    ).replace("</", "<\\/")

def gerar_metadados_social(obra):
    """
    Gera as etiquetas Open Graph e Twitter Cards.
    """
    titulo = gerar_titulo_seo(obra)

    descricao = gerar_descricao_seo(obra)

    url = url_obra(obra.get("id"))

    titulo_html = escapar_html(titulo)

    descricao_html = escapar_html(descricao)

    url_html = escapar_html(url)

    return f"""
    <meta property="og:type" content="article">
    <meta property="og:site_name" content="{escapar_html(SITE_NAME)}">
    <meta property="og:title" content="{titulo_html}">
    <meta property="og:description" content="{descricao_html}">
    <meta property="og:url" content="{url_html}">
    <meta property="og:locale" content="pt_PT">

    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="{titulo_html}">
    <meta name="twitter:description" content="{descricao_html}">
    """

def obter_texto_principal(obra):
    """
    Obtem um texto representativo para a pagina SEO.

    Evita reproduzir desnecessariamente o conteudo integral
    da obra na pagina gerada.
    """
    descricao = limpar_html(
        obra.get("descricao")
    )

    if descricao:
        return limitar_texto(descricao, 1200)

    conteudo = limpar_html(
        obra.get("conteudo_texto")
    )

    if conteudo:
        return limitar_texto(conteudo, 1000)

    return (
        "Consulte as informacoes desta obra académica "
        "na plataforma Obra Livre e aceda ao documento "
        "disponibilizado pelo autor, quando estiver disponível."
    )

def obter_url_documento(obra):
    """
    Obtem e valida o endereco do documento.
    """
    documento = texto_seguro(
        obra.get("url_documento")
    )

    if not documento:
        return ""

    documento = documento.replace("&amp;", "&")

    try:
        partes = urllib.parse.urlsplit(documento)

        if partes.scheme not in ("http", "https"):
            return ""

        if not partes.netloc:
            return ""

        if partes.username or partes.password:
            return ""

        return documento
    except (ValueError, TypeError):
        return ""

