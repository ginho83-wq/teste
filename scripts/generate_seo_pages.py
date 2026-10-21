"""
OBRA LIVRE
Gerador principal das páginas SEO.

Utiliza:
- seo_config.py
- seo_utils.py
- seo_supabase.py
- seo_paginas.py
"""

import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

from seo_config import BASE_URL, OUTPUT_DIR

from seo_utils import (
    texto_seguro,
    url_obra,
    obter_data_iso,
)

from seo_supabase import (
    descobrir_configuracao_supabase,
    obter_obras,
    obter_secoes,
    obter_imagens,
)

from seo_paginas import (
    gerar_pagina_obra,
    validar_pagina_html,
)


# ============================================================
# CONFIGURACOES
# ============================================================

URL_SITE = BASE_URL.rstrip("/")
DIRETORIO_SAIDA = OUTPUT_DIR

NS_SITEMAP = "http://www.sitemaps.org/schemas/sitemap/0.9"

ET.register_namespace("", NS_SITEMAP)


# ============================================================
# ORGANIZACAO DAS IMAGENS
# ============================================================

def organizar_imagens_por_obra(imagens):
    """Organiza e ordena as imagens por obra."""

    imagens_por_obra = {}

    for imagem in imagens or []:
        obra_id = texto_seguro(imagem.get("obra_id"))

        if not obra_id:
            continue

        imagens_por_obra.setdefault(obra_id, []).append(imagem)

    def chave_ordenacao(imagem):

        def numero(valor, padrao=999999):
            try:
                return int(valor)
            except (TypeError, ValueError):
                return padrao

        return (
            numero(imagem.get("paragrafo_ordem")),
            numero(imagem.get("ordem")),
            texto_seguro(imagem.get("id")),
        )

    for obra_id in imagens_por_obra:
        imagens_por_obra[obra_id].sort(key=chave_ordenacao)

    return imagens_por_obra


# ============================================================
# DATAS
# ============================================================

def obter_data_modificacao(obra):
    """Obtém uma data válida de modificação da obra."""

    campos_data = (
        "updated_at",
        "data_atualizacao",
        "data_publicacao",
        "created_at",
    )

    for campo in campos_data:
        valor = texto_seguro(obra.get(campo))

        if not valor:
            continue

        data_iso = obter_data_iso(valor)

        if data_iso:
            return data_iso

    return None


# ============================================================
# PAGINAS PRINCIPAIS
# ============================================================

def obter_paginas_principais():
    """Devolve os endereços principais do site."""

    return [URL_SITE + "/"]


# ============================================================
# SITEMAP.XML
# ============================================================

def gerar_sitemap(obras):
    """Gera sitemap.xml para o site e para as obras."""

    DIRETORIO_SAIDA.mkdir(parents=True, exist_ok=True)

    urlset = ET.Element(
        f"{{{NS_SITEMAP}}}urlset"
    )

    enderecos = obter_paginas_principais()
    obras_por_url = {}

    for obra in obras or []:
        obra_id = texto_seguro(obra.get("id"))

        if not obra_id:
            continue

        endereco = url_obra(obra_id)

        if endereco:
            enderecos.append(endereco)
            obras_por_url[endereco] = obra

    enderecos_unicos = list(dict.fromkeys(enderecos))

    for endereco in enderecos_unicos:
        elemento_url = ET.SubElement(
            urlset,
            f"{{{NS_SITEMAP}}}url",
        )

        ET.SubElement(
            elemento_url,
            f"{{{NS_SITEMAP}}}loc",
        ).text = endereco

        data_modificacao = None

        if endereco.rstrip("/") == URL_SITE:
            data_modificacao = datetime.now(
                timezone.utc
            ).date().isoformat()
        else:
            obra = obras_por_url.get(endereco)

            if obra:
                data_modificacao = obter_data_modificacao(obra)

        if data_modificacao:
            data_limpa = obter_data_iso(data_modificacao)

            if data_limpa:
                try:
                    data = datetime.fromisoformat(
                        data_limpa.replace("Z", "+00:00")
                    )

                    ET.SubElement(
                        elemento_url,
                        f"{{{NS_SITEMAP}}}lastmod",
                    ).text = data.date().isoformat()

                except (ValueError, TypeError):
                    pass

    caminho_sitemap = DIRETORIO_SAIDA / "sitemap.xml"

    arvore = ET.ElementTree(urlset)

    try:
        ET.indent(arvore, space="  ")
    except AttributeError:
        pass

    arvore.write(
        caminho_sitemap,
        encoding="utf-8",
        xml_declaration=True,
    )

    print(f"Sitemap criado: {caminho_sitemap}")

    return caminho_sitemap


# ============================================================
# ROBOTS.TXT
# ============================================================

def gerar_robots():
    """Gera o ficheiro robots.txt."""

    DIRETORIO_SAIDA.mkdir(parents=True, exist_ok=True)

    caminho_robots = DIRETORIO_SAIDA / "robots.txt"

    conteudo = (
        "User-agent: *\n"
        "Allow: /\n"
        "\n"
        f"Sitemap: {URL_SITE}/sitemap.xml\n"
    )

    caminho_robots.write_text(
        conteudo,
        encoding="utf-8",
    )

    print(f"Robots criado: {caminho_robots}")

    return caminho_robots


# ============================================================
# VALIDACAO DAS OBRAS
# ============================================================

def obter_obras_validas(obras):
    """Remove obras sem identificador ou título e duplicados."""

    resultado = []
    ids_vistos = set()

    for obra in obras or []:
        obra_id = texto_seguro(obra.get("id"))
        titulo = texto_seguro(obra.get("titulo"))

        if not obra_id or not titulo:
            continue

        if obra_id in ids_vistos:
            continue

        ids_vistos.add(obra_id)
        resultado.append(obra)

    return resultado


# ============================================================
# GERACAO DE TODAS AS PAGINAS
# ============================================================

def gerar_todas_as_paginas():
    """Obtém os dados e gera as páginas SEO individuais."""

    DIRETORIO_SAIDA.mkdir(
        parents=True,
        exist_ok=True,
    )

    print("\nA obter obras do Supabase...")

    obras = obter_obras_validas(obter_obras())

    if not obras:
        print(
            "AVISO: não foram encontradas obras válidas. "
            "Verifica a ligação, as permissões e os dados "
            "da tabela obras."
        )
        return []

    print(f"Obras válidas encontradas: {len(obras)}")

    print("A consultar secções...")
    secoes = obter_secoes()

    print(
        f"Registos de secções consultados: "
        f"{len(secoes or [])}"
    )

    print("A consultar imagens...")
    imagens = obter_imagens()

    imagens_por_obra = organizar_imagens_por_obra(imagens)

    total_geradas = 0
    total_invalidas = 0
    total_erros = 0

    for indice, obra in enumerate(obras, start=1):
        obra_id = texto_seguro(obra.get("id"))

        titulo = texto_seguro(
            obra.get("titulo"),
            "Obra académica",
        )

        print(
            f"\n[{indice}/{len(obras)}] "
            f"A gerar: {titulo}"
        )

        try:
            pagina_html = gerar_pagina_obra(
                obra,
                todas_obras=obras,
                imagens=imagens_por_obra.get(
                    obra_id,
                    [],
                ),
            )

            diretorio_obra = (
                DIRETORIO_SAIDA / "obra" / obra_id
            )

            diretorio_obra.mkdir(
                parents=True,
                exist_ok=True,
            )

            caminho_html = diretorio_obra / "index.html"

            caminho_html.write_text(
                pagina_html,
                encoding="utf-8",
            )

            valida, mensagem = validar_pagina_html(
                caminho_html
            )

            if valida:
                total_geradas += 1
                print(f"  OK: {mensagem}")
            else:
                total_invalidas += 1
                print(f"  AVISO: {mensagem}")

        except Exception as erro:
            total_erros += 1

            print(
                f"  ERRO ao gerar a página da obra "
                f"{obra_id}: {erro}"
            )

    print("\nA atualizar sitemap.xml...")
    gerar_sitemap(obras)

    print("A atualizar robots.txt...")
    gerar_robots()

    print("\n" + "=" * 58)
    print("RESUMO DA GERAÇÃO SEO")
    print("=" * 58)

    print(f"Obras encontradas: {len(obras)}")
    print(f"Páginas válidas geradas: {total_geradas}")
    print(
        "Páginas com avisos de validação: "
        f"{total_invalidas}"
    )
    print(f"Erros de geração: {total_erros}")
    print(f"Diretório de saída: {DIRETORIO_SAIDA}")

    print("=" * 58)

    return obras


# ============================================================
# PONTO DE ENTRADA
# ============================================================

def main():
    """Executa o gerador SEO."""

    print("=" * 58)
    print("OBRA LIVRE - GERADOR DE PÃGINAS SEO")
    print("=" * 58)

    print(f"URL do site: {URL_SITE}")
    print(f"Diretório de saída: {DIRETORIO_SAIDA}")

    print("\nA verificar a configuração do Supabase...")

    try:
        configuracao_ok = descobrir_configuracao_supabase()

        if not configuracao_ok:
            print(
                "\nERRO: não foi possível identificar "
                "a configuração do Supabase."
            )

            print(
                "Verifica seo_supabase.py e a configuração "
                "SupabaseConfig do projeto Flutter."
            )

            return 1

        print("Configuração do Supabase identificada.")

        gerar_todas_as_paginas()

        print("\nProcesso SEO concluído.")

        return 0

    except KeyboardInterrupt:
        print("\nProcesso interrompido pelo utilizador.")
        return 130

    except Exception as erro:
        print(
            "\nERRO durante a geração SEO:\n"
            f"{type(erro).__name__}: {erro}"
        )

        return 1


if __name__ == "__main__":
    sys.exit(main())
