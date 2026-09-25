import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarUtilizador extends StatelessWidget {
  final double radius;
  final Map<String, dynamic>? perfil;

  const AvatarUtilizador({
    super.key,
    this.radius = 18,
    this.perfil,
  });

  String? _obterFoto(User? usuario) {
    final metadata =
        usuario?.userMetadata ?? const <String, dynamic>{};

    final valores = <dynamic>[
      perfil?['avatar_url'],
      perfil?['picture'],
      perfil?['photo_url'],
      metadata['picture'],
      metadata['avatar_url'],
      metadata['photo_url'],
    ];

    for (final valor in valores) {
      final url = valor?.toString().trim();

      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    return null;
  }

  String _obterNome(User? usuario) {
    final metadata =
        usuario?.userMetadata ?? const <String, dynamic>{};

    final valores = <dynamic>[
      perfil?['nome'],
      metadata['full_name'],
      metadata['name'],
      usuario?.email,
    ];

    for (final valor in valores) {
      final texto = valor?.toString().trim();

      if (texto != null && texto.isNotEmpty) {
        return texto;
      }
    }

    return 'Utilizador';
  }

  String _iniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (partes.isEmpty) {
      return 'U';
    }

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return (
        partes.first.substring(0, 1) +
            partes.last.substring(0, 1)
    ).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final foto = _obterFoto(usuario);
    final iniciais = _iniciais(_obterNome(usuario));

    if (foto != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Image.network(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    iniciais,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: radius * 0.75,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        iniciais,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.75,
          color: Colors.black54,
        ),
      ),
    );
  }
}

