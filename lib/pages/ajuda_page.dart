import 'package:flutter/material.dart';

class AjudaPage extends StatelessWidget {
  const AjudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajuda',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Encontre respostas para as principais dúvidas '
                      'sobre a utilização da plataforma.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                _secao(
                  context,
                  'Como criar uma conta?',
                  'Selecione "Criar conta" na tela de login '
                      'e preencha os dados solicitados.',
                ),

                _secao(
                  context,
                  'Como entrar na plataforma?',
                  'Pode entrar utilizando o seu email e '
                      'palavra-passe ou através da opção '
                      '"Continuar com Google".',
                ),

                _secao(
                  context,
                  'Como consultar uma obra?',
                  'Depois de entrar na plataforma, utilize '
                      'a pesquisa ou navegue pelo Acervo para '
                      'encontrar as obras disponíveis.',
                ),

                _secao(
                  context,
                  'Como publicar uma obra?',
                  'Depois de iniciar sessão, utilize a opção '
                      '"Publicar" para submeter uma obra para análise.',
                ),

                _secao(
                  context,
                  'Precisa de mais ajuda?',
                  'Entre na página de Contacto para enviar '
                      'uma questão ou comunicação à equipa '
                      'responsável pela plataforma.',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secao(
      BuildContext context,
      String titulo,
      String texto,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

