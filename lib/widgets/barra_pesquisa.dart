import 'package:flutter/material.dart';

class BarraPesquisa extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onPesquisar;
  final VoidCallback? onLimpar;
  final ValueChanged<String>? onChanged;
  final bool pesquisando;

  const BarraPesquisa({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onPesquisar,
    this.onLimpar,
    this.onChanged,
    this.pesquisando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffe8e8e8),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
                      size: 21,
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                      tooltip: 'Limpar pesquisa',
                      icon: const Icon(
                        Icons.close,
                        size: 19,
                      ),
                      onPressed:
                      onLimpar ?? controller.clear,
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xfff3f3f3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed:
              pesquisando ? null : onPesquisar,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              child: pesquisando
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Text('Pesquisar'),
            ),
          ),
        ],
      ),
    );
  }
}
