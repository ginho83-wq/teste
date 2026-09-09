
import 'package:flutter/material.dart';

class ContactoPage extends StatelessWidget {
  const ContactoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
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
                  'Contacto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estamos disponíveis para receber questões, sugestões e comunicações relacionadas com a plataforma.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                _cartao(
                  context,
                  icone: Icons.help_outline,
                  titulo: 'Dúvidas e sugestões',
                  texto:
                  'Para questões relacionadas com a utilização da Obra Livre, '
                      'funcionalidades ou sugestões de melhoria, utilize o canal '
                      'de contacto disponibilizado pela plataforma.',
                ),

                const SizedBox(height: 16),

                _cartao(
                  context,
                  icone: Icons.report_problem_outlined,
                  titulo: 'Denúncias e pedidos de remoção',
                  texto:
                  'Para comunicar problemas relacionados com uma obra publicada, '
                      'direitos de autor, autoria ou outras situações relevantes, '
                      'utilize as funcionalidades de denúncia e pedido de remoção '
                      'disponíveis na plataforma.',
                ),

                const SizedBox(height: 16),

                _cartao(
                  context,
                  icone: Icons.business_outlined,
                  titulo: 'Informações gerais',
                  texto:
                  'Para outras questões relacionadas com a Obra Livre, '
                      'entre em contacto através do canal oficial disponibilizado '
                      'pela plataforma.',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartao(
      BuildContext context, {
        required IconData icone,
        required String titulo,
        required String texto,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texto,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

