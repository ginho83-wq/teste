"""Construção dos componentes HTML e estilos das páginas SEO."""
import json
import re
import urllib.parse
from datetime import datetime

from seo_config import (BASE_URL, SITE_NAME, COR_PRIMARIA, COR_PRIMARIA_ESCURO,
                        COR_SECUNDARIA, COR_FUNDO, COR_CARTAO, COR_TEXTO,
                        COR_TEXTO_SECUNDARIO, COR_BORDA, COR_SUCESSO)
from seo_utils import (texto_seguro, escapar_html, limpar_html, limitar_texto,
                       url_obra, obter_autor, obter_url_documento, slug_texto)

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
