import 'package:flutter/material.dart';

class BarraPesquisa extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final VoidCallback onPesquisar;
  final VoidCallback? onLimpar;
  final ValueChanged<String>? onChanged;
  final bool pesquisando;

  const BarraPesquisa({
    super.key,
    required this.controller,
    this.hintText,
    required this.onPesquisar,
    this.onLimpar,
    this.onChanged,
    this.pesquisando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onPesquisar(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,

              prefixIcon: const Icon(
                Icons.search,
                size: 22,
                color: Color(0xff555555),
              ),

              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                tooltip: 'Limpar pesquisa',
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: Color(0xff666666),
                ),
                onPressed:
                onLimpar ?? controller.clear,
              )
                  : null,

              filled: true,
              fillColor: const Color(0xfff5f5f5),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffc8c8c8),
                  width: 1,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}
