from pathlib import Path

ficheiro = Path(r"D:\teste\scripts\seo_html.py")
codigo = ficheiro.read_text(encoding="utf-8")

substituicoes = {
    '''                WhatsApp
            </a>''': '''                <img class="icone-partilha" src="https://cdn.simpleicons.org/whatsapp" alt="" />
                WhatsApp
            </a>''',

    '''                Facebook
            </a>''': '''                <img class="icone-partilha" src="https://cdn.simpleicons.org/facebook" alt="" />
                Facebook
            </a>''',

    '''                LinkedIn
            </a>''': '''                <img class="icone-partilha" src="https://cdn.simpleicons.org/linkedin" alt="" />
                LinkedIn
            </a>''',

    '''                Telegram
            </a>''': '''                <img class="icone-partilha" src="https://cdn.simpleicons.org/telegram" alt="" />
                Telegram
            </a>''',
}

for antigo, novo in substituicoes.items():
    if antigo not in codigo:
        print("ATENÇÃO: trecho não encontrado:", antigo.strip())
    else:
        codigo = codigo.replace(antigo, novo, 1)
        print("Ícone atualizado:", antigo.strip().splitlines()[0])

marcador = '''            <button
                class="botao-partilha"
                type="button"
                onclick="copiarLinkObra()"'''

botao_x = '''            <a
                class="botao-partilha"
                href="https://twitter.com/intent/tweet?url={urllib.parse.quote(endereco, safe='')}&text={urllib.parse.quote(titulo, safe='')}"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Partilhar no X (Twitter)"
            >
                <img class="icone-partilha" src="https://cdn.simpleicons.org/x" alt="" />
                X
            </a>

'''

if marcador in codigo:
    if 'aria-label="Partilhar no X (Twitter)"' not in codigo:
        codigo = codigo.replace(marcador, botao_x + marcador, 1)
        print("Botão X (Twitter) adicionado.")
    else:
        print("O botão X já existe.")
else:
    print("ATENÇÃO: não foi possível localizar o botão Copiar link.")

ficheiro.write_text(codigo, encoding="utf-8")
print("Alteração guardada em seo_html.py")
