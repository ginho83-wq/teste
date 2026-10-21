"""Orquestração da geração, sitemap.xml e robots.txt."""
import sys
import xml.etree.ElementTree as ET

from seo_config import BASE_URL, OUTPUT_DIR
from seo_utils import texto_seguro, url_obra, obter_data_iso
from seo_supabase import descobrir_configuracao_supabase, obter_obras, obter_secoes, obter_imagens
from seo_paginas import gerar_pagina_obra, validar_pagina_html

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

