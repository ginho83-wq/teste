import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ============================================================
  // CONTROLADORES
  // ============================================================

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _senhaController =
  TextEditingController();

  // ============================================================
  // ESTADO
  // ============================================================

  bool _carregando = false;
  bool _mostrarSenha = false;

  // Controla se os campos de email e palavra-passe aparecem.
  bool _mostrarFormulario = false;

  // ============================================================
  // LOGIN COM EMAIL E PALAVRA-PASSE
  // ============================================================

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem(
        'Preencha o email e a palavra-passe.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia.entrarComEmail(
        email: email,
        senha: senha,
      );

      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);
    } catch (e) {
      _mostrarMensagem('Erro ao entrar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // LOGIN COM GOOGLE
  // ============================================================

  Future<void> _entrarGoogle() async {
    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia.entrarComGoogle();

      // O Google redireciona para /auth/callback.
      // O GoRouter trata a sessão e encaminha para a página principal.
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    } catch (e) {
      _mostrarMensagem(
        'Erro ao entrar com Google: $e',
      );

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // ABRIR FORMULÁRIO DE LOGIN
  // ============================================================

  void _abrirFormularioLogin() {
    if (_carregando) return;

    setState(() {
      _mostrarFormulario = true;
    });
  }

  // ============================================================
  // MENU PLATAFORMA
  // ============================================================

  Widget _menuPlataforma() {
    return PopupMenuButton<String>(
      enabled: !_carregando,
      tooltip: 'Plataforma',
      offset: const Offset(0, 45),
      onSelected: (valor) {
        switch (valor) {
          case 'inicio':
            context.go('/');
            break;

          case 'acervo':
            context.push('/acervo');
            break;

          case 'pesquisar':
            context.push('/acervo');
            break;

          case 'publicar':
            context.push('/publicar');
            break;

          case 'sobre':
            context.push('/sobre');
            break;

          case 'contacto':
            context.push('/contacto');
            break;

          case 'termos':
            context.push('/termos');
            break;

          case 'privacidade':
            context.push('/politica-privacidade');
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'inicio',
          child: Text('Início'),
        ),
        PopupMenuItem<String>(
          value: 'acervo',
          child: Text('Acervo'),
        ),
        PopupMenuItem<String>(
          value: 'pesquisar',
          child: Text('Pesquisar obras'),
        ),
        PopupMenuItem<String>(
          value: 'publicar',
          child: Text('Publicar uma obra'),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'sobre',
          child: Text('Sobre a plataforma'),
        ),
        PopupMenuItem<String>(
          value: 'contacto',
          child: Text('Contacto'),
        ),
        PopupMenuItem<String>(
          value: 'termos',
          child: Text('Termos de Uso'),
        ),
        PopupMenuItem<String>(
          value: 'privacidade',
          child: Text('Política de Privacidade'),
        ),
      ],
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Plataforma'),
          SizedBox(width: 3),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  // ============================================================
  // LINKS DO RODAPÉ
  // ============================================================

  Widget _linkRodape(
      BuildContext context,
      String texto,
      String rota,
      ) {
    return TextButton(
      onPressed: _carregando
          ? null
          : () {
        context.push(rota);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 4,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _separadorRodape() {
    return Text(
      '•',
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 12,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // NOME DO SITE — CANTO SUPERIOR ESQUERDO
            // ==================================================

            Positioned(
              top: 16,
              left: 20,
              child: Text(
                'Teste',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // ==================================================
            // PLATAFORMA + ENTRAR + CRIAR CONTA
            // CANTO SUPERIOR DIREITO
            // ==================================================

            Positioned(
              top: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PLATAFORMA
                  _menuPlataforma(),

                  // ENTRAR
                  TextButton(
                    onPressed: _carregando
                        ? null
                        : _abrirFormularioLogin,
                    child: const Text('Entrar'),
                  ),

                  // CRIAR CONTA
                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () {
                      context.go('/cadastro');
                    },
                    child: const Text('Criar conta'),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTEÚDO CENTRAL
            // ==================================================

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: _mostrarFormulario
                        ? _buildFormularioLogin(theme)
                        : _buildLoginInicial(theme),
                  ),
                ),
              ),
            ),

            // ==================================================
            // LINKS INSTITUCIONAIS — CANTO INFERIOR DIREITO
            // ==================================================

            Positioned(
              right: 20,
              bottom: 14,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment:
                WrapCrossAlignment.center,
                children: [
                  _linkRodape(
                    context,
                    'Contacto',
                    '/contacto',
                  ),
                  _separadorRodape(),
                  _linkRodape(
                    context,
                    'Termos',
                    '/termos',
                  ),
                  _separadorRodape(),
                  _linkRodape(
                    context,
                    'Privacidade',
                    '/politica-privacidade',
                  ),
                  _separadorRodape(),
                  _linkRodape(
                    context,
                    'Ajuda',
                    '/ajuda',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TELA INICIAL
  // ============================================================

  Widget _buildLoginInicial(ThemeData theme) {
    return Column(
      key: const ValueKey('inicio'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Explore, consulte e publique obras académicas e conteúdos de conhecimento.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORMULÁRIO DE LOGIN
  // ============================================================

  Widget _buildFormularioLogin(ThemeData theme) {
    return Column(
      key: const ValueKey('formulario'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // ==================================================
        // EMAIL
        // ==================================================

        TextField(
          controller: _emailController,
          keyboardType:
          TextInputType.emailAddress,
          textInputAction:
          TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.email_outlined,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ==================================================
        // PALAVRA-PASSE
        // ==================================================

        TextField(
          controller: _senhaController,
          obscureText: !_mostrarSenha,
          textInputAction:
          TextInputAction.done,
          onSubmitted: (_) {
            if (!_carregando) {
              _entrar();
            }
          },
          decoration: InputDecoration(
            labelText: 'Palavra-passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(
              Icons.lock_outline,
            ),
            suffixIcon: IconButton(
              onPressed: _carregando
                  ? null
                  : () {
                setState(() {
                  _mostrarSenha =
                  !_mostrarSenha;
                });
              },
              icon: Icon(
                _mostrarSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ==================================================
        // BOTÃO ENTRAR
        // ==================================================

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _carregando
                ? null
                : _entrar,
            child: _carregando
                ? const SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Entrar',
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ==================================================
        // BOTÃO CONTINUAR COM GOOGLE
        // ==================================================

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _carregando
                ? null
                : _entrarGoogle,
            icon: const Icon(
              Icons.login,
            ),
            label: const Text(
              'Continuar com Google',
            ),
          ),
        ),
      ],
    );
  }
}

