enum CategoriaServicio { corte, color, barba, peinado, tratamiento }

enum PublicoServicio { mujeres, hombres, unisex }

class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.duracionMinutos,
    required this.precio,
    required this.publico,
  });

  final String id;
  final String nombre;
  final CategoriaServicio categoria;
  final int duracionMinutos;
  final int precio;
  final PublicoServicio publico;
}
