enum GeneroCliente { mujer, hombre }

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.genero,
    required this.fechaRegistro,
    this.correo,
  });

  final String id;
  final String nombre;
  final String telefono;
  final GeneroCliente genero;
  final String? correo;
  final DateTime fechaRegistro;
}
