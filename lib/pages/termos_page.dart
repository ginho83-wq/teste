
import 'package:flutter/material.dart';

class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Utilização'),
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
                  'Termos de Utilização',
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
                  '1. Aceitação dos termos',
                  'Ao utilizar a plataforma Obra Livre, o utilizador concorda '
                      'com estes Termos de Utilização. Caso não concorde com '
                      'alguma disposição, deverá deixar de utilizar a plataforma.',
                ),

                _secao(
                  context,
                  '2. Utilização da plataforma',
                  'A Obra Livre disponibiliza uma plataforma destinada à '
                      'consulta, publicação e organização de trabalhos académicos '
                      'e científicos. O utilizador compromete-se a utilizar a '
                      'plataforma de forma responsável e de acordo com a legislação aplicável.',
                ),

                _secao(
                  context,
                  '3. Conta do utilizador',
                  'Algumas funcionalidades podem exigir uma conta. O utilizador '
                      'é responsável pelas informações fornecidas e pela utilização '
                      'da sua conta. As informações devem ser verdadeiras, atuais '
                      'e utilizadas de forma adequada.',
                ),

                _secao(
                  context,
                  '4. Publicação de trabalhos',
                  'O utilizador que submete um trabalho para publicação declara '
                      'que possui autorização para disponibilizar o conteúdo ou '
                      'que tem os direitos necessários para a sua utilização. '
                      'A submissão de um trabalho não transfere automaticamente '
                      'a propriedade intelectual do conteúdo para a Obra Livre.',
                ),

                _secao(
                  context,
                  '5. Direitos de autor',
                  'Os autores mantêm os direitos que lhes sejam legalmente '
                      'atribuídos sobre os seus trabalhos. Não é permitida a '
                      'publicação de conteúdo que viole direitos de autor, '
                      'direitos de terceiros ou outras normas aplicáveis.',
                ),

                _secao(
                  context,
                  '6. Conteúdo e moderação',
                  'A Obra Livre poderá analisar trabalhos submetidos e, quando '
                      'necessário, recusar, remover ou restringir o acesso a '
                      'conteúdos que violem estes termos, apresentem informações '
                      'inadequadas ou sejam objeto de uma denúncia fundamentada.',
                ),

                _secao(
                  context,
                  '7. Denúncias e pedidos de remoção',
                  'A plataforma disponibiliza mecanismos para comunicação de '
                      'conteúdos que possam apresentar problemas relacionados '
                      'com direitos de autor, autoria, informações incorretas '
                      'ou outras situações relevantes. As solicitações poderão '
                      'ser analisadas pela equipa responsável.',
                ),

                _secao(
                  context,
                  '8. Disponibilidade do serviço',
                  'A Obra Livre procura manter a plataforma disponível e funcional, '
                      'mas poderão ocorrer interrupções decorrentes de manutenção, '
                      'atualizações, problemas técnicos ou circunstâncias fora do '
                      'controlo da plataforma.',
                ),

                _secao(
                  context,
                  '9. Alterações aos termos',
                  'Estes Termos de Utilização poderão ser atualizados para refletir '
                      'alterações na plataforma, nos seus serviços ou nas regras aplicáveis. '
                      'A versão mais recente será disponibilizada nesta página.',
                ),

                _secao(
                  context,
                  '10. Contacto',
                  'Para questões relacionadas com estes termos ou com a utilização '
                      'da plataforma, utilize o canal de contacto disponibilizado '
                      'pela Obra Livre.',
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
