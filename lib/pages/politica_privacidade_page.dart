

import 'package:flutter/material.dart';

class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: const [
                Text(
                  'Política de Privacidade — Obra Livre',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '1. Introdução',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'A Obra Livre é uma plataforma destinada à disponibilização, '
                      'consulta e partilha de trabalhos académicos e científicos. '
                      'Esta Política de Privacidade explica como as informações dos '
                      'utilizadores são tratadas quando utilizam a plataforma.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '2. Informações recolhidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Quando o utilizador cria uma conta, podemos recolher informações '
                      'necessárias para o funcionamento da plataforma, como nome, '
                      'endereço de e-mail e informações relacionadas com o perfil.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '3. Login com Google',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'O Obra Livre pode permitir o acesso através da conta Google. '
                      'Quando esta opção é utilizada, determinadas informações básicas '
                      'da conta Google podem ser disponibilizadas à plataforma para '
                      'criação e autenticação da conta do utilizador.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '4. Utilização das informações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'As informações recolhidas são utilizadas para autenticação, '
                      'gestão das contas, funcionamento dos serviços e melhoria da '
                      'experiência dos utilizadores.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '5. Proteção das informações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Adotamos medidas razoáveis para proteger as informações dos '
                      'utilizadores contra acesso, alteração ou divulgação não autorizada.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  '6. Contacto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Para questões relacionadas com esta Política de Privacidade, '
                      'o utilizador poderá contactar a equipa responsável pelo Obra Livre.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 32),

                Text(
                  'Última atualização: Setembro de 2026',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

