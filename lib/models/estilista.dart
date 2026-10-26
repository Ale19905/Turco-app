class Estilista {
  const Estilista({
    required this.id,
    required this.nombre,
    required this.rutaAvatar,
    required this.serviciosIds,
  });

  final String id;
  final String nombre;
  final String rutaAvatar;
  final List<String> serviciosIds;

  bool realizaTodos(Iterable<String> servicios) =>
      servicios.every(serviciosIds.contains);
}
