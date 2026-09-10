import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool _notificacoesPublicacoes = true;
  bool _notificacoesConta = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Configurações'),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              48,
            ),
            children: [
              const Text(
                'Preferências',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Gerencie as preferências da sua conta no Obra Livre.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 32),

              _buildSecao(
                titulo: 'Notificações',
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Novas publicações',
                    ),
                    subtitle: const Text(
                      'Receber informações sobre novas obras disponíveis.',
                    ),
                    value: _notificacoesPublicacoes,
                    onChanged: (valor) {
                      setState(() {
                        _notificacoesPublicacoes = valor;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Atualizações da conta',
                    ),
                    subtitle: const Text(
                      'Receber informações importantes sobre a sua conta.',
                    ),
                    value: _notificacoesConta,
                    onChanged: (valor) {
                      setState(() {
                        _notificacoesConta = valor;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _buildSecao(
                titulo: 'Privacidade',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                    ),
                    title: const Text(
                      'Política de privacidade',
                    ),
                    subtitle: const Text(
                      'Consulte como os seus dados são tratados.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push('/politica-privacidade');
                    },
                  ),

                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.description_outlined,
                    ),
                    title: const Text(
                      'Termos de utilização',
                    ),
                    subtitle: const Text(
                      'Consulte os termos de utilização do Obra Livre.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push('/termos');
                    },
                  ),

                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.cookie_outlined,
                    ),
                    title: const Text(
                      'Política de cookies',
                    ),
                    subtitle: const Text(
                      'Consulte informações sobre cookies.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push('/cookies');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _buildSecao(
                titulo: 'Sobre',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.info_outline,
                    ),
                    title: const Text(
                      'Sobre o Obra Livre',
                    ),
                    subtitle: const Text(
                      'Informações sobre a plataforma.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push('/contacto');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
