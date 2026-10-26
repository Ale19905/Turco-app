import 'servicio.dart';

enum EstadoTurno { programado, completado, cancelado }

class Turno {
  const Turno({
    required this.id,
    required this.clienteId,
    required this.estilistaId,
    required this.serviciosIds,
    required this.inicio,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.notas,
  });

  final String id;
  final String clienteId;
  final String estilistaId;
  final List<String> serviciosIds;
  final DateTime inicio;
  final String? notas;
  final EstadoTurno estado;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;

  // Duración, hora de fin y total SIEMPRE derivados: nunca se persisten.
  int duracionMinutos(Map<String, Servicio> catalogo) =>
      serviciosIds.fold(0, (suma, id) => suma + catalogo[id]!.duracionMinutos);

  DateTime fin(Map<String, Servicio> catalogo) =>
      inicio.add(Duration(minutes: duracionMinutos(catalogo)));

  int precioTotal(Map<String, Servicio> catalogo) =>
      serviciosIds.fold(0, (suma, id) => suma + catalogo[id]!.precio);

  Turno conEstado(EstadoTurno nuevoEstado, DateTime modificacion) => Turno(
        id: id,
        clienteId: clienteId,
        estilistaId: estilistaId,
        serviciosIds: serviciosIds,
        inicio: inicio,
        estado: nuevoEstado,
        fechaCreacion: fechaCreacion,
        fechaModificacion: modificacion,
        notas: notas,
      );
}
