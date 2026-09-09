
import 'package:flutter/material.dart';

class CookiesPage extends StatelessWidget {
  const CookiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Cookies'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Política de Cookies',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Última atualização: setembro de 2026',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                _secao(
                  context,
                  '1. O que são cookies',
                  'Cookies são pequenos ficheiros ou tecnologias semelhantes '
                      'que podem ser utilizados por websites e aplicações para '
                      'guardar ou consultar determinadas informações no dispositivo '
                      'do utilizador.',
                ),

                _secao(
                  context,
                  '2. Como a Obra Livre pode utilizar cookies',
                  'A plataforma poderá utilizar cookies ou tecnologias semelhantes '
                      'para manter determinadas funcionalidades, melhorar a experiência '
                      'de utilização e compreender como os utilizadores interagem '
                      'com a plataforma.',
                ),

                _secao(
                  context,
                  '3. Cookies necessários',
                  'Algumas tecnologias podem ser necessárias para o funcionamento '
                      'da plataforma, incluindo funcionalidades relacionadas com '
                      'sessão, autenticação, segurança e preferências.',
                ),

                _secao(
                  context,
                  '4. Cookies de preferência',
                  'Quando utilizados, estes recursos podem ajudar a guardar '
                      'determinadas preferências do utilizador e proporcionar '
                      'uma experiência mais adequada nas visitas seguintes.',
                ),

                _secao(
                  context,
                  '5. Serviços de terceiros',
                  'Alguns serviços externos integrados na plataforma poderão '
                      'utilizar cookies ou tecnologias semelhantes de acordo com '
                      'as suas próprias políticas. Esses serviços podem incluir '
                      'ferramentas de análise ou publicidade, quando aplicáveis.',
                ),

                _secao(
                  context,
                  '6. Gestão de cookies',
                  'O utilizador pode, dependendo do navegador utilizado, controlar '
                      'ou eliminar cookies através das respetivas definições. '
                      'A desativação de determinados cookies poderá afetar algumas '
                      'funcionalidades da plataforma.',
                ),

                _secao(
                  context,
                  '7. Alterações a esta política',
                  'Esta Política de Cookies poderá ser atualizada sempre que '
                      'necessário para refletir alterações nas funcionalidades '
                      'da plataforma ou nos serviços utilizados. A versão mais '
                      'recente estará disponível nesta página.',
                ),

                const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

