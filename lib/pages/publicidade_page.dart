import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicidadePage extends StatefulWidget {
  const PublicidadePage({super.key});

  @override
  State<PublicidadePage> createState() => _PublicidadePageState();
}

class _PublicidadePageState extends State<PublicidadePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _assuntoController =
  TextEditingController();

  final TextEditingController _mensagemController =
  TextEditingController();

  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _assuntoController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensagem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'enviar-email-contacto',
        body: {
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'assunto': _assuntoController.text.trim(),
          'mensagem': _mensagemController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.status >= 200 && response.status < 300) {
        _nomeController.clear();
        _emailController.clear();
        _assuntoController.clear();
        _mensagemController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mensagem enviada com sucesso. '
                  'Entraremos em contacto consigo.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(
          'A função devolveu o estado ${response.status}.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível enviar a mensagem. '
                'Tente novamente dentro de instantes.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FF),
        elevation: 0,
        surfaceTintColor: const Color(0xFFEAF4FF),
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: 28,

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD5E5F5),
          ),
        ),

        title: GestureDetector(
          onTap: () {
            Navigator.of(context).popUntil(
                  (route) => route.isFirst,
            );
          },
          child: const Text(
            'Obra Livre',
            style: TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 52,
                      color: Color(0xFF333333),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Anuncie na Obra Livre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Divulgue a sua empresa, serviço, '
                          'projecto ou iniciativa '
                          'para uma comunidade interessada em '
                          'conhecimento, educação, ciência e '
                          'produção académica.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF666666),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 42),

                    _buildCartao(
                      icon: Icons.visibility_outlined,
                      titulo: 'Aumente a visibilidade',
                      texto:
                      'Apresente a sua marca a visitantes '
                          'e utilizadores da plataforma '
                          'Obra Livre.',
                    ),

                    const SizedBox(height: 14),

                    _buildCartao(
                      icon: Icons.public_outlined,
                      titulo:
                      'Alcance um público académico',
                      texto:
                      'Divulgue produtos, serviços, eventos '
                          'e projectos relacionados com educação, '
                          'ciência e conhecimento.',
                    ),

                    const SizedBox(height: 14),

                    _buildCartao(
                      icon: Icons.ads_click_outlined,
                      titulo:
                      'Publicidade na plataforma',
                      texto:
                      'Escolha uma solução de publicidade '
                          'adequada à sua necessidade.',
                    ),

                    const SizedBox(height: 42),

                    _buildFormularioContacto(),

                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 24,
              ),
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Obra Livre — Obras Académicas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioContacto() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E4E7),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Tem interesse em anunciar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'Preencha o formulário e entre em contacto '
                    'com a equipa da Obra Livre.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 28),

            _buildCampo(
              controller: _nomeController,
              label: 'Nome',
              hint: 'Digite o seu nome',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Digite o seu nome.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCampo(
              controller: _emailController,
              label: 'Email',
              hint: 'exemplo@email.com',
              icon: Icons.email_outlined,
              keyboardType:
              TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Digite o seu email.';
                }

                final emailRegex = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                );

                if (!emailRegex.hasMatch(
                  value.trim(),
                )) {
                  return 'Digite um email válido.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCampo(
              controller: _assuntoController,
              label: 'Assunto',
              hint: 'Interesse em publicidade',
              icon: Icons.subject_outlined,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Digite o assunto.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCampo(
              controller: _mensagemController,
              label: 'Mensagem',
              hint: 'Escreva a sua mensagem...',
              icon: Icons.message_outlined,
              keyboardType:
              TextInputType.multiline,
              maxLines: 6,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Digite a sua mensagem.';
                }

                if (value.trim().length < 10) {
                  return 'A mensagem é muito curta.';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                _enviando ? null : _enviarMensagem,

                icon: _enviando
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.send_outlined,
                ),

                label: Text(
                  _enviando
                      ? 'A enviar...'
                      : 'Enviar mensagem',
                ),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF222222),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  const Color(0xFF777777),
                  disabledForegroundColor:
                  Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text(
                'A sua mensagem será tratada pela equipa '
                    'da Obra Livre.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: const Color(0xFF666666),
        ),

        filled: true,
        fillColor: const Color(0xFFFAFAFA),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E7),
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E7),
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF333333),
            width: 1.2,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _buildCartao({
    required IconData icon,
    required String titulo,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE1E4E7),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius:
              BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF333333),
              size: 23,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF222222),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    color:
                    Color(0xFF777777),
                    height: 1.5,
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
