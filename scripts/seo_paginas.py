"""Geração e validação de cada página SEO individual."""
from datetime import datetime

from seo_config import BASE_URL, FAVICON_URL
from seo_utils import (texto_seguro, escapar_html, obter_autor, gerar_titulo_seo,
                       gerar_descricao_seo, gerar_json_ld, gerar_metadados_social, url_obra,
                       obter_url_documento, obter_texto_principal, obter_data_iso)
from seo_html import (gerar_css, gerar_html_imagens,
                      encontrar_obras_relacionadas, gerar_html_obras_relacionadas,
                      gerar_html_partilha, gerar_html_cabecalho, gerar_html_rodape,
                      gerar_html_metadados)

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
