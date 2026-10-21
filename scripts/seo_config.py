"""Configuração central do gerador SEO da Obra Livre."""
from pathlib import Path

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

COR_PRIMARIA = "#174A7E"

COR_PRIMARIA_ESCURO = "#103456"

COR_SECUNDARIA = "#1769AA"

COR_FUNDO = "#F4F7FB"

COR_CARTAO = "#FFFFFF"

COR_TEXTO = "#263445"

COR_TEXTO_SECUNDARIO = "#64748B"

COR_BORDA = "#E2E8F0"

COR_SUCESSO = "#16794B"


