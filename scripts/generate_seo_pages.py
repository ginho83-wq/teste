# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 1 DE 3
#
# Configuracao, estilos visuais e estrutura da pagina.
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
# CONFIGURACAO GERAL
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

SUPABASE_TABLE_OBRAS = "obras"

SUPABASE_TABLE_SECOES = "teste_secoes"

SUPABASE_TABLE_IMAGENS = "teste_imagens"


# ============================================================
# IDENTIDADE VISUAL
# ============================================================

COR_PRIMARIA = "#174A7E"

COR_PRIMARIA_ESCURO = "#103456"

COR_SECUNDARIA = "#1769AA"

COR_FUNDO = "#F4F7FB"

COR_CARTAO = "#FFFFFF"

COR_TEXTO = "#263445"

COR_TEXTO_SECUNDARIO = "#64748B"

COR_BORDA = "#E2E8F0"

COR_SUCESSO = "#16794B"


# ============================================================
# ESTILOS CSS
# ============================================================

def gerar_css():
    """
    Gera os estilos responsivos das paginas SEO.
    """

    return r"""
    :root {
        --cor-primaria: #174A7E;
        --cor-primaria-escuro: #103456;
        --cor-secundaria: #1769AA;
        --cor-fundo: #F4F7FB;
        --cor-cartao: #FFFFFF;
        --cor-texto: #263445;
        --cor-texto-secundario: #64748B;
        --cor-borda: #E2E8F0;
        --cor-sucesso: #16794B;

        --largura-conteudo: 1120px;

        --raio-pequeno: 8px;
        --raio-medio: 14px;
        --raio-grande: 20px;

        --sombra-cartao:
            0 4px 20px rgba(15, 40, 70, 0.055);

        --sombra-destaque:
            0 10px 30px rgba(15, 40, 70, 0.09);
    }

    *,
    *::before,
    *::after {
        box-sizing: border-box;
    }

    html {
        scroll-behavior: smooth;
        -webkit-text-size-adjust: 100%;
    }

    body {
        margin: 0;
        padding: 0;
        background: var(--cor-fundo);
        color: var(--cor-texto);
        font-family:
            Inter,
            -apple-system,
            BlinkMacSystemFont,
            "Segoe UI",
            Roboto,
            Arial,
            sans-serif;
        font-size: 16px;
        line-height: 1.75;
        -webkit-font-smoothing: antialiased;
    }

    img {
        max-width: 100%;
        height: auto;
    }

    a {
        color: var(--cor-secundaria);
        text-decoration: none;
    }

    a:hover {
        text-decoration: none;
    }

    a:focus-visible,
    button:focus-visible {
        outline: 3px solid rgba(23, 105, 170, 0.35);
        outline-offset: 3px;
    }

    button {
        font: inherit;
    }

    .pagina {
        min-height: 100vh;
        display: flex;
        flex-direction: column;
    }

    .contentor {
        width: min(
            var(--largura-conteudo),
            calc(100% - 40px)
        );
        margin-left: auto;
        margin-right: auto;
    }


    /* ========================================================
       CABECALHO
       ======================================================== */

    .cabecalho {
        background: #FFFFFF;
        border-bottom: 1px solid var(--cor-borda);
        position: relative;
        z-index: 10;
    }

    .cabecalho-interior {
        min-height: 76px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 24px;
    }

    .marca {
        display: inline-flex;
        align-items: center;
        gap: 12px;
        min-width: 0;
        color: var(--cor-primaria);
        text-decoration: none;
    }

    .marca-simbolo {
        width: 44px;
        height: 44px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        border-radius: 12px;
        background: var(--cor-primaria);
        color: #FFFFFF;
        font-size: 21px;
        font-weight: 800;
        letter-spacing: -1px;
        box-shadow:
            0 5px 12px rgba(23, 74, 126, 0.18);
    }

    .marca-texto {
        display: flex;
        flex-direction: column;
        line-height: 1.25;
    }

    .marca-nome {
        color: var(--cor-primaria-escuro);
        font-size: 19px;
        font-weight: 800;
        letter-spacing: -0.45px;
    }

    .marca-descricao {
        margin-top: 4px;
        color: var(--cor-texto-secundario);
        font-size: 11px;
        font-weight: 500;
        letter-spacing: 0.35px;
    }

    .cabecalho-link {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        padding: 10px 16px;
        border: 1px solid var(--cor-borda);
        border-radius: 9px;
        color: var(--cor-primaria);
        font-size: 13px;
        font-weight: 700;
        transition:
            background 0.2s ease,
            border-color 0.2s ease;
    }

    .cabecalho-link:hover {
        background: #F1F6FB;
        border-color: #B9CCDE;
    }


    /* ========================================================
       AREA PRINCIPAL
       ======================================================== */

    .conteudo-principal {
        flex: 1;
        padding-top: 34px;
        padding-bottom: 56px;
    }

    .caminho-navegacao {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
        margin-bottom: 24px;
        color: var(--cor-texto-secundario);
        font-size: 12px;
    }

    .caminho-navegacao a {
        color: var(--cor-secundaria);
        font-weight: 600;
    }

    .caminho-separador {
        color: #94A3B8;
    }


    /* ========================================================
       CARTAO PRINCIPAL DA OBRA
       ======================================================== */

    .obra-cabecalho {
        position: relative;
        overflow: hidden;
        padding: 36px;
        background: var(--cor-cartao);
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-grande);
        box-shadow: var(--sombra-cartao);
    }

    .obra-cabecalho::before {
        content: "";
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 5px;
        background:
            linear-gradient(
                90deg,
                var(--cor-primaria),
                #4B94CC
            );
    }

    .obra-etiquetas {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 9px;
        margin-bottom: 17px;
    }

    .etiqueta {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 5px 11px;
        border-radius: 6px;
        background: #EAF2FA;
        color: var(--cor-primaria);
        font-size: 11px;
        font-weight: 800;
        letter-spacing: 0.45px;
        text-transform: uppercase;
    }

    .etiqueta-secundaria {
        background: #F1F5F9;
        color: #475569;
    }

    .obra-titulo {
        max-width: 950px;
        margin: 0;
        color: var(--cor-primaria-escuro);
        font-size: clamp(27px, 4vw, 39px);
        font-weight: 800;
        line-height: 1.25;
        letter-spacing: -1.05px;
        overflow-wrap: anywhere;
    }

    .obra-subtitulo {
        max-width: 850px;
        margin-top: 18px;
        margin-bottom: 0;
        color: var(--cor-texto-secundario);
        font-size: 16px;
        line-height: 1.8;
    }

    .obra-autor {
        display: flex;
        align-items: flex-start;
        gap: 12px;
        margin-top: 25px;
        padding-top: 22px;
        border-top: 1px solid var(--cor-borda);
    }

    .autor-icone {
        width: 42px;
        height: 42px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        border-radius: 50%;
        background: #EAF2FA;
        color: var(--cor-primaria);
        font-size: 17px;
        font-weight: 800;
    }

    .autor-informacao {
        min-width: 0;
    }

    .autor-legenda {
        display: block;
        margin-bottom: 2px;
        color: var(--cor-texto-secundario);
        font-size: 12px;
    }

    .autor-nome {
        display: block;
        color: var(--cor-primaria-escuro);
        font-size: 15px;
        font-weight: 700;
        overflow-wrap: anywhere;
    }


    /* ========================================================
       METADADOS
       ======================================================== */

    .metadados {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 14px;
        margin-top: 20px;
    }

    .metadado {
        min-width: 0;
        padding: 19px 18px;
        background: var(--cor-cartao);
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-medio);
        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease;
    }

    .metadado:hover {
        transform: translateY(-2px);
        box-shadow: var(--sombra-cartao);
    }

    .metadado-rotulo {
        display: block;
        margin-bottom: 6px;
        color: var(--cor-texto-secundario);
        font-size: 12px;
        font-weight: 500;
    }

    .metadado-valor {
        display: block;
        color: var(--cor-primaria-escuro);
        font-size: 15px;
        font-weight: 750;
        overflow-wrap: anywhere;
    }


    /* ========================================================
       SECCOES DE CONTEUDO
       ======================================================== */

    .secao {
        margin-top: 24px;
        padding: 30px;
        background: var(--cor-cartao);
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-grande);
        box-shadow: var(--sombra-cartao);
    }

    .secao-cabecalho {
        display: flex;
        align-items: flex-start;
        gap: 13px;
        margin-bottom: 20px;
    }

    .secao-icone {
        width: 42px;
        height: 42px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        border-radius: 11px;
        background: #EAF2FA;
        color: var(--cor-primaria);
        font-size: 18px;
        font-weight: 800;
    }

    .secao-titulos {
        min-width: 0;
    }

    .secao-titulo {
        margin: 0;
        color: var(--cor-primaria-escuro);
        font-size: 22px;
        font-weight: 800;
        line-height: 1.4;
        letter-spacing: -0.4px;
    }

    .secao-descricao {
        margin: 5px 0 0;
        color: var(--cor-texto-secundario);
        font-size: 13px;
        line-height: 1.6;
    }

    .texto-obra {
        color: var(--cor-texto);
        font-size: 16px;
        line-height: 1.95;
        text-align: justify;
        overflow-wrap: anywhere;
        hyphens: auto;
    }

    .texto-obra p {
        margin-top: 0;
        margin-bottom: 17px;
    }

    .texto-obra p:last-child {
        margin-bottom: 0;
    }

    .texto-obra h2,
    .texto-obra h3,
    .texto-obra h4 {
        margin-top: 27px;
        margin-bottom: 12px;
        color: var(--cor-primaria-escuro);
        line-height: 1.45;
        text-align: left;
    }

    .texto-obra ul,
    .texto-obra ol {
        padding-left: 25px;
    }

    .texto-obra li {
        margin-bottom: 7px;
    }


    /* ========================================================
       BOTOES DE ACCAO
       ======================================================== */

    .acoes-obra {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        margin-top: 26px;
    }

    .botao {
        min-height: 46px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 9px;
        padding: 11px 19px;
        border: 1px solid transparent;
        border-radius: 9px;
        font-size: 13px;
        font-weight: 750;
        line-height: 1.4;
        text-align: center;
        cursor: pointer;
        transition:
            background 0.2s ease,
            border-color 0.2s ease,
            transform 0.2s ease;
    }

    .botao:hover {
        transform: translateY(-1px);
    }

    .botao-primario {
        background: var(--cor-primaria);
        color: #FFFFFF;
        box-shadow:
            0 4px 12px rgba(23, 74, 126, 0.15);
    }

    .botao-primario:hover {
        background: var(--cor-primaria-escuro);
        color: #FFFFFF;
    }

    .botao-secundario {
        background: #FFFFFF;
        border-color: var(--cor-borda);
        color: var(--cor-primaria);
    }

    .botao-secundario:hover {
        background: #F1F6FB;
        border-color: #B9CCDE;
    }

    .botao-sucesso {
        background: #EAF7EF;
        border-color: #C9E8D4;
        color: var(--cor-sucesso);
    }

    .botao-sucesso:hover {
        background: #DDF2E5;
    }


    /* ========================================================
       PARTILHA
       ======================================================== */

    .partilha {
        margin-top: 24px;
        padding-top: 22px;
        border-top: 1px solid var(--cor-borda);
    }

    .partilha-titulo {
        margin: 0 0 12px;
        color: var(--cor-primaria-escuro);
        font-size: 14px;
        font-weight: 800;
    }

    .partilha-botoes {
        display: flex;
        flex-wrap: wrap;
        gap: 9px;
    }

    .botao-partilha {
        min-height: 39px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        padding: 8px 12px;
        border: 1px solid var(--cor-borda);
        border-radius: 8px;
        background: #FFFFFF;
        color: var(--cor-texto);
        font-size: 12px;
        font-weight: 700;
        cursor: pointer;
        transition:
            background 0.2s ease,
            border-color 0.2s ease;
    }

    .botao-partilha:hover {
        background: #F1F6FB;
        border-color: #B9CCDE;
    }

    .mensagem-partilha {
        min-height: 22px;
        margin-top: 10px;
        color: var(--cor-sucesso);
        font-size: 12px;
        font-weight: 600;
    }


    /* ========================================================
       IMAGENS
       ======================================================== */

    .galeria-imagens {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 18px;
    }

    .imagem-obra {
        margin: 0;
        overflow: hidden;
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-medio);
        background: #FFFFFF;
    }

    .imagem-obra img {
        display: block;
        width: 100%;
        max-height: 440px;
        object-fit: contain;
        background: #F8FAFC;
    }

    .imagem-legenda {
        padding: 12px 14px;
        color: var(--cor-texto-secundario);
        font-size: 12px;
        line-height: 1.6;
    }


    /* ========================================================
       OBRAS RELACIONADAS
       ======================================================== */

    .obras-relacionadas {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 15px;
    }

    .obra-relacionada {
        min-width: 0;
        display: flex;
        flex-direction: column;
        padding: 20px;
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-medio);
        background: #FFFFFF;
        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease,
            border-color 0.2s ease;
    }

    .obra-relacionada:hover {
        transform: translateY(-3px);
        border-color: #B9CCDE;
        box-shadow: var(--sombra-cartao);
    }

    .obra-relacionada-categoria {
        margin-bottom: 9px;
        color: var(--cor-secundaria);
        font-size: 10px;
        font-weight: 800;
        letter-spacing: 0.6px;
        text-transform: uppercase;
    }

    .obra-relacionada-titulo {
        margin: 0;
        color: var(--cor-primaria-escuro);
        font-size: 16px;
        font-weight: 800;
        line-height: 1.5;
        overflow-wrap: anywhere;
    }

    .obra-relacionada-autor {
        margin-top: 9px;
        color: var(--cor-texto-secundario);
        font-size: 12px;
    }

    .obra-relacionada-link {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        margin-top: auto;
        padding-top: 15px;
        color: var(--cor-secundaria);
        font-size: 12px;
        font-weight: 800;
    }


    /* ========================================================
       RODAPE
       ======================================================== */

    .rodape {
        margin-top: auto;
        background: #102D49;
        color: #D8E4EF;
    }

    .rodape-interior {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 24px;
        padding-top: 28px;
        padding-bottom: 28px;
    }

    .rodape-marca {
        color: #FFFFFF;
        font-size: 15px;
        font-weight: 800;
    }

    .rodape-descricao {
        margin-top: 5px;
        color: #C2D1DF;
        font-size: 12px;
        line-height: 1.7;
    }

    .rodape-direitos {
        color: #C2D1DF;
        font-size: 11px;
        text-align: right;
    }

    .rodape a {
        color: #FFFFFF;
    }


    /* ========================================================
       ESTADOS VAZIOS E AVISOS
       ======================================================== */

    .aviso {
        padding: 18px;
        border: 1px solid var(--cor-borda);
        border-radius: var(--raio-medio);
        background: #F8FAFC;
        color: var(--cor-texto-secundario);
        font-size: 14px;
        line-height: 1.7;
    }

    .aviso-sucesso {
        border-color: #C9E8D4;
        background: #F0FAF3;
        color: #166534;
    }


    /* ========================================================
       RESPONSIVIDADE: TABLETS
       ======================================================== */

    @media (max-width: 900px) {
        .metadados {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .obra-cabecalho {
            padding: 28px;
        }

        .secao {
            padding: 25px;
        }

        .obras-relacionadas {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }
    }


    /* ========================================================
       RESPONSIVIDADE: TELEMOVEIS
       ======================================================== */

    @media (max-width: 600px) {
        body {
            font-size: 15px;
            line-height: 1.7;
        }

        .contentor {
            width: calc(100% - 28px);
        }

        .cabecalho-interior {
            min-height: 67px;
            gap: 12px;
        }

        .marca {
            gap: 9px;
        }

        .marca-simbolo {
            width: 38px;
            height: 38px;
            border-radius: 10px;
            font-size: 18px;
        }

        .marca-nome {
            font-size: 17px;
        }

        .marca-descricao {
            font-size: 9px;
        }

        .cabecalho-link {
            padding: 8px 10px;
            font-size: 11px;
        }

        .conteudo-principal {
            padding-top: 22px;
            padding-bottom: 35px;
        }

        .caminho-navegacao {
            margin-bottom: 17px;
            font-size: 11px;
        }

        .obra-cabecalho {
            padding: 24px 20px;
            border-radius: 15px;
        }

        .obra-titulo {
            font-size: 27px;
            line-height: 1.3;
            letter-spacing: -0.6px;
        }

        .obra-subtitulo {
            margin-top: 14px;
            font-size: 14px;
        }

        .obra-autor {
            margin-top: 20px;
            padding-top: 18px;
        }

        .metadados {
            gap: 10px;
            margin-top: 14px;
        }

        .metadado {
            padding: 15px 13px;
            border-radius: 11px;
        }

        .metadado-rotulo {
            font-size: 11px;
        }

        .metadado-valor {
            font-size: 13px;
        }

        .secao {
            margin-top: 16px;
            padding: 21px 18px;
            border-radius: 15px;
        }

        .secao-cabecalho {
            gap: 10px;
            margin-bottom: 15px;
        }

        .secao-icone {
            width: 37px;
            height: 37px;
            border-radius: 9px;
            font-size: 16px;
        }

        .secao-titulo {
            font-size: 19px;
        }

        .secao-descricao {
            font-size: 12px;
        }

        .texto-obra {
            font-size: 15px;
            line-height: 1.9;
        }

        .acoes-obra {
            flex-direction: column;
            gap: 10px;
        }

        .acoes-obra .botao {
            width: 100%;
        }

        .partilha-botoes {
            gap: 8px;
        }

        .botao-partilha {
            flex: 1 1 calc(50% - 8px);
        }

        .galeria-imagens {
            grid-template-columns: 1fr;
            gap: 14px;
        }

        .obras-relacionadas {
            grid-template-columns: 1fr;
        }

        .obra-relacionada {
            padding: 17px;
        }

        .rodape-interior {
            flex-direction: column;
            align-items: flex-start;
            gap: 14px;
            padding-top: 24px;
            padding-bottom: 24px;
        }

        .rodape-direitos {
            text-align: left;
        }
    }


    /* ========================================================
       ACESSIBILIDADE E IMPRESSAO
       ======================================================== */

    @media (prefers-reduced-motion: reduce) {
        *,
        *::before,
        *::after {
            scroll-behavior: auto !important;
            transition-duration: 0.01ms !important;
            animation-duration: 0.01ms !important;
        }
    }

    @media print {
        body {
            background: #FFFFFF;
            color: #000000;
        }

        .cabecalho,
        .rodape,
        .partilha,
        .acoes-obra {
            display: none !important;
        }

        .obra-cabecalho,
        .secao,
        .metadado {
            box-shadow: none;
            break-inside: avoid;
        }

        .contentor {
            width: 100%;
        }

        .texto-obra {
            color: #000000;
        }
    }
    """


# ============================================================
# FIM DA PARTE 1
#
# A PARTE 2 CONTINUARA COM AS FUNCOES DE PROCESSAMENTO
# DOS DADOS E CONSTRUCAO DO HTML DE CADA OBRA.
# ============================================================
# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 2 DE 3
#
# Processamento dos dados e construcao do HTML das obras.
# ============================================================


# ============================================================
# FUNCOES AUXILIARES
# ============================================================

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


# ============================================================
# IMAGENS DA OBRA
# ============================================================

def gerar_html_imagens(imagens):
    """
    Gera uma galeria de imagens, quando existirem imagens.
    """
    if not imagens:
        return ""

    elementos = []

    for imagem in imagens:
        url_imagem = texto_seguro(
            imagem.get("url_imagem")
        )

        if not url_imagem:
            continue

        try:
            partes = urllib.parse.urlsplit(url_imagem)

            if partes.scheme not in ("http", "https"):
                continue

            if not partes.netloc:
                continue
        except (ValueError, TypeError):
            continue

        legenda = texto_seguro(
            imagem.get("legenda")
        )

        fonte = texto_seguro(
            imagem.get("fonte")
        )

        legenda_completa = legenda

        if fonte:
            if legenda_completa:
                legenda_completa += f" — Fonte: {fonte}"
            else:
                legenda_completa = f"Fonte: {fonte}"

        legenda_html = ""

        if legenda_completa:
            legenda_html = (
                '<figcaption class="imagem-legenda">'
                f"{escapar_html(legenda_completa)}"
                "</figcaption>"
            )

        elementos.append(
            f"""
            <figure class="imagem-obra">
                <img
                    src="{escapar_html(url_imagem)}"
                    alt="{escapar_html(legenda or 'Imagem da obra académica')}"
                    loading="lazy"
                    decoding="async"
                >
                {legenda_html}
            </figure>
            """
        )

    if not elementos:
        return ""

    return f"""
    <section class="secao" aria-labelledby="titulo-imagens">
        <div class="secao-cabecalho">
            <div class="secao-icone" aria-hidden="true">▧</div>

            <div class="secao-titulos">
                <h2 class="secao-titulo" id="titulo-imagens">
                    Imagens da obra
                </h2>

                <p class="secao-descricao">
                    Elementos visuais associados a este trabalho.
                </p>
            </div>
        </div>

        <div class="galeria-imagens">
            {''.join(elementos)}
        </div>
    </section>
    """


# ============================================================
# OBRAS RELACIONADAS
# ============================================================

def encontrar_obras_relacionadas(obra, todas_obras, limite=4):
    """
    Identifica obras relacionadas usando a categoria
    e palavras presentes no titulo.

    A funcao nao modifica os dados originais.
    """
    obra_id = texto_seguro(obra.get("id"))

    titulo_atual = slug_texto(
        obra.get("titulo")
    )

    categoria_atual = slug_texto(
        obra.get("categoria")
    )

    palavras_atuais = {
        palavra
        for palavra in titulo_atual.split("-")
        if len(palavra) >= 4
    }

    palavras_genericas = {
        "sobre",
        "para",
        "como",
        "uma",
        "este",
        "esta",
        "dos",
        "das",
        "com",
        "por",
        "entre",
        "estudo",
        "analise",
        "avaliacao",
        "trabalho",
    }

    palavras_atuais -= palavras_genericas

    candidatos = []

    for outra in todas_obras:
        outro_id = texto_seguro(outra.get("id"))

        if not outro_id or outro_id == obra_id:
            continue

        outro_titulo = slug_texto(
            outra.get("titulo")
        )

        outra_categoria = slug_texto(
            outra.get("categoria")
        )

        palavras_outras = {
            palavra
            for palavra in outro_titulo.split("-")
            if len(palavra) >= 4
        }

        palavras_outras -= palavras_genericas

        intersecao = palavras_atuais & palavras_outras

        pontuacao = len(intersecao)

        if (
            categoria_atual
            and outra_categoria
            and categoria_atual == outra_categoria
        ):
            pontuacao += 3

        if pontuacao > 0:
            candidatos.append(
                (pontuacao, outra)
            )

    candidatos.sort(
        key=lambda item: (
            -item[0],
            texto_seguro(item[1].get("titulo")).lower(),
        )
    )

    return [
        item[1]
        for item in candidatos[:limite]
    ]


def gerar_html_obras_relacionadas(obras_relacionadas):
    """
    Constrói os cartões das obras relacionadas.
    """
    if not obras_relacionadas:
        return ""

    cartoes = []

    for obra in obras_relacionadas:
        titulo = texto_seguro(
            obra.get("titulo"),
            "Obra académica",
        )

        autor = texto_seguro(
            obra.get("autor"),
            "Autor não informado",
        )

        categoria = texto_seguro(
            obra.get("categoria"),
            "Publicação académica",
        )

        endereco = url_obra(
            obra.get("id")
        )

        cartoes.append(
            f"""
            <article class="obra-relacionada">
                <div class="obra-relacionada-categoria">
                    {escapar_html(categoria)}
                </div>

                <h3 class="obra-relacionada-titulo">
                    {escapar_html(titulo)}
                </h3>

                <div class="obra-relacionada-autor">
                    Autor: {escapar_html(autor)}
                </div>

                <a
                    class="obra-relacionada-link"
                    href="{escapar_html(endereco)}"
                >
                    Consultar obra
                    <span aria-hidden="true">→</span>
                </a>
            </article>
            """
        )

    return f"""
    <section class="secao" aria-labelledby="titulo-relacionadas">
        <div class="secao-cabecalho">
            <div class="secao-icone" aria-hidden="true">⌕</div>

            <div class="secao-titulos">
                <h2 class="secao-titulo" id="titulo-relacionadas">
                    Obras relacionadas
                </h2>

                <p class="secao-descricao">
                    Explore outros trabalhos académicos
                    disponíveis no Obra Livre.
                </p>
            </div>
        </div>

        <div class="obras-relacionadas">
            {''.join(cartoes)}
        </div>
    </section>
    """


# ============================================================
# BOTOES DE PARTILHA
# ============================================================

def gerar_html_partilha(obra):
    """
    Gera os botoes para partilhar a obra.
    """
    titulo = texto_seguro(
        obra.get("titulo"),
        "Obra académica",
    )

    endereco = url_obra(
        obra.get("id")
    )

    titulo_js = json.dumps(
        titulo,
        ensure_ascii=False,
    )

    endereco_js = json.dumps(
        endereco,
        ensure_ascii=False,
    )

    return f"""
    <div class="partilha">
        <h3 class="partilha-titulo">
            Partilhar esta obra
        </h3>

        <div class="partilha-botoes">
            <a
                class="botao-partilha"
                href="https://wa.me/?text={urllib.parse.quote(titulo + ' ' + endereco)}"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Partilhar no WhatsApp"
            >
                WhatsApp
            </a>

            <a
                class="botao-partilha"
                href="https://www.facebook.com/sharer/sharer.php?u={urllib.parse.quote(endereco, safe='')}"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Partilhar no Facebook"
            >
                Facebook
            </a>

            <a
                class="botao-partilha"
                href="https://www.linkedin.com/sharing/share-offsite/?url={urllib.parse.quote(endereco, safe='')}"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Partilhar no LinkedIn"
            >
                LinkedIn
            </a>

            <a
                class="botao-partilha"
                href="https://t.me/share/url?url={urllib.parse.quote(endereco, safe='')}&text={urllib.parse.quote(titulo, safe='')}"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Partilhar no Telegram"
            >
                Telegram
            </a>

            <button
                class="botao-partilha"
                type="button"
                onclick="copiarLinkObra()"
            >
                Copiar link
            </button>
        </div>

        <div
            class="mensagem-partilha"
            id="mensagem-partilha"
            role="status"
            aria-live="polite"
        ></div>
    </div>

    <script>
    (function () {{
        const tituloObra = {titulo_js};
        const enderecoObra = {endereco_js};

        window.copiarLinkObra = async function () {{
            const mensagem = document.getElementById(
                "mensagem-partilha"
            );

            try {{
                if (
                    navigator.clipboard &&
                    window.isSecureContext
                ) {{
                    await navigator.clipboard.writeText(
                        enderecoObra
                    );
                }} else {{
                    const campo = document.createElement("textarea");

                    campo.value = enderecoObra;
                    campo.setAttribute("readonly", "");
                    campo.style.position = "fixed";
                    campo.style.opacity = "0";

                    document.body.appendChild(campo);

                    campo.select();

                    const copiado = document.execCommand("copy");

                    document.body.removeChild(campo);

                    if (!copiado) {{
                        throw new Error("Falha ao copiar");
                    }}
                }}

                mensagem.textContent = "Link copiado com sucesso!";
            }} catch (erro) {{
                mensagem.textContent =
                    "Não foi possível copiar automaticamente. "
                    + "Copie o endereço da barra do navegador.";
            }}
        }};
    }})();
    </script>
    """


# ============================================================
# CABECALHO E RODAPE
# ============================================================

def gerar_html_cabecalho():
    """
    Gera o cabecalho institucional.
    """
    return f"""
    <header class="cabecalho">
        <div class="contentor cabecalho-interior">
            <a
                class="marca"
                href="{BASE_URL}/"
                aria-label="Obra Livre — página inicial"
            >
                <span class="marca-simbolo" aria-hidden="true">
                    OL
                </span>

                <span class="marca-texto">
                    <span class="marca-nome">
                        Obra Livre
                    </span>

                    <span class="marca-descricao">
                        O conhecimento ao alcance de todos
                    </span>
                </span>
            </a>

            <a
                class="cabecalho-link"
                href="{BASE_URL}/"
            >
                Explorar obras
                <span aria-hidden="true">→</span>
            </a>
        </div>
    </header>
    """


def gerar_html_rodape():
    """
    Gera o rodape institucional.
    """
    ano_atual = datetime.now().year

    return f"""
    <footer class="rodape">
        <div class="contentor rodape-interior">
            <div>
                <div class="rodape-marca">
                    Obra Livre — Obras Académicas
                </div>

                <div class="rodape-descricao">
                    Uma plataforma de consulta e partilha
                    de conhecimento académico.
                </div>
            </div>

            <div class="rodape-direitos">
                © {ano_atual} Obra Livre.
                <br>
                Todos os direitos reservados.
            </div>
        </div>
    </footer>
    """


# ============================================================
# METADADOS VISUAIS DA OBRA
# ============================================================

def gerar_html_metadados(obra):
    """
    Mostra os dados bibliograficos disponiveis.
    """
    categoria = texto_seguro(
        obra.get("categoria"),
        "Não especificada",
    )

    ano = texto_seguro(
        obra.get("ano_obra")
    )

    if not ano:
        ano = "Não informado"

    paginas = texto_seguro(
        obra.get("numero_paginas")
    )

    if paginas.isdigit():
        paginas = f"{paginas} páginas"
    else:
        paginas = "Não informado"

    tamanho = obra.get(
        "tamanho_arquivo_bytes"
    )

    try:
        tamanho = int(tamanho or 0)
    except (TypeError, ValueError):
        tamanho = 0

    if tamanho > 0:
        tamanho_mb = tamanho / (1024 * 1024)

        if tamanho_mb < 1:
            tamanho_kb = tamanho / 1024

            tamanho_texto = f"{tamanho_kb:.0f} KB"
        else:
            tamanho_texto = f"{tamanho_mb:.2f} MB"
    else:
        tamanho_texto = "Não informado"

    itens = [
        ("Categoria", categoria),
        ("Ano de publicação", ano),
        ("Extensão", paginas),
        ("Tamanho do ficheiro", tamanho_texto),
    ]

    elementos = []

    for rotulo, valor in itens:
        elementos.append(
            f"""
            <div class="metadado">
                <span class="metadado-rotulo">
                    {escapar_html(rotulo)}
                </span>

                <span class="metadado-valor">
                    {escapar_html(valor)}
                </span>
            </div>
            """
        )

    return f"""
    <section
        class="metadados"
        aria-label="Informações bibliográficas"
    >
        {''.join(elementos)}
    </section>
    """


# ============================================================
# PAGINA HTML DE UMA OBRA
# ============================================================

def gerar_pagina_obra(obra, todas_obras=None, imagens=None):
    """
    Gera uma pagina HTML completa para uma obra.

    O HTML inclui:
    - Metadados SEO;
    - Dados estruturados;
    - Cabecalho institucional;
    - Titulo e autor;
    - Informacoes bibliograficas;
    - Descricao representativa;
    - Ligacao ao documento;
    - Partilha;
    - Obras relacionadas;
    - Rodape responsivo.
    """

    todas_obras = todas_obras or []

    imagens = imagens or []

    obra_id = texto_seguro(
        obra.get("id")
    )

    if not obra_id:
        raise ValueError(
            "Não é possível gerar uma página sem o ID da obra."
        )

    titulo = texto_seguro(
        obra.get("titulo"),
        "Obra académica",
    )

    autor = obter_autor(obra)

    categoria = texto_seguro(
        obra.get("categoria"),
        "Publicação académica",
    )

    titulo_seo = gerar_titulo_seo(obra)

    descricao_seo = gerar_descricao_seo(obra)

    endereco = url_obra(obra_id)

    documento = obter_url_documento(obra)

    texto_principal = obter_texto_principal(obra)

    ano = texto_seguro(
        obra.get("ano_obra")
    )

    if not ano:
        ano = "Ano não informado"

    # --------------------------------------------------------
    # METADADOS HTML
    # --------------------------------------------------------

    titulo_html = escapar_html(titulo_seo)

    descricao_html = escapar_html(descricao_seo)

    endereco_html = escapar_html(endereco)

    favicon_html = escapar_html(FAVICON_URL)

    metadados_social = gerar_metadados_social(obra)

    dados_estruturados = gerar_json_ld(obra)

    # --------------------------------------------------------
    # BOTAO PARA ABRIR O DOCUMENTO
    # --------------------------------------------------------

    if documento:
        botao_documento = f"""
        <a
            class="botao botao-primario"
            href="{escapar_html(documento)}"
            target="_blank"
            rel="noopener noreferrer"
        >
            <span aria-hidden="true">↗</span>
            Consultar documento
        </a>
        """
    else:
        botao_documento = """
        <span class="botao botao-secundario">
            Documento não disponível
        </span>
        """

    # --------------------------------------------------------
    # DATA DE PUBLICACAO
    # --------------------------------------------------------

    data_publicacao = obter_data_iso(
        obra.get("data_publicacao")
        or obra.get("created_at")
    )

    if data_publicacao:
        try:
            data_legivel = datetime.fromisoformat(
                data_publicacao.replace("Z", "+00:00")
            ).strftime("%d/%m/%Y")
        except ValueError:
            data_legivel = ""
    else:
        data_legivel = ""

    if data_legivel:
        data_html = f"""
        <div class="metadado">
            <span class="metadado-rotulo">
                Data de publicação
            </span>

            <span class="metadado-valor">
                {escapar_html(data_legivel)}
            </span>
        </div>
        """
    else:
        data_html = ""

    # --------------------------------------------------------
    # DESCRICAO DA OBRA
    # --------------------------------------------------------

    descricao_html_conteudo = escapar_html(
        texto_principal
    )

    descricao_html_conteudo = (
        descricao_html_conteudo
        .replace("\n", "<br>")
    )

    # --------------------------------------------------------
    # IMAGENS
    # --------------------------------------------------------

    html_imagens = gerar_html_imagens(
        imagens
    )

    # --------------------------------------------------------
    # OBRAS RELACIONADAS
    # --------------------------------------------------------

    relacionadas = encontrar_obras_relacionadas(
        obra,
        todas_obras,
        limite=4,
    )

    html_relacionadas = gerar_html_obras_relacionadas(
        relacionadas
    )

    # --------------------------------------------------------
    # PARTILHA
    # --------------------------------------------------------

    html_partilha = gerar_html_partilha(
        obra
    )

    # --------------------------------------------------------
    # PAGINA COMPLETA
    # --------------------------------------------------------

    return f"""<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1"
    >

    <title>{titulo_html}</title>

    <meta
        name="description"
        content="{descricao_html}"
    >

    <meta name="robots" content="index, follow, max-image-preview:large">

    <meta name="author" content="{escapar_html(autor)}">

    <meta name="theme-color" content="#174A7E">

    <link rel="canonical" href="{endereco_html}">

    <link rel="icon" href="{favicon_html}">

    {metadados_social}

    <script type="application/ld+json">{dados_estruturados}</script>

    <style>
        {gerar_css()}
    </style>
</head>

<body>
    <div class="pagina">

        {gerar_html_cabecalho()}

        <main class="conteudo-principal">
            <div class="contentor">

                <nav
                    class="caminho-navegacao"
                    aria-label="Navegação"
                >
                    <a href="{BASE_URL}/">
                        Início
                    </a>

                    <span
                        class="caminho-separador"
                        aria-hidden="true"
                    >
                        /
                    </span>

                    <span>
                        {escapar_html(categoria)}
                    </span>
                </nav>

                <article>
                    <header class="obra-cabecalho">

                        <div class="obra-etiquetas">
                            <span class="etiqueta">
                                Obra académica
                            </span>

                            <span class="etiqueta etiqueta-secundaria">
                                {escapar_html(categoria)}
                            </span>
                        </div>

                        <h1 class="obra-titulo">
                            {escapar_html(titulo)}
                        </h1>

                        <p class="obra-subtitulo">
                            Consulte as informações desta publicação
                            académica e aceda ao documento original,
                            quando disponível.
                        </p>

                        <div class="obra-autor">
                            <div
                                class="autor-icone"
                                aria-hidden="true"
                            >
                                {escapar_html(
                                    autor[:1].upper()
                                    if autor and autor != "Autor não informado"
                                    else "A"
                                )}
                            </div>

                            <div class="autor-informacao">
                                <span class="autor-legenda">
                                    Autor da publicação
                                </span>

                                <span class="autor-nome">
                                    {escapar_html(autor)}
                                </span>
                            </div>
                        </div>

                        <div class="acoes-obra">
                            {botao_documento}

                            <button
                                class="botao botao-secundario"
                                type="button"
                                onclick="window.print()"
                            >
                                Imprimir página
                            </button>
                        </div>

                        {html_partilha}

                    </header>

                    {gerar_html_metadados(obra)}

                    <section
                        class="secao"
                        aria-labelledby="titulo-descricao"
                    >
                        <div class="secao-cabecalho">
                            <div
                                class="secao-icone"
                                aria-hidden="true"
                            >
                                ≡
                            </div>

                            <div class="secao-titulos">
                                <h2
                                    class="secao-titulo"
                                    id="titulo-descricao"
                                >
                                    Sobre esta obra
                                </h2>

                                <p class="secao-descricao">
                                    Apresentação e informações
                                    gerais da publicação.
                                </p>
                            </div>
                        </div>

                        <div class="texto-obra">
                            <p>{descricao_html_conteudo}</p>
                        </div>
                    </section>

                    {html_imagens}

                    {html_relacionadas}

                </article>

            </div>
        </main>

        {gerar_html_rodape()}

    </div>
</body>
</html>
"""
# ============================================================
# OBRA LIVRE
# GERADOR DE PAGINAS SEO
# PARTE 3 DE 3
#
# Supabase, geracao das paginas, sitemap, robots.txt
# e validacao final.
# ============================================================


# ============================================================
# CONFIGURACAO DO SUPABASE
# ============================================================

SUPABASE_URL = os.environ.get(
    "SUPABASE_URL",
    "",
).strip().rstrip("/")

SUPABASE_ANON_KEY = (
    os.environ.get("SUPABASE_ANON_KEY", "").strip()
    or os.environ.get("SUPABASE_PUBLISHABLE_KEY", "").strip()
)


def descobrir_configuracao_supabase():
    """
    Procura a configuracao do Supabase nas variaveis
    de ambiente e nos ficheiros Dart do projeto.

    Suporta configuracoes que utilizam:
    - url
    - publishableKey
    - anonKey
    - anon_key
    """

    global SUPABASE_URL
    global SUPABASE_ANON_KEY

    if SUPABASE_URL and SUPABASE_ANON_KEY:
        return True

    # --------------------------------------------------------
    # Procurar nos ficheiros Dart
    # --------------------------------------------------------

    ficheiros_dart = []

    pastas = [
        BASE_DIR / "lib",
        BASE_DIR / "lib" / "config",
        BASE_DIR / "lib" / "core",
    ]

    for pasta in pastas:
        if not pasta.exists():
            continue

        try:
            ficheiros_dart.extend(
                pasta.rglob("*.dart")
            )
        except OSError:
            continue

    # Remover ficheiros duplicados
    ficheiros_dart = list(
        dict.fromkeys(ficheiros_dart)
    )

    padrao_url = re.compile(
        r"""https://[a-zA-Z0-9-]+\.supabase\.co"""
    )

    for ficheiro in ficheiros_dart:
        try:
            conteudo = ficheiro.read_text(
                encoding="utf-8",
                errors="ignore",
            )
        except OSError:
            continue

        if not SUPABASE_URL:
            correspondencia_url = padrao_url.search(
                conteudo
            )

            if correspondencia_url:
                SUPABASE_URL = (
                    correspondencia_url.group(0).rstrip("/")
                )

        if not SUPABASE_ANON_KEY:
            # Suporta chaves publicaveis modernas.
            correspondencia_publishable = re.search(
                r"""(?:publishableKey|publishable_key|SUPABASE_PUBLISHABLE_KEY)"""
                r"""\s*[:=]\s*['"]([^'"]+)['"]""",
                conteudo,
                re.IGNORECASE,
            )

            if correspondencia_publishable:
                SUPABASE_ANON_KEY = (
                    correspondencia_publishable.group(1).strip()
                )

            # Suporta chaves anon antigas em formato JWT.
            if not SUPABASE_ANON_KEY:
                correspondencia_anon = re.search(
                    r"""(?:anonKey|anon_key|SUPABASE_ANON_KEY)"""
                    r"""\s*[:=]\s*['"]([^'"]+)['"]""",
                    conteudo,
                    re.IGNORECASE,
                )

                if correspondencia_anon:
                    SUPABASE_ANON_KEY = (
                        correspondencia_anon.group(1).strip()
                    )

        if SUPABASE_URL and SUPABASE_ANON_KEY:
            break

    return bool(
        SUPABASE_URL and SUPABASE_ANON_KEY
    )


# ============================================================
# CONSULTA HTTP AO SUPABASE
# ============================================================

def consultar_supabase(
    tabela,
    parametros=None,
    limite=1000,
):
    """
    Consulta uma tabela atraves da API REST do Supabase.

    Utiliza a chave publica configurada no projeto.
    """

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Configuracao do Supabase nao encontrada."
        )

    parametros = dict(parametros or {})

    parametros.setdefault("select", "*")

    parametros.setdefault(
        "limit",
        str(limite),
    )

    query_string = urllib.parse.urlencode(
        parametros,
        doseq=True,
    )

    endereco = (
        f"{SUPABASE_URL}/rest/v1/"
        f"{urllib.parse.quote(tabela, safe='')}"
        f"?{query_string}"
    )

    pedido = urllib.request.Request(
        endereco,
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": (
                f"Bearer {SUPABASE_ANON_KEY}"
            ),
            "Accept": "application/json",
            "User-Agent": "ObraLivre-SEO-Generator/1.0",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(
            pedido,
            timeout=45,
        ) as resposta:
            conteudo = resposta.read().decode(
                "utf-8"
            )

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
            f"Erro HTTP {erro.code} ao consultar "
            f"a tabela '{tabela}': {detalhe}"
        ) from erro

    except urllib.error.URLError as erro:
        raise RuntimeError(
            f"Falha de ligacao ao Supabase: {erro}"
        ) from erro


# ============================================================
# CONSULTAR OBRAS
# ============================================================

def obter_obras():
    """
    Consulta as obras publicadas.

    Ordena os resultados por titulo e utiliza paginacao
    para evitar depender de uma unica resposta.
    """

    print("A consultar obras no Supabase...")

    todas = []

    limite_pagina = 500

    inicio = 0

    while True:
        fim = inicio + limite_pagina - 1

        parametros = {
            "select": "*",
            "order": "titulo.asc",
            "limit": str(limite_pagina),
            "offset": str(inicio),
        }

        pagina = consultar_supabase(
            SUPABASE_TABLE_OBRAS,
            parametros=parametros,
            limite=limite_pagina,
        )

        if not pagina:
            break

        todas.extend(pagina)

        if len(pagina) < limite_pagina:
            break

        inicio += limite_pagina

    # Ignorar registos sem identificador ou titulo.
    obras_validas = []

    ids_encontrados = set()

    for obra in todas:
        obra_id = texto_seguro(
            obra.get("id")
        )

        titulo = texto_seguro(
            obra.get("titulo")
        )

        if not obra_id or not titulo:
            continue

        if obra_id in ids_encontrados:
            continue

        ids_encontrados.add(obra_id)

        obras_validas.append(obra)

    print(
        f"Foram encontradas {len(obras_validas)} "
        "obras com identificador e titulo."
    )

    return obras_validas


# ============================================================
# CONSULTAR SECCOES
# ============================================================

def obter_secoes():
    """
    Consulta as secoes associadas as obras.

    As secoes sao carregadas para permitir futuras
    extensoes, mas nao sao reproduzidas integralmente
    nas paginas SEO.
    """

    print("A consultar secoes das obras...")

    try:
        secoes = consultar_supabase(
            SUPABASE_TABLE_SECOES,
            parametros={
                "select": (
                    "id,obra_id,titulo,conteudo,"
                    "ordem,nivel,paragrafo_ordem"
                ),
                "order": "ordem.asc",
                "limit": "5000",
            },
            limite=5000,
        )

        print(
            f"Foram encontradas {len(secoes)} secoes."
        )

        return secoes

    except Exception as erro:
        print(
            "Aviso: nao foi possivel consultar as secoes: "
            f"{erro}"
        )

        return []


# ============================================================
# CONSULTAR IMAGENS
# ============================================================

def obter_imagens():
    """
    Consulta as imagens associadas as obras.
    """

    print("A consultar imagens das obras...")

    try:
        imagens = consultar_supabase(
            SUPABASE_TABLE_IMAGENS,
            parametros={
                "select": (
                    "id,obra_id,url_imagem,legenda,"
                    "posicao,ordem,fonte,paragrafo_ordem"
                ),
                "order": "ordem.asc",
                "limit": "5000",
            },
            limite=5000,
        )

        print(
            f"Foram encontradas {len(imagens)} imagens."
        )

        return imagens

    except Exception as erro:
        print(
            "Aviso: nao foi possivel consultar imagens: "
            f"{erro}"
        )

        return []


# ============================================================
# ORGANIZAR IMAGENS POR OBRA
# ============================================================

def organizar_imagens_por_obra(imagens):
    """
    Agrupa as imagens pelo identificador da obra.
    """

    resultado = {}

    for imagem in imagens:
        obra_id = texto_seguro(
            imagem.get("obra_id")
        )

        if not obra_id:
            continue

        resultado.setdefault(
            obra_id,
            [],
        ).append(imagem)

    for obra_id in resultado:
        resultado[obra_id].sort(
            key=lambda imagem: (
                imagem.get("paragrafo_ordem")
                if isinstance(
                    imagem.get("paragrafo_ordem"),
                    (int, float),
                )
                else 999999,
                imagem.get("ordem")
                if isinstance(
                    imagem.get("ordem"),
                    (int, float),
                )
                else 999999,
            )
        )

    return resultado


# ============================================================
# DATA DE MODIFICACAO
# ============================================================

def obter_data_modificacao(obra):
    """
    Obtem a data de modificacao da obra.
    """

    valor = (
        obra.get("updated_at")
        or obra.get("data_publicacao")
        or obra.get("created_at")
    )

    return obter_data_iso(valor)


# ============================================================
# PAGINAS PRINCIPAIS
# ============================================================

def obter_paginas_principais():
    """
    Devolve os enderecos principais do website.
    """

    return [
        {
            "url": f"{BASE_URL}/",
            "changefreq": "daily",
            "priority": "1.0",
        },
    ]


# ============================================================
# GERAR SITEMAP XML
# ============================================================

def gerar_sitemap(obras):
    """
    Gera sitemap.xml com as paginas publicas.

    O sitemap contem URLs absolutas e evita duplicacoes.
    """

    print("A gerar sitemap.xml...")

    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"

    ET.register_namespace(
        "",
        namespace,
    )

    raiz = ET.Element(
        f"{{{namespace}}}urlset"
    )

    urls_adicionadas = set()

    def adicionar_url(
        endereco,
        ultima_modificacao=None,
        frequencia="weekly",
        prioridade="0.8",
    ):
        if endereco in urls_adicionadas:
            return

        urls_adicionadas.add(endereco)

        elemento_url = ET.SubElement(
            raiz,
            f"{{{namespace}}}url",
        )

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}loc",
        ).text = endereco

        if ultima_modificacao:
            ET.SubElement(
                elemento_url,
                f"{{{namespace}}}lastmod",
            ).text = ultima_modificacao

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}changefreq",
        ).text = frequencia

        ET.SubElement(
            elemento_url,
            f"{{{namespace}}}priority",
        ).text = prioridade

    # Pagina inicial
    for pagina in obter_paginas_principais():
        adicionar_url(
            pagina["url"],
            frequencia=pagina.get(
                "changefreq",
                "weekly",
            ),
            prioridade=pagina.get(
                "priority",
                "0.8",
            ),
        )

    # Paginas individuais
    for obra in obras:
        obra_id = texto_seguro(
            obra.get("id")
        )

        if not obra_id:
            continue

        adicionar_url(
            url_obra(obra_id),
            ultima_modificacao=obter_data_modificacao(
                obra
            ),
            frequencia="monthly",
            prioridade="0.8",
        )

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho_sitemap = OUTPUT_DIR / "sitemap.xml"

    arvore = ET.ElementTree(raiz)

    try:
        ET.indent(
            arvore,
            space="  ",
        )
    except AttributeError:
        pass

    arvore.write(
        caminho_sitemap,
        encoding="utf-8",
        xml_declaration=True,
    )

    print(
        f"Sitemap criado: {caminho_sitemap}"
    )

    print(
        f"URLs no sitemap: {len(urls_adicionadas)}"
    )


# ============================================================
# GERAR ROBOTS.TXT
# ============================================================

def gerar_robots():
    """
    Gera robots.txt para o website publicado.
    """

    print("A gerar robots.txt...")

    conteudo = f"""User-agent: *
Allow: /

Sitemap: {BASE_URL}/sitemap.xml
"""

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho = OUTPUT_DIR / "robots.txt"

    caminho.write_text(
        conteudo,
        encoding="utf-8",
    )

    print(
        f"robots.txt criado: {caminho}"
    )


# ============================================================
# VALIDAR PAGINA HTML
# ============================================================

def validar_pagina_html(caminho):
    """
    Verifica elementos essenciais da pagina gerada.

    Esta verificacao e basica: nao substitui um validador
    completo de HTML.
    """

    try:
        conteudo = caminho.read_text(
            encoding="utf-8"
        )
    except OSError as erro:
        return False, str(erro)

    verificacoes = {
        "DOCTYPE": "<!DOCTYPE html>" in conteudo,
        "Titulo": "<title>" in conteudo,
        "Descricao SEO": 'name="description"' in conteudo,
        "URL canonico": 'rel="canonical"' in conteudo,
        "H1": "<h1" in conteudo,
        "Fecho HTML": "</html>" in conteudo,
    }

    falhas = [
        nome
        for nome, passou in verificacoes.items()
        if not passou
    ]

    if falhas:
        return (
            False,
            "Elementos em falta: " + ", ".join(falhas),
        )

    return True, "OK"


# ============================================================
# GERAR TODAS AS PAGINAS
# ============================================================

def gerar_todas_as_paginas():
    """
    Gera uma pagina HTML para cada obra.
    """

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    obras = obter_obras()

    if not obras:
        print(
            "Aviso: nao foram encontradas obras."
        )

        return []

    # Consultar os dados auxiliares
    obter_secoes()

    imagens = obter_imagens()

    imagens_por_obra = organizar_imagens_por_obra(
        imagens
    )

    total = len(obras)

    geradas = 0

    erros = 0

    print("")
    print("=" * 60)
    print("A GERAR PAGINAS SEO DO OBRA LIVRE")
    print("=" * 60)

    for indice, obra in enumerate(
        obras,
        start=1,
    ):
        obra_id = texto_seguro(
            obra.get("id")
        )

        titulo = texto_seguro(
            obra.get("titulo"),
            "Obra sem titulo",
        )

        print(
            f"[{indice}/{total}] {titulo}"
        )

        try:
            html_pagina = gerar_pagina_obra(
                obra,
                todas_obras=obras,
                imagens=imagens_por_obra.get(
                    obra_id,
                    [],
                ),
            )

            diretorio_obra = (
                OUTPUT_DIR
                / "obra"
                / obra_id
            )

            diretorio_obra.mkdir(
                parents=True,
                exist_ok=True,
            )

            caminho_html = (
                diretorio_obra
                / "index.html"
            )

            caminho_html.write_text(
                html_pagina,
                encoding="utf-8",
            )

            valido, mensagem = validar_pagina_html(
                caminho_html
            )

            if not valido:
                print(
                    f"  AVISO: {mensagem}"
                )
            else:
                print(
                    "  Pagina criada e validada."
                )

            geradas += 1

        except Exception as erro:
            erros += 1

            print(
                f"  ERRO ao gerar a pagina: {erro}"
            )

    print("")
    print("=" * 60)
    print("RESUMO DA GERACAO")
    print("=" * 60)

    print(f"Obras encontradas: {total}")
    print(f"Paginas geradas: {geradas}")
    print(f"Erros: {erros}")

    if geradas:
        gerar_sitemap(obras)

        gerar_robots()

    return obras


# ============================================================
# EXECUCAO PRINCIPAL
# ============================================================

def main():
    """
    Ponto de entrada do gerador SEO.
    """

    print("")
    print("=" * 60)
    print("OBRA LIVRE — GERADOR DE PAGINAS SEO")
    print("=" * 60)
    print("")

    if not descobrir_configuracao_supabase():
        print(
            "ERRO: configuracao do Supabase nao encontrada."
        )

        print(
            "Configure SUPABASE_URL e "
            "SUPABASE_ANON_KEY ou "
            "SUPABASE_PUBLISHABLE_KEY."
        )

        print(
            "O script tambem tenta localizar a configuracao "
            "nos ficheiros Dart do projeto."
        )

        return 1

    print("Configuracao do Supabase encontrada.")

    print(
        f"URL do projeto: {SUPABASE_URL}"
    )

    try:
        obras = gerar_todas_as_paginas()

        if not obras:
            print(
                "A geracao terminou sem obras para processar."
            )

            return 1

        print("")
        print("=" * 60)
        print("GERACAO CONCLUIDA")
        print("=" * 60)

        print(
            f"Paginas geradas em: {OUTPUT_DIR}"
        )

        print(
            "Execute o processo de build e publicacao "
            "do website para disponibilizar as paginas."
        )

        return 0

    except Exception as erro:
        print("")
        print("ERRO DURANTE A GERACAO:")
        print(str(erro))

        return 1


# ============================================================
# PONTO DE ENTRADA
# ============================================================

if __name__ == "__main__":
    sys.exit(main())
