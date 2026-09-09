import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Supabase.instance.client.auth.currentUser;
    final metadata = usuario?.userMetadata;

    // ============================================================
    // FOTO DO USUÁRIO
    // ============================================================

    final fotoUrl =
        metadata?['avatar_url'] ??
            metadata?['picture'] ??
            metadata?['photo_url'];

    final nome =
        metadata?['full_name'] ??
            metadata?['name'] ??
            usuario?.email?.split('@').first ??
            'Utilizador';

    final temFoto =
        fotoUrl != null &&
            fotoUrl.toString().trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
        Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 0,

        // ========================================================
        // LOGO / NOME
        // ========================================================

        title: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.only(
                left: constraints.maxWidth < 600 ? 12 : 24,
              ),
              child: const Text(
                'Obra Livre',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            );
          },
        ),

        actions: [
          // ======================================================
          // PUBLICAÇÕES GERAIS
          // ======================================================

          _HeaderButton(
            label: 'Publicações',
            onPressed: () {
              // TODO: navegar para publicações gerais
            },
          ),

          const SizedBox(width: 2),

          // ======================================================
          // PUBLICAR
          // ======================================================

          _HeaderButton(
            label: 'Publicar',
            onPressed: () {
              // TODO: navegar para publicar obra
            },
            fontWeight: FontWeight.w600,
          ),

          // ======================================================
          // SEPARADOR
          // ======================================================

          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.6),
          ),

          // ======================================================
          // AVATAR / MENU DO USUÁRIO
          // ======================================================

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              tooltip: 'Conta',
              offset: const Offset(0, 10),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              elevation: 8,

              onSelected: (valor) async {
                // ------------------------------------------------
                // MINHAS PUBLICAÇÕES
                // ------------------------------------------------

                if (valor == 'minhas_publicacoes') {
                  // TODO:
                  // navegar para a página das publicações
                  // pertencentes ao usuário autenticado
                }

                // ------------------------------------------------
                // CONFIGURAÇÕES
                // ------------------------------------------------

                if (valor == 'configuracoes') {
                  // TODO: navegar para configurações
                }

                // ------------------------------------------------
                // SAIR
                // ------------------------------------------------

                if (valor == 'sair') {
                  await AuthService.instancia.sair();
                }
              },

              itemBuilder: (context) => [
                // ==================================================
                // CABEÇALHO DO USUÁRIO
                // ==================================================

                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: temFoto
                            ? NetworkImage(
                          fotoUrl.toString(),
                        )
                            : null,
                        child: !temFoto
                            ? const Icon(
                          Icons.person_outline,
                        )
                            : null,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome.toString(),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              usuario?.email ?? '',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                // ==================================================
                // MINHAS PUBLICAÇÕES
                // ==================================================

                const PopupMenuItem<String>(
                  value: 'minhas_publicacoes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                      ),
                      SizedBox(width: 12),
                      Text('Minhas publicações'),
                    ],
                  ),
                ),

                // ==================================================
                // CONFIGURAÇÕES
                // ==================================================

                const PopupMenuItem<String>(
                  value: 'configuracoes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                      ),
                      SizedBox(width: 12),
                      Text('Configurações'),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                // ==================================================
                // SAIR
                // ==================================================

                const PopupMenuItem<String>(
                  value: 'sair',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Sair'),
                    ],
                  ),
                ),
              ],

              // ====================================================
              // AVATAR
              // ====================================================

              child: CircleAvatar(
                radius: 20,
                backgroundImage: temFoto
                    ? NetworkImage(
                  fotoUrl.toString(),
                )
                    : null,
                child: !temFoto
                    ? const Icon(
                  Icons.person_outline,
                )
                    : null,
              ),
            ),
          ),
        ],
      ),

      // ==========================================================
      // HOME
      // ==========================================================

      body: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;

          final bool celular = largura < 600;

          final bool tablet =
              largura >= 600 && largura < 1000;

          final double margemHorizontal = celular
              ? 16
              : tablet
              ? 32
              : 64;

          final double larguraConteudo = largura > 1200
              ? 1100
              : largura -
              (margemHorizontal * 2);

          return SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: larguraConteudo,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: celular ? 0 : 8,
                    vertical: 28,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                    children: [
                      // ==================================================
                      // ÁREA PRINCIPAL
                      // ==================================================

                      const SizedBox(height: 12),

                      Text(
                        'Encontre uma obra para consultar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: celular ? 27 : 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Pesquise por título, autor ou palavra-chave.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: celular ? 14 : 16,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // PESQUISA
                      // ==================================================

                      Center(
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 720,
                          ),

                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                              'Pesquisar obras, autores ou palavras-chave...',

                              prefixIcon:
                              const Icon(
                                Icons.search,
                              ),

                              suffixIcon:
                              IconButton(
                                tooltip: 'Pesquisar',
                                onPressed: () {
                                  // TODO:
                                  // executar pesquisa
                                },
                                icon: const Icon(
                                  Icons.arrow_forward,
                                ),
                              ),

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  28,
                                ),
                              ),

                              enabledBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  28,
                                ),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .dividerColor,
                                ),
                              ),

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ==================================================
                      // CATEGORIAS
                      // ==================================================

                      SizedBox(
                        height: 40,

                        child: ListView(
                          scrollDirection:
                          Axis.horizontal,

                          children: const [
                            _CategoriaTexto(
                              titulo:
                              'Teses de Doutoramento',
                            ),

                            _CategoriaTexto(
                              titulo:
                              'Dissertações de Mestrado',
                            ),

                            _CategoriaTexto(
                              titulo: 'Monografias',
                            ),

                            _CategoriaTexto(
                              titulo:
                              'Artigos Científicos',
                            ),

                            _CategoriaTexto(
                              titulo: 'Literatura',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 42),

                      // ==================================================
                      // PUBLICAÇÕES RECENTES
                      // ==================================================

                      const _SectionTitle(
                        titulo:
                        'Publicações recentes',
                      ),

                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: celular
                            ? 1
                            : tablet
                            ? 2
                            : 3,

                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,

                        childAspectRatio: celular
                            ? 2.3
                            : 1.55,

                        shrinkWrap: true,

                        physics:
                        const NeverScrollableScrollPhysics(),

                        children: const [
                          _ObraCard(
                            titulo:
                            'Título da obra publicada',
                            autor: 'Nome do autor',
                            categoria: 'Monografia',
                            ano: '2026',
                          ),

                          _ObraCard(
                            titulo:
                            'Título da segunda obra',
                            autor: 'Nome do autor',
                            categoria:
                            'Artigo Científico',
                            ano: '2026',
                          ),

                          _ObraCard(
                            titulo:
                            'Título da terceira obra',
                            autor: 'Nome do autor',
                            categoria:
                            'Dissertação de Mestrado',
                            ano: '2026',
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // ==================================================
                      // CONSULTADOS RECENTEMENTE
                      // ==================================================

                      const _SectionTitle(
                        titulo:
                        'Consultados recentemente',
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 34,
                        ),

                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .dividerColor,
                          ),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 34,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'As obras que consultar aparecerão aqui.',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'O seu histórico de consultas será apresentado nesta área.',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 56),

                      // ==================================================
                      // RODAPÉ
                      // ==================================================

                      const Divider(),

                      const SizedBox(height: 22),

                      Wrap(
                        alignment:
                        WrapAlignment.center,

                        spacing: 24,
                        runSpacing: 12,

                        children: const [
                          _FooterLink(
                            titulo:
                            'Sobre o Obra Livre',
                          ),

                          _FooterLink(
                            titulo: 'Como publicar',
                          ),

                          _FooterLink(
                            titulo: 'Contacto',
                          ),

                          _FooterLink(
                            titulo:
                            'Termos de utilização',
                          ),

                          _FooterLink(
                            titulo:
                            'Política de privacidade',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        '© ${DateTime.now().year} Obra Livre',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ======================================================================
// TÍTULO DE SEÇÃO
// ======================================================================

class _SectionTitle extends StatelessWidget {
  final String titulo;

  const _SectionTitle({
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ======================================================================
// CATEGORIA — APENAS TEXTO
// ======================================================================

class _CategoriaTexto extends StatelessWidget {
  final String titulo;

  const _CategoriaTexto({
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(right: 28),

      child: InkWell(
        onTap: () {
          // TODO:
          // navegar para a categoria
        },

        child: Center(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// CARTÃO DA OBRA
// ======================================================================

class _ObraCard extends StatelessWidget {
  final String titulo;
  final String autor;
  final String categoria;
  final String ano;

  const _ObraCard({
    required this.titulo,
    required this.autor,
    required this.categoria,
    required this.ano,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),

        side: BorderSide(
          color: Theme.of(context)
              .dividerColor,
        ),
      ),

      child: InkWell(
        onTap: () {
          // TODO:
          // abrir detalhes da obra
        },

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 22,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      categoria,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ),

                  Text(
                    ano,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                titulo,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                autor,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// LINK DO RODAPÉ
// ======================================================================

class _FooterLink extends StatelessWidget {
  final String titulo;

  const _FooterLink({
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO:
        // navegar para a página correspondente
      },

      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color,
        ),
      ),
    );
  }
}

// ======================================================================
// BOTÃO DO CABEÇALHO — SEM QUADRO
// ======================================================================

class _HeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final FontWeight fontWeight;

  const _HeaderButton({
    required this.label,
    required this.onPressed,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,

      style: TextButton.styleFrom(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),

        minimumSize: Size.zero,

        tapTargetSize:
        MaterialTapTargetSize.shrinkWrap,

        shape:
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),

      child: Text(
        label,
        style: TextStyle(
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

