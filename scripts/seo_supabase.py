"""Ligação REST ao Supabase e leitura dos dados."""
import json
import os
import re
import urllib.parse
import urllib.request
import urllib.error

from seo_config import BASE_DIR, SUPABASE_TABLE_OBRAS, SUPABASE_TABLE_SECOES, SUPABASE_TABLE_IMAGENS
from seo_utils import texto_seguro

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
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

    cabecalhos = {
        "apikey": SUPABASE_ANON_KEY,
        "Accept": "application/json",
        "User-Agent": "ObraLivre-SEO-Generator/1.0",
    }
    # Chaves anon antigas são JWT; publishable keys modernas não são JWT.
    if SUPABASE_ANON_KEY.startswith("eyJ"):
        cabecalhos["Authorization"] = f"Bearer {SUPABASE_ANON_KEY}"

    pedido = urllib.request.Request(
        endereco,
        headers=cabecalhos,
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

