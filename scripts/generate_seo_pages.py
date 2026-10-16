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
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

BASE_URL = "https://ginho83-wq.github.io/teste"
PROJECT_BASE = "/teste/"

OUTPUT_DIR = BASE_DIR / "build" / "web"
SITEMAP_PATH = OUTPUT_DIR / "sitemap.xml"

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

SITEMAP_NS = "http://www.sitemaps.org/schemas/sitemap/0.9"

ET.register_namespace("", SITEMAP_NS)


# ============================================================
# CONFIGURAÇÃO SUPABASE
# ============================================================

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "").strip()


def procurar_configuracao_supabase():
    """
    Procura a configuração pública do Supabase nos ficheiros Dart.
    As variáveis de ambiente têm prioridade.
    """

    global SUPABASE_URL, SUPABASE_ANON_KEY

    if SUPABASE_URL and SUPABASE_ANON_KEY:
        return

    pasta_lib = BASE_DIR / "lib"

    if not pasta_lib.exists():
        return

    padroes_url = [
        r"""(?:supabaseUrl|supabase_url|url)\s*[:=]\s*['"]([^'"]+)['"]""",
        r"""Supabase\.initialize\s*\(\s*url\s*:\s*['"]([^'"]+)['"]""",
    ]

    padroes_key = [
        r"""(?:supabaseAnonKey|supabase_anon_key|anonKey|publishableKey|anon_key)\s*[:=]\s*['"]([^'"]+)['"]""",
        r"""Supabase\.initialize\s*\([\s\S]*?anonKey\s*:\s*['"]([^'"]+)['"]""",
    ]

    ficheiros = list(pasta_lib.rglob("*.dart"))

    for ficheiro in ficheiros:
        try:
            conteudo = ficheiro.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue

        if not SUPABASE_URL:
            for padrao in padroes_url:
                resultado = re.search(padrao, conteudo, re.IGNORECASE)

                if resultado:
                    valor = resultado.group(1).strip()

                    if valor.startswith("https://"):
                        SUPABASE_URL = valor.rstrip("/")
                        break

        if not SUPABASE_ANON_KEY:
            for padrao in padroes_key:
                resultado = re.search(padrao, conteudo, re.IGNORECASE)

                if resultado:
                    SUPABASE_ANON_KEY = resultado.group(1).strip()
                    break

        if SUPABASE_URL and SUPABASE_ANON_KEY:
            return


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def texto_seguro(valor):
    if valor is None:
        return ""

    return str(valor).strip()


def escapar(valor):
    return html.escape(texto_seguro(valor), quote=True)


def escapar_json(valor):
    """
    Converte dados Python para JSON seguro para inclusão em JavaScript.
    """

    resultado = json.dumps(
        valor,
        ensure_ascii=False
    )

    return (
        resultado
        .replace("</", "<\\/")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")
    )


def url_absoluta(caminho):
    caminho = texto_seguro(caminho)

    if not caminho:
        return BASE_URL + PROJECT_BASE

    if caminho.startswith("https://") or caminho.startswith("http://"):
        return caminho

    if caminho.startswith("/"):
        return BASE_URL + caminho

    return BASE_URL + PROJECT_BASE + caminho


def url_obra(obra_id):
    return url_absoluta(
        PROJECT_BASE + "obra/" + urllib.parse.quote(texto_seguro(obra_id)) + "/"
    )


def converter_inteiro(valor, padrao=0):
    try:
        if valor is None or valor == "":
            return padrao

        return int(float(valor))

    except (ValueError, TypeError):
        return padrao


def converter_data(valor):
    if not valor:
        return None

    valor = texto_seguro(valor)

    try:
        return datetime.fromisoformat(
            valor.replace("Z", "+00:00")
        )

    except (ValueError, TypeError):
        pass

    for formato in (
        "%Y-%m-%d",
        "%Y-%m-%d %H:%M:%S",
        "%d/%m/%Y",
    ):
        try:
            return datetime.strptime(valor, formato)

        except ValueError:
            continue

    return None


def data_formatada(valor):
    data = converter_data(valor)

    if not data:
        return ""

    return data.strftime("%d/%m/%Y")


def ano_da_obra(obra):
    """
    Obtém o ano real da obra, sem inventar um ano de publicação.
    """

    ano = texto_seguro(obra.get("ano_obra"))

    if ano and ano.isdigit():
        return ano

    for campo in (
        "data_publicacao",
        "created_at",
        "updated_at",
    ):
        data = converter_data(obra.get(campo))

        if data:
            return str(data.year)

    return ""


def data_acesso():
    return date.today().strftime("%d/%m/%Y")


def data_acesso_abnt():
    meses = [
        "jan.",
        "fev.",
        "mar.",
        "abr.",
        "maio",
        "jun.",
        "jul.",
        "ago.",
        "set.",
        "out.",
        "nov.",
        "dez.",
    ]

    hoje = date.today()

    return f"{hoje.day} {meses[hoje.month - 1]} {hoje.year}"


def descricao_seo(texto, limite=160):
    texto = re.sub(r"\s+", " ", texto_seguro(texto)).strip()

    if len(texto) <= limite:
        return texto

    texto = texto[:limite].rsplit(" ", 1)[0]

    return texto.rstrip(".,;: ") + "…"


def nome_ficheiro_pdf(url_pdf):
    if not url_pdf:
        return "documento.pdf"

    caminho = urllib.parse.urlparse(url_pdf).path
    nome = caminho.rsplit("/", 1)[-1]

    if not nome:
        return "documento.pdf"

    return urllib.parse.unquote(nome)


def url_pdf_com_nome(url_pdf, titulo):
    """
    Acrescenta o nome sugerido para descarregar o PDF.
    """

    if not url_pdf:
        return ""

    nome = re.sub(
        r'[\\/:*?"<>|]+',
        "",
        texto_seguro(titulo)
    ).strip()

    nome = re.sub(r"\s+", "_", nome)

    if not nome:
        nome = "documento"

    nome += ".pdf"

    separador = "&" if "?" in url_pdf else "?"

    return (
        url_pdf
        + separador
        + "download="
        + urllib.parse.quote(nome)
    )


def formatar_tamanho(tamanho):
    tamanho = converter_inteiro(tamanho)

    if tamanho <= 0:
        return ""

    if tamanho < 1024:
        return f"{tamanho} bytes"

    if tamanho < 1024 * 1024:
        return f"{tamanho / 1024:.1f} KB"

    if tamanho < 1024 * 1024 * 1024:
        return f"{tamanho / (1024 * 1024):.2f} MB"

    return f"{tamanho / (1024 * 1024 * 1024):.2f} GB"


def normalizar_texto(texto):
    texto = texto_seguro(texto).lower()

    texto = re.sub(r"\s+", " ", texto)

    return texto.strip()


def hoje_iso():
    return datetime.now(timezone.utc).date().isoformat()


def limpar_html(texto):
    """
    Remove etiquetas HTML de conteúdo textual antes de o inserir
    em elementos HTML gerados pelo script.
    """

    texto = texto_seguro(texto)

    texto = re.sub(
        r"<\s*(script|style)\b[^>]*>.*?<\s*/\s*\1\s*>",
        " ",
        texto,
        flags=re.IGNORECASE | re.DOTALL,
    )

    texto = re.sub(r"<[^>]+>", " ", texto)

    texto = html.unescape(texto)

    texto = re.sub(r"\s+", " ", texto)

    return texto.strip()


def texto_em_paragrafos(texto):
    """
    Converte texto simples em parágrafos HTML.
    """

    texto = texto_seguro(texto)

    if not texto:
        return ""

    texto = texto.replace("\r\n", "\n").replace("\r", "\n")

    blocos = re.split(r"\n\s*\n", texto)

    paragrafos = []

    for bloco in blocos:
        bloco = bloco.strip()

        if not bloco:
            continue

        linhas = bloco.split("\n")

        conteudo = "<br>".join(
            escapar(linha.strip())
            for linha in linhas
            if linha.strip()
        )

        if conteudo:
            paragrafos.append(f"<p>{conteudo}</p>")

    return "\n".join(paragrafos)


# ============================================================
# SUPABASE REST API
# ============================================================

def consultar_supabase(caminho, parametros=None):
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Configuração do Supabase não encontrada. "
            "Define SUPABASE_URL e SUPABASE_ANON_KEY "
            "ou verifica os ficheiros de configuração Dart."
        )

    url = SUPABASE_URL + "/rest/v1/" + caminho

    if parametros:
        url += "?" + urllib.parse.urlencode(
            parametros,
            doseq=True,
            safe="(),.*"
        )

    pedido = urllib.request.Request(
        url,
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": "Bearer " + SUPABASE_ANON_KEY,
            "Accept": "application/json",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(pedido, timeout=60) as resposta:
            conteudo = resposta.read().decode("utf-8")

            if not conteudo:
                return []

            return json.loads(conteudo)

    except urllib.error.HTTPError as erro:
        corpo = erro.read().decode(
            "utf-8",
            errors="replace"
        )

        raise RuntimeError(
            f"Erro Supabase HTTP {erro.code}: {corpo}"
        ) from erro

    except urllib.error.URLError as erro:
        raise RuntimeError(
            f"Não foi possível contactar o Supabase: {erro}"
        ) from erro


def consultar_tabela(tabela, campos="*", parametros=None):
    parametros = dict(parametros or {})

    parametros.setdefault("select", campos)

    return consultar_supabase(
        tabela,
        parametros
    )


# ============================================================
# OBRAS
# ============================================================

def obter_obras():
    campos = (
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

    return consultar_tabela(
        "obras",
        campos=campos,
        parametros={
            "order": "created_at.desc",
        }
    )


def obter_secoes(obra_id):
    try:
        secoes = consultar_tabela(
            "teste_secoes",
            campos=(
                "id,"
                "obra_id,"
                "titulo,"
                "conteudo,"
                "ordem,"
                "nivel,"
                "paragrafo_ordem"
            ),
            parametros={
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

        return sorted(
            secoes,
            key=lambda item: (
                converter_inteiro(item.get("ordem")),
                converter_inteiro(item.get("paragrafo_ordem")),
            )
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível obter secções da obra "
            f"{obra_id}: {erro}"
        )

        return []


def obter_imagens(obra_id):
    try:
        imagens = consultar_tabela(
            "teste_imagens",
            campos=(
                "id,"
                "obra_id,"
                "url_imagem,"
                "legenda,"
                "posicao,"
                "ordem,"
                "fonte,"
                "paragrafo_ordem"
            ),
            parametros={
                "obra_id": f"eq.{obra_id}",
                "order": "ordem.asc",
            },
        )

        return sorted(
            imagens,
            key=lambda item: (
                converter_inteiro(item.get("paragrafo_ordem"), 999999),
                converter_inteiro(item.get("ordem")),
            )
        )

    except Exception as erro:
        print(
            f"Aviso: não foi possível obter imagens da obra "
            f"{obra_id}: {erro}"
        )

        return []


# ============================================================
# CONTEÚDO DAS SECÇÕES
# ============================================================

def gerar_html_secoes(secoes):
    if not secoes:
        return ""

    blocos = []
    conteudos_processados = set()

    for secao in secoes:
        titulo = texto_seguro(secao.get("titulo"))
        conteudo = texto_seguro(secao.get("conteudo"))

        if not titulo and not conteudo:
            continue

        chave = normalizar_texto(conteudo)

        if chave and chave in conteudos_processados:
            continue

        if chave:
            conteudos_processados.add(chave)

        nivel = converter_inteiro(
            secao.get("nivel"),
            2
        )

        nivel = max(2, min(nivel, 6))

        if titulo:
            blocos.append(
                f"<h{nivel}>{escapar(titulo)}</h{nivel}>"
            )

        if conteudo:
            blocos.append(
                texto_em_paragrafos(conteudo)
            )

    return "\n".join(blocos)


# ============================================================
# IMAGENS
# ============================================================

def gerar_html_imagens(imagens):
    if not imagens:
        return ""

    blocos = []

    for imagem in imagens:
        url = texto_seguro(imagem.get("url_imagem"))

        if not url:
            continue

        legenda = texto_seguro(imagem.get("legenda"))
        fonte = texto_seguro(imagem.get("fonte"))

        legenda_html = ""

        if legenda:
            legenda_html += (
                f"<figcaption>{escapar(legenda)}</figcaption>"
            )

        if fonte:
            legenda_html += (
                f'<p class="fonte-imagem">'
                f"Fonte: {escapar(fonte)}"
                f"</p>"
            )

        blocos.append(
            f"""
            <figure class="imagem-obra">
                <img
                    src="{escapar(url)}"
                    alt="{escapar(legenda or 'Imagem da obra académica')}"
                    loading="lazy"
                    decoding="async"
                >
                {legenda_html}
            </figure>
            """
        )

    return "\n".join(blocos)


# ============================================================
# OBRAS RELACIONADAS
# ============================================================

def obter_obras_relacionadas(obra, todas_obras, limite=5):
    obra_id = texto_seguro(obra.get("id"))
    categoria = normalizar_texto(obra.get("categoria"))
    autor = normalizar_texto(obra.get("autor"))

    classificadas = []

    for outra in todas_obras:
        if texto_seguro(outra.get("id")) == obra_id:
            continue

        pontuacao = 0

        if categoria and normalizar_texto(
            outra.get("categoria")
        ) == categoria:
            pontuacao += 2

        if autor and normalizar_texto(
            outra.get("autor")
        ) == autor:
            pontuacao += 3

        classificadas.append(
            (pontuacao, outra)
        )

    classificadas.sort(
        key=lambda item: (
            item[0],
            texto_seguro(
                item[1].get("created_at")
            )
        ),
        reverse=True
    )

    relacionadas = [
        obra_relacionada
        for pontuacao, obra_relacionada in classificadas
        if pontuacao > 0
    ]

    if len(relacionadas) < limite:
        ids_existentes = {
            texto_seguro(item.get("id"))
            for item in relacionadas
        }

        for _, outra in classificadas:
            outro_id = texto_seguro(outra.get("id"))

            if outro_id in ids_existentes:
                continue

            relacionadas.append(outra)
            ids_existentes.add(outro_id)

            if len(relacionadas) >= limite:
                break

    return relacionadas[:limite]


def gerar_html_relacionadas(obra, todas_obras):
    relacionadas = obter_obras_relacionadas(
        obra,
        todas_obras
    )

    if not relacionadas:
        return ""

    blocos = []

    for relacionada in relacionadas:
        titulo = texto_seguro(
            relacionada.get("titulo")
        ) or "Obra sem título"

        identificador = texto_seguro(
            relacionada.get("id")
        )

        descricao = descricao_seo(
            relacionada.get("descricao")
            or relacionada.get("conteudo_texto")
            or ""
        )

        url = url_obra(identificador)

        autor = texto_seguro(
            relacionada.get("autor")
        )

        autor_html = ""

        if autor:
            autor_html = (
                f'<p class="obra-relacionada-autor">'
                f"{escapar(autor)}"
                f"</p>"
            )

        descricao_html = ""

        if descricao:
            descricao_html = (
                f'<p class="obra-relacionada-descricao">'
                f"{escapar(descricao)}"
                f"</p>"
            )

        blocos.append(
            f"""
            <article class="obra-relacionada">
                <h3>
                    <a href="{escapar(url)}">
                        {escapar(titulo)}
                    </a>
                </h3>
                {autor_html}
                {descricao_html}
            </article>
            """
        )

    return f"""
        <section class="secao-relacionadas">
            <h2>Obras relacionadas</h2>
            <div class="lista-relacionadas">
                {"".join(blocos)}
            </div>
        </section>
    """


# ============================================================
# GERAÇÃO DE CITAÇÕES
# ============================================================

def preparar_dados_citacao(obra, url):
    titulo = limpar_html(
        obra.get("titulo")
    ) or "Obra sem título"

    autor = limpar_html(
        obra.get("autor")
    )

    ano = ano_da_obra(obra)

    categoria = limpar_html(
        obra.get("categoria")
    )

    nome_site = NOME_SITE

    if autor:
        autor_apa = autor
        autor_abnt = autor.upper()
        autor_vancouver = autor
        autor_iso = autor.upper()
    else:
        autor_apa = ""
        autor_abnt = ""
        autor_vancouver = ""
        autor_iso = ""

    ano_referencia = ano or "s.d."

    # APA 7
    if autor_apa:
        citacao_apa = (
            f"{autor_apa}. ({ano_referencia}). "
            f"{titulo}. {nome_site}. {url}"
        )
    else:
        citacao_apa = (
            f"{titulo}. ({ano_referencia}). "
            f"{nome_site}. {url}"
        )

    # ABNT
    if autor_abnt:
        citacao_abnt = (
            f"{autor_abnt}. {titulo}. "
            f"{nome_site}, {ano_referencia}. "
            f"Disponível em: {url}. "
            f"Acesso em: {data_acesso_abnt()}."
        )
    else:
        citacao_abnt = (
            f"{titulo}. {nome_site}, {ano_referencia}. "
            f"Disponível em: {url}. "
            f"Acesso em: {data_acesso_abnt()}."
        )

    # Vancouver
    if autor_vancouver:
        citacao_vancouver = (
            f"{autor_vancouver}. {titulo} [Internet]. "
            f"{nome_site}; {ano_referencia} "
            f"[citado {data_acesso()}]. "
            f"Disponível em: {url}."
        )
    else:
        citacao_vancouver = (
            f"{titulo} [Internet]. "
            f"{nome_site}; {ano_referencia} "
            f"[citado {data_acesso()}]. "
            f"Disponível em: {url}."
        )

    # ISO 690
    if autor_iso:
        citacao_iso = (
            f"{autor_iso}. {titulo} [online]. "
            f"{nome_site}, {ano_referencia} "
            f"[acesso em {data_acesso()}]. "
            f"Disponível em: {url}."
        )
    else:
        citacao_iso = (
            f"{titulo} [online]. "
            f"{nome_site}, {ano_referencia} "
            f"[acesso em {data_acesso()}]. "
            f"Disponível em: {url}."
        )

    return {
        "apa": citacao_apa,
        "abnt": citacao_abnt,
        "vancouver": citacao_vancouver,
        "iso690": citacao_iso,
    }


def gerar_html_botao_citar(obra, url):
    dados = preparar_dados_citacao(
        obra,
        url
    )

    dados_json = escapar_json(dados)

    return f"""
    <section class="secao-citacao" aria-label="Citar esta obra">
        <button
            type="button"
            class="botao-citar"
            id="abrir-modal-citacao"
            aria-haspopup="dialog"
            aria-controls="modal-citacao"
        >
            <span aria-hidden="true">❝</span>
            Citar
        </button>
    </section>

    <div
        class="modal-citacao"
        id="modal-citacao"
        role="dialog"
        aria-modal="true"
        aria-labelledby="titulo-modal-citacao"
        aria-hidden="true"
        hidden
    >
        <div class="modal-citacao-fundo" data-fechar-citacao></div>

        <div class="modal-citacao-conteudo">
            <div class="modal-citacao-cabecalho">
                <div>
                    <h2 id="titulo-modal-citacao">
                        Citar esta obra
                    </h2>
                    <p>
                        Escolhe o estilo de referência bibliográfica.
                    </p>
                </div>

                <button
                    type="button"
                    class="botao-fechar-citacao"
                    id="fechar-modal-citacao"
                    aria-label="Fechar janela de citação"
                >
                    &times;
                </button>
            </div>

            <label
                for="estilo-citacao"
                class="rotulo-estilo-citacao"
            >
                Estilo de citação
            </label>

            <select
                id="estilo-citacao"
                class="seletor-citacao"
            >
                <option value="apa">APA 7.ª edição</option>
                <option value="abnt">ABNT</option>
                <option value="vancouver">Vancouver</option>
                <option value="iso690">ISO 690</option>
            </select>

            <label
                for="texto-citacao"
                class="rotulo-texto-citacao"
            >
                Referência bibliográfica
            </label>

            <textarea
                id="texto-citacao"
                class="texto-citacao"
                rows="6"
                readonly
            ></textarea>

            <div class="acoes-citacao">
                <button
                    type="button"
                    class="botao-copiar-citacao"
                    id="copiar-citacao"
                >
                    Copiar citação
                </button>

                <button
                    type="button"
                    class="botao-cancelar-citacao"
                    id="cancelar-citacao"
                >
                    Fechar
                </button>
            </div>

            <p
                class="mensagem-citacao"
                id="mensagem-citacao"
                role="status"
                aria-live="polite"
            ></p>

            <p class="nota-citacao">
                Confirma os requisitos de citação da tua instituição
                antes de utilizares a referência num trabalho académico.
            </p>
        </div>
    </div>

    <script>
    (function () {{
        "use strict";

        const citacoes = {dados_json};

        const modal = document.getElementById("modal-citacao");
        const botaoAbrir = document.getElementById(
            "abrir-modal-citacao"
        );
        const botaoFechar = document.getElementById(
            "fechar-modal-citacao"
        );
        const botaoCancelar = document.getElementById(
            "cancelar-citacao"
        );
        const botaoCopiar = document.getElementById(
            "copiar-citacao"
        );
        const seletor = document.getElementById(
            "estilo-citacao"
        );
        const campoTexto = document.getElementById(
            "texto-citacao"
        );
        const mensagem = document.getElementById(
            "mensagem-citacao"
        );

        if (
            !modal ||
            !botaoAbrir ||
            !botaoFechar ||
            !botaoCopiar ||
            !seletor ||
            !campoTexto
        ) {{
            return;
        }}

        let elementoAnterior = null;

        function atualizarCitacao() {{
            const estilo = seletor.value;

            campoTexto.value = citacoes[estilo] || "";

            if (mensagem) {{
                mensagem.textContent = "";
            }}
        }}

        function abrirModal() {{
            elementoAnterior = document.activeElement;

            modal.hidden = false;
            modal.setAttribute("aria-hidden", "false");

            document.body.classList.add(
                "modal-citacao-aberto"
            );

            atualizarCitacao();

            window.setTimeout(function () {{
                seletor.focus();
            }}, 0);
        }}

        function fecharModal() {{
            modal.hidden = true;
            modal.setAttribute("aria-hidden", "true");

            document.body.classList.remove(
                "modal-citacao-aberto"
            );

            if (
                elementoAnterior &&
                typeof elementoAnterior.focus === "function"
            ) {{
                elementoAnterior.focus();
            }}
        }}

        async function copiarTexto() {{
            const texto = campoTexto.value;

            if (!texto) {{
                return;
            }}

            try {{
                if (
                    navigator.clipboard &&
                    window.isSecureContext
                ) {{
                    await navigator.clipboard.writeText(texto);
                }} else {{
                    campoTexto.focus();
                    campoTexto.select();

                    const copiado = document.execCommand("copy");

                    if (!copiado) {{
                        throw new Error(
                            "Não foi possível copiar automaticamente."
                        );
                    }}
                }}

                mensagem.textContent = "Citação copiada com sucesso!";
                mensagem.classList.add("citacao-sucesso");
                mensagem.classList.remove("citacao-erro");

            }} catch (erro) {{
                campoTexto.focus();
                campoTexto.select();

                mensagem.textContent =
                    "Não foi possível copiar automaticamente. "
                    + "Seleciona o texto e copia manualmente.";

                mensagem.classList.remove("citacao-sucesso");
                mensagem.classList.add("citacao-erro");
            }}
        }}

        botaoAbrir.addEventListener(
            "click",
            abrirModal
        );

        botaoFechar.addEventListener(
            "click",
            fecharModal
        );

        botaoCancelar.addEventListener(
            "click",
            fecharModal
        );

        botaoCopiar.addEventListener(
            "click",
            copiarTexto
        );

        seletor.addEventListener(
            "change",
            atualizarCitacao
        );

        modal.querySelectorAll(
            "[data-fechar-citacao]"
        ).forEach(function (elemento) {{
            elemento.addEventListener(
                "click",
                fecharModal
            );
        }});

        document.addEventListener(
            "keydown",
            function (evento) {{
                if (modal.hidden) {{
                    return;
                }}

                if (evento.key === "Escape") {{
                    fecharModal();
                }}
            }}
        );

        atualizarCitacao();
    }})();
    </script>
    """


# ============================================================
# DADOS ESTRUTURADOS JSON-LD
# ============================================================

def gerar_json_ld(obra, url):
    titulo = limpar_html(
        obra.get("titulo")
    ) or "Obra sem título"

    descricao = limpar_html(
        obra.get("descricao")
        or obra.get("conteudo_texto")
        or titulo
    )

    autor = limpar_html(
        obra.get("autor")
    )

    categoria = texto_seguro(
        obra.get("categoria")
    )

    categoria_normalizada = normalizar_texto(
        categoria
    )

    if (
        "artigo" in categoria_normalizada
        or "comunica" in categoria_normalizada
    ):
        tipo = "ScholarlyArticle"

    elif (
        "tese" in categoria_normalizada
        or "disserta" in categoria_normalizada
    ):
        tipo = "Thesis"

    elif "relatório" in categoria_normalizada or "relatorio" in categoria_normalizada:
        tipo = "Report"

    else:
        tipo = "CreativeWork"

    dados = {
        "@context": "https://schema.org",
        "@type": tipo,
        "name": titulo,
        "headline": titulo,
        "description": descricao_seo(descricao, 300),
        "url": url,
        "inLanguage": "pt",
        "publisher": {
            "@type": "Organization",
            "name": NOME_SITE,
            "url": BASE_URL + PROJECT_BASE,
        },
    }

    if autor:
        dados["author"] = {
            "@type": "Person",
            "name": autor,
        }

    if categoria:
        dados["genre"] = categoria

    ano = ano_da_obra(obra)

    if ano.isdigit():
        dados["datePublished"] = ano

    else:
        data_publicacao = texto_seguro(
            obra.get("data_publicacao")
        )

        if data_publicacao:
            data = converter_data(data_publicacao)

            if data:
                dados["datePublished"] = data.date().isoformat()

    url_pdf = texto_seguro(
        obra.get("url_documento")
    )

    if url_pdf:
        dados["encoding"] = {
            "@type": "MediaObject",
            "contentUrl": url_pdf,
            "encodingFormat": "application/pdf",
        }

    return escapar_json(dados)


# ============================================================
# ESTATÍSTICAS
# ============================================================

def gerar_javascript_estatisticas(obra_id):
    configuracao = {
        "supabaseUrl": SUPABASE_URL,
        "supabaseAnonKey": SUPABASE_ANON_KEY,
        "obraId": texto_seguro(obra_id),
    }

    configuracao_json = escapar_json(configuracao)

    return f"""
    <script>
    (function () {{
        "use strict";

        const config = {configuracao_json};

        if (
            !config.supabaseUrl ||
            !config.supabaseAnonKey ||
            !config.obraId
        ) {{
            return;
        }}

        async function registarEvento(tipo) {{
            try {{
                const resposta = await fetch(
                    config.supabaseUrl
                        + "/rest/v1/rpc/registar_obra_evento",
                    {{
                        method: "POST",
                        headers: {{
                            "Content-Type": "application/json",
                            "apikey": config.supabaseAnonKey,
                            "Authorization":
                                "Bearer " + config.supabaseAnonKey
                        }},
                        body: JSON.stringify({{
                            p_obra_id: config.obraId,
                            p_tipo_evento: tipo
                        }})
                    }}
                );

                if (!resposta.ok) {{
                    console.warn(
                        "Não foi possível registar o evento:",
                        tipo,
                        resposta.status
                    );
                }}

            }} catch (erro) {{
                console.warn(
                    "Erro ao registar evento:",
                    erro
                );
            }}
        }}

        if (!sessionStorage.getItem(
            "obra_vista_" + config.obraId
        )) {{
            sessionStorage.setItem(
                "obra_vista_" + config.obraId,
                "1"
            );

            registarEvento("visualizacao");
        }}

        document.querySelectorAll(
            "[data-evento-pdf]"
        ).forEach(function (botao) {{
            botao.addEventListener(
                "click",
                function () {{
                    registarEvento("clique_pdf");
                }}
            );
        }});
    }})();
    </script>
    """


# ============================================================
# ESTILOS CSS
# ============================================================

def gerar_css():
    return """
    <style>
        :root {
            color-scheme: light;
            --cor-primaria: #1769aa;
            --cor-primaria-escura: #104b80;
            --cor-texto: #243447;
            --cor-texto-secundario: #5d6b7a;
            --cor-fundo: #f5f8fc;
            --cor-cartao: #ffffff;
            --cor-borda: #dce5ef;
            --cor-sucesso: #16794b;
            --sombra: 0 8px 28px rgba(20, 50, 80, 0.08);
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            font-size: 15px;
            line-height: 1.7;
            color: var(--cor-texto);
            background: var(--cor-fundo);
        }

        body.modal-citacao-aberto {
            overflow: hidden;
        }

        a {
            color: var(--cor-primaria);
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        .cabecalho {
            background: #eaf4ff;
            border-bottom: 1px solid #d5e5f5;
        }

        .cabecalho-conteudo {
            max-width: 1120px;
            margin: 0 auto;
            padding: 14px 22px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 18px;
        }

        .marca {
            color: #164d80;
            font-size: 17px;
            font-weight: 700;
        }

        .navegacao a {
            margin-left: 16px;
            font-size: 13px;
            font-weight: 600;
        }

        .conteudo-principal {
            max-width: 940px;
            margin: 28px auto;
            padding: 0 20px;
        }

        .artigo {
            background: var(--cor-cartao);
            border: 1px solid var(--cor-borda);
            border-radius: 12px;
            padding: 30px;
            box-shadow: var(--sombra);
        }

        .titulo-obra {
            margin: 0 0 14px;
            font-size: 27px;
            line-height: 1.35;
            overflow-wrap: anywhere;
        }

        .metadados {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin: 0 0 20px;
        }

        .metadado {
            display: inline-block;
            background: #edf5fd;
            border: 1px solid #dbeafa;
            border-radius: 5px;
            padding: 4px 9px;
            font-size: 12px;
            color: #315675;
        }

        .descricao-obra {
            margin: 0 0 24px;
            padding: 15px 17px;
            background: #f7faff;
            border-left: 3px solid var(--cor-primaria);
            border-radius: 4px;
            font-size: 14px;
            text-align: justify;
        }

        .conteudo-obra {
            overflow-wrap: anywhere;
        }

        .conteudo-obra h2 {
            margin-top: 30px;
            margin-bottom: 12px;
            font-size: 20px;
            line-height: 1.4;
        }

        .conteudo-obra h3 {
            margin-top: 24px;
            margin-bottom: 10px;
            font-size: 18px;
            line-height: 1.45;
        }

        .conteudo-obra h4,
        .conteudo-obra h5,
        .conteudo-obra h6 {
            margin-top: 20px;
            margin-bottom: 8px;
            font-size: 16px;
            line-height: 1.5;
        }

        .conteudo-obra p {
            margin: 0 0 15px;
            text-align: justify;
            font-size: 14px;
        }

        .imagem-obra {
            margin: 24px 0;
            text-align: center;
        }

        .imagem-obra img {
            max-width: 100%;
            height: auto;
            border-radius: 7px;
        }

        .imagem-obra figcaption {
            margin-top: 8px;
            color: var(--cor-texto-secundario);
            font-size: 12px;
        }

        .fonte-imagem {
            margin-top: 4px;
            color: var(--cor-texto-secundario);
            font-size: 11px;
        }

        .informacao-tecnica {
            margin-top: 26px;
            padding: 18px;
            background: #f7faff;
            border: 1px solid var(--cor-borda);
            border-radius: 8px;
        }

        .informacao-tecnica h2 {
            margin: 0 0 10px;
            font-size: 18px;
        }

        .informacao-tecnica p {
            margin: 5px 0;
            font-size: 13px;
        }

        .secao-pdf {
            margin-top: 24px;
            padding: 20px;
            background: #f7faff;
            border: 1px solid var(--cor-borda);
            border-radius: 8px;
        }

        .secao-pdf h2 {
            margin-top: 0;
            font-size: 18px;
        }

        .botoes-pdf {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 12px;
        }

        .botao-pdf {
            display: inline-block;
            border: 0;
            border-radius: 6px;
            padding: 10px 16px;
            background: var(--cor-primaria);
            color: white;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
        }

        .botao-pdf:hover {
            background: var(--cor-primaria-escura);
            color: white;
            text-decoration: none;
        }

        /* BOTÃO CITAR */

        .secao-citacao {
            margin: 20px 0;
        }

        .botao-citar {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            min-height: 40px;
            padding: 9px 17px;
            border: 1px solid #b8d4ef;
            border-radius: 7px;
            background: #edf5ff;
            color: #17588d;
            font-family: inherit;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            transition:
                background 0.2s ease,
                border-color 0.2s ease;
        }

        .botao-citar:hover {
            background: #dcecff;
            border-color: #8fbbe5;
        }

        .botao-citar:focus-visible,
        .botao-fechar-citacao:focus-visible,
        .botao-copiar-citacao:focus-visible,
        .botao-cancelar-citacao:focus-visible,
        .seletor-citacao:focus-visible,
        .texto-citacao:focus-visible {
            outline: 3px solid #8dbff0;
            outline-offset: 2px;
        }

        /* JANELA MODAL DE CITAÇÃO */

        .modal-citacao[hidden] {
            display: none !important;
        }

        .modal-citacao {
            position: fixed;
            inset: 0;
            z-index: 99999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 18px;
        }

        .modal-citacao-fundo {
            position: absolute;
            inset: 0;
            background: rgba(13, 29, 46, 0.66);
            backdrop-filter: blur(3px);
        }

        .modal-citacao-conteudo {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 590px;
            max-height: calc(100vh - 36px);
            overflow-y: auto;
            padding: 25px;
            background: #ffffff;
            border: 1px solid #dce5ef;
            border-radius: 13px;
            box-shadow: 0 20px 65px rgba(0, 0, 0, 0.25);
        }

        .modal-citacao-cabecalho {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 14px;
            margin-bottom: 20px;
        }

        .modal-citacao-cabecalho h2 {
            margin: 0;
            color: #203b55;
            font-size: 21px;
            line-height: 1.4;
        }

        .modal-citacao-cabecalho p {
            margin: 5px 0 0;
            color: #687789;
            font-size: 13px;
        }

        .botao-fechar-citacao {
            flex-shrink: 0;
            width: 36px;
            height: 36px;
            border: 1px solid #dce5ef;
            border-radius: 7px;
            background: #f6f8fb;
            color: #33475b;
            font-size: 26px;
            line-height: 1;
            cursor: pointer;
        }

        .rotulo-estilo-citacao,
        .rotulo-texto-citacao {
            display: block;
            margin: 15px 0 7px;
            color: #2e4358;
            font-size: 13px;
            font-weight: 700;
        }

        .seletor-citacao {
            display: block;
            width: 100%;
            min-height: 44px;
            padding: 10px 12px;
            border: 1px solid #cbd9e7;
            border-radius: 7px;
            background: #ffffff;
            color: #243447;
            font-family: inherit;
            font-size: 14px;
        }

        .texto-citacao {
            display: block;
            width: 100%;
            min-height: 145px;
            resize: vertical;
            padding: 13px;
            border: 1px solid #cbd9e7;
            border-radius: 7px;
            background: #f8fafc;
            color: #263747;
            font-family: Arial, Helvetica, sans-serif;
            font-size: 13px;
            line-height: 1.7;
            overflow-wrap: anywhere;
        }

        .acoes-citacao {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 16px;
        }

        .botao-copiar-citacao,
        .botao-cancelar-citacao {
            min-height: 42px;
            padding: 10px 17px;
            border-radius: 7px;
            font-family: inherit;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
        }

        .botao-copiar-citacao {
            border: 1px solid var(--cor-primaria);
            background: var(--cor-primaria);
            color: white;
        }

        .botao-copiar-citacao:hover {
            background: var(--cor-primaria-escura);
        }

        .botao-cancelar-citacao {
            border: 1px solid #d3deea;
            background: #ffffff;
            color: #405469;
        }

        .botao-cancelar-citacao:hover {
            background: #f1f5f9;
        }

        .mensagem-citacao {
            min-height: 20px;
            margin: 12px 0 0;
            font-size: 13px;
        }

        .citacao-sucesso {
            color: var(--cor-sucesso);
        }

        .citacao-erro {
            color: #b42318;
        }

        .nota-citacao {
            margin: 10px 0 0;
            color: #718096;
            font-size: 11px;
            line-height: 1.6;
        }

        /* OBRAS RELACIONADAS */

        .secao-relacionadas {
            margin-top: 32px;
        }

        .secao-relacionadas > h2 {
            font-size: 21px;
        }

        .lista-relacionadas {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px;
        }

        .obra-relacionada {
            min-width: 0;
            padding: 16px;
            background: #ffffff;
            border: 1px solid var(--cor-borda);
            border-radius: 8px;
        }

        .obra-relacionada h3 {
            margin: 0 0 7px;
            font-size: 15px;
            line-height: 1.5;
            overflow-wrap: anywhere;
        }

        .obra-relacionada-autor {
            margin: 0 0 7px;
            color: #687789;
            font-size: 12px;
        }

        .obra-relacionada-descricao {
            margin: 0;
            font-size: 12px;
            line-height: 1.6;
        }

        /* RODAPÉ */

        .rodape {
            margin-top: 35px;
            padding: 24px 20px;
            border-top: 1px solid var(--cor-borda);
            background: #ffffff;
            text-align: center;
            color: #64748b;
            font-size: 12px;
        }

        .rodape a {
            margin: 0 7px;
        }

        @media (max-width: 650px) {
            body {
                font-size: 14px;
            }

            .cabecalho-conteudo {
                align-items: flex-start;
                flex-direction: column;
                padding: 13px 16px;
                gap: 9px;
            }

            .navegacao a {
                margin-left: 0;
                margin-right: 13px;
            }

            .conteudo-principal {
                margin: 16px auto;
                padding: 0 10px;
            }

            .artigo {
                padding: 19px 15px;
            }

            .titulo-obra {
                font-size: 22px;
            }

            .conteudo-obra h2 {
                font-size: 18px;
            }

            .conteudo-obra h3 {
                font-size: 16px;
            }

            .conteudo-obra h4,
            .conteudo-obra h5,
            .conteudo-obra h6 {
                font-size: 15px;
            }

            .conteudo-obra p {
                font-size: 13px;
            }

            .lista-relacionadas {
                grid-template-columns: 1fr;
            }

            .modal-citacao {
                padding: 10px;
            }

            .modal-citacao-conteudo {
                max-height: calc(100vh - 20px);
                padding: 19px 15px;
                border-radius: 10px;
            }

            .modal-citacao-cabecalho h2 {
                font-size: 19px;
            }

            .acoes-citacao {
                flex-direction: column;
            }

            .botao-copiar-citacao,
            .botao-cancelar-citacao {
                width: 100%;
            }
        }
    </style>
    """


# ============================================================
# PÁGINA HTML DE CADA OBRA
# ============================================================

def gerar_pagina_obra(obra, todas_obras):
    obra_id = texto_seguro(
        obra.get("id")
    )

    if not obra_id:
        print("Aviso: obra sem ID ignorada.")
        return False

    if not re.fullmatch(
        r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
        r"[0-9a-fA-F]{12}",
        obra_id
    ):
        print(
            f"Aviso: ID inválido para geração de página: {obra_id}"
        )
        return False

    titulo = limpar_html(
        obra.get("titulo")
    ) or "Obra sem título"

    autor = limpar_html(
        obra.get("autor")
    )

    categoria = limpar_html(
        obra.get("categoria")
    )

    descricao = limpar_html(
        obra.get("descricao")
    )

    conteudo_texto = texto_seguro(
        obra.get("conteudo_texto")
    )

    url = url_obra(obra_id)

    caminho_relativo = (
        OUTPUT_DIR
        / "obra"
        / obra_id
        / "index.html"
    )

    caminho_relativo.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    secoes = obter_secoes(obra_id)
    imagens = obter_imagens(obra_id)

    html_secoes = gerar_html_secoes(secoes)

    # Se não existirem secções, utiliza o conteúdo textual da obra.
    if not html_secoes and conteudo_texto:
        html_secoes = texto_em_paragrafos(
            conteudo_texto
        )

    html_imagens = gerar_html_imagens(
        imagens
    )

    ano = ano_da_obra(obra)

    data_publicacao = data_formatada(
        obra.get("data_publicacao")
    )

    url_pdf = texto_seguro(
        obra.get("url_documento")
    )

    numero_paginas = converter_inteiro(
        obra.get("numero_paginas")
    )

    tamanho_arquivo = formatar_tamanho(
        obra.get("tamanho_arquivo_bytes")
    )

    titulo_html = escapar(titulo)

    descricao_meta = descricao_seo(
        descricao or limpar_html(conteudo_texto) or titulo
    )

    metadados = []

    if autor:
        metadados.append(
            f'<span class="metadado">'
            f'Autor: {escapar(autor)}'
            f"</span>"
        )

    if categoria:
        metadados.append(
            f'<span class="metadado">'
            f'{escapar(categoria)}'
            f"</span>"
        )

    if ano:
        metadados.append(
            f'<span class="metadado">'
            f'Ano: {escapar(ano)}'
            f"</span>"
        )

    if data_publicacao:
        metadados.append(
            f'<span class="metadado">'
            f'Publicado em: {escapar(data_publicacao)}'
            f"</span>"
        )

    html_metadados = "\n".join(
        metadados
    )

    html_descricao = ""

    if descricao:
        html_descricao = (
            f'<div class="descricao-obra">'
            f"<strong>Resumo:</strong> "
            f"{escapar(descricao)}"
            f"</div>"
        )

    informacoes_tecnicas = []

    if numero_paginas > 0:
        informacoes_tecnicas.append(
            f"<p><strong>Número de páginas:</strong> "
            f"{numero_paginas}</p>"
        )

    if tamanho_arquivo:
        informacoes_tecnicas.append(
            f"<p><strong>Tamanho do ficheiro:</strong> "
            f"{escapar(tamanho_arquivo)}</p>"
        )

    if categoria:
        informacoes_tecnicas.append(
            f"<p><strong>Tipo de obra:</strong> "
            f"{escapar(categoria)}</p>"
        )

    html_informacoes = ""

    if informacoes_tecnicas:
        html_informacoes = f"""
        <section class="informacao-tecnica">
            <h2>Informações da obra</h2>
            {"".join(informacoes_tecnicas)}
        </section>
        """

    html_pdf = ""

    if url_pdf:
        url_download = url_pdf_com_nome(
            url_pdf,
            titulo
        )

        html_pdf = f"""
        <section class="secao-pdf">
            <h2>Documento completo</h2>

            <p>
                Consulta ou descarrega o documento PDF
                desta obra académica.
            </p>

            <div class="botoes-pdf">
                <a
                    class="botao-pdf"
                    href="{escapar(url_pdf)}"
                    target="_blank"
                    rel="noopener noreferrer"
                    data-evento-pdf
                >
                    Ler PDF
                </a>

                <a
                    class="botao-pdf"
                    href="{escapar(url_download)}"
                    data-evento-pdf
                >
                    Descarregar PDF
                </a>
            </div>
        </section>
        """

    html_relacionadas = gerar_html_relacionadas(
        obra,
        todas_obras
    )

    html_citacao = gerar_html_botao_citar(
        obra,
        url
    )

    json_ld = gerar_json_ld(
        obra,
        url
    )

    javascript_estatisticas = gerar_javascript_estatisticas(
        obra_id
    )

    data_atualizacao = texto_seguro(
        obra.get("updated_at")
        or obra.get("created_at")
        or obra.get("data_publicacao")
    )

    if not data_atualizacao:
        data_atualizacao = hoje_iso()

    pagina = f"""<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1"
    >

    <title>{titulo_html} | {escapar(NOME_SITE)}</title>

    <meta
        name="description"
        content="{escapar(descricao_meta)}"
    >

    <meta name="robots" content="index, follow">

    <link
        rel="canonical"
        href="{escapar(url)}"
    >

    <meta
        property="og:type"
        content="article"
    >

    <meta
        property="og:title"
        content="{titulo_html}"
    >

    <meta
        property="og:description"
        content="{escapar(descricao_meta)}"
    >

    <meta
        property="og:url"
        content="{escapar(url)}"
    >

    <meta
        property="og:site_name"
        content="{escapar(NOME_SITE)}"
    >

    <meta
        name="twitter:card"
        content="summary"
    >

    <meta
        name="twitter:title"
        content="{titulo_html}"
    >

    <meta
        name="twitter:description"
        content="{escapar(descricao_meta)}"
    >

    <meta
        property="article:modified_time"
        content="{escapar(data_atualizacao)}"
    >

    <script type="application/ld+json">
        {json_ld}
    </script>

    {gerar_css()}
</head>

<body>

    <header class="cabecalho">
        <div class="cabecalho-conteudo">

            <a
                class="marca"
                href="{escapar(url_absoluta(PROJECT_BASE))}"
            >
                {escapar(NOME_SITE)}
            </a>

            <nav class="navegacao" aria-label="Navegação principal">
                <a href="{escapar(url_absoluta(PROJECT_BASE))}">
                    Início
                </a>

                <a href="{escapar(url_absoluta(PROJECT_BASE + 'acervo/'))}">
                    Explorar acervo
                </a>

                <a href="{escapar(url_absoluta(PROJECT_BASE + 'categorias/'))}">
                    Categorias
                </a>
            </nav>

        </div>
    </header>

    <main class="conteudo-principal">

        <article class="artigo">

            <h1 class="titulo-obra">
                {titulo_html}
            </h1>

            <div class="metadados">
                {html_metadados}
            </div>

            {html_descricao}

            {html_citacao}

            <section class="conteudo-obra">
                {html_secoes}
                {html_imagens}
            </section>

            {html_informacoes}

            {html_pdf}

            {html_relacionadas}

        </article>

    </main>

    <footer class="rodape">

        <p>
            © {date.today().year} {escapar(NOME_SITE)}.
            Consulta e disseminação de obras académicas.
        </p>

        <nav aria-label="Links institucionais">
            <a href="{escapar(url_absoluta(PROJECT_BASE + 'termos/'))}">
                Termos de utilização
            </a>

            <a href="{escapar(url_absoluta(PROJECT_BASE + 'politica-privacidade/'))}">
                Política de privacidade
            </a>

            <a href="{escapar(url_absoluta(PROJECT_BASE + 'contacto/'))}">
                Contacto
            </a>
        </nav>

    </footer>

    {javascript_estatisticas}

</body>
</html>
"""

    caminho_relativo.write_text(
        pagina,
        encoding="utf-8"
    )

    print(
        f"Página gerada: {caminho_relativo.relative_to(OUTPUT_DIR)}"
    )

    return True


# ============================================================
# SITEMAP XML
# ============================================================

def gerar_sitemap(obras):
    urlset = ET.Element(
        f"{{{SITEMAP_NS}}}urlset"
    )

    urls_adicionadas = set()

    def adicionar_url(url, lastmod=None):
        if url in urls_adicionadas:
            return

        urls_adicionadas.add(url)

        elemento_url = ET.SubElement(
            urlset,
            f"{{{SITEMAP_NS}}}url"
        )

        elemento_loc = ET.SubElement(
            elemento_url,
            f"{{{SITEMAP_NS}}}loc"
        )

        elemento_loc.text = url

        if lastmod:
            elemento_lastmod = ET.SubElement(
                elemento_url,
                f"{{{SITEMAP_NS}}}lastmod"
            )

            elemento_lastmod.text = lastmod

    # Páginas fixas.
    for caminho in URLS_FIXAS:
        adicionar_url(
            url_absoluta(caminho),
            hoje_iso()
        )

    # Páginas individuais das obras.
    for obra in obras:
        obra_id = texto_seguro(
            obra.get("id")
        )

        if not obra_id:
            continue

        url = url_obra(obra_id)

        data = (
            obra.get("updated_at")
            or obra.get("created_at")
            or obra.get("data_publicacao")
        )

        data_convertida = converter_data(data)

        if data_convertida:
            lastmod = data_convertida.date().isoformat()
        else:
            lastmod = hoje_iso()

        adicionar_url(
            url,
            lastmod
        )

    arvore = ET.ElementTree(
        urlset
    )

    try:
        ET.indent(
            arvore,
            space="  ",
            level=0
        )
    except AttributeError:
        pass

    SITEMAP_PATH.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    arvore.write(
        SITEMAP_PATH,
        encoding="utf-8",
        xml_declaration=True
    )

    print(
        f"Sitemap gerado: {SITEMAP_PATH}"
    )

    print(
        f"URLs no sitemap: {len(urls_adicionadas)}"
    )


# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================

def main():
    print("=" * 65)
    print("GERADOR DE PÁGINAS SEO — OBRA LIVRE")
    print("=" * 65)

    procurar_configuracao_supabase()

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Não foi possível encontrar a configuração pública "
            "do Supabase.\n"
            "Define as variáveis SUPABASE_URL e SUPABASE_ANON_KEY "
            "ou verifica a configuração nos ficheiros Dart."
        )

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    print()
    print(f"Base do projeto: {BASE_DIR}")
    print(f"Diretório de saída: {OUTPUT_DIR}")
    print(f"URL do site: {BASE_URL}")
    print()
    print("A consultar obras no Supabase...")

    obras = obter_obras()

    print(
        f"Obras encontradas: {len(obras)}"
    )

    paginas_geradas = 0
    paginas_ignoradas = 0

    for obra in obras:
        try:
            resultado = gerar_pagina_obra(
                obra,
                obras
            )

            if resultado:
                paginas_geradas += 1
            else:
                paginas_ignoradas += 1

        except Exception as erro:
            paginas_ignoradas += 1

            print(
                "Erro ao gerar página da obra "
                f"{texto_seguro(obra.get('id'))}: {erro}"
            )

    gerar_sitemap(obras)

    print()
    print("=" * 65)
    print("PROCESSO CONCLUÍDO")
    print("=" * 65)
    print(f"Total de obras: {len(obras)}")
    print(f"Páginas geradas: {paginas_geradas}")
    print(f"Páginas ignoradas ou com erro: {paginas_ignoradas}")
    print(f"Sitemap: {SITEMAP_PATH}")
    print()
    print("Funcionalidades incluídas:")
    print("- Páginas HTML individuais para SEO")
    print("- Metadados e dados estruturados JSON-LD")
    print("- Sitemap XML")
    print("- Secções e imagens das obras")
    print("- Obras relacionadas")
    print("- Botões para ler e descarregar PDFs")
    print("- Registo de visualizações e cliques no PDF")
    print("- Botão Citar")
    print("- Citações APA 7, ABNT, Vancouver e ISO 690")
    print("- Janela de citação adaptada a telemóveis")
    print("- Cópia da referência bibliográfica")


if __name__ == "__main__":
    try:
        main()

    except KeyboardInterrupt:
        print(
            "\nProcesso interrompido pelo utilizador.",
            file=sys.stderr
        )

        sys.exit(130)

    except Exception as erro:
        print(
            f"\nERRO FATAL: {erro}",
            file=sys.stderr
        )

        sys.exit(1)
