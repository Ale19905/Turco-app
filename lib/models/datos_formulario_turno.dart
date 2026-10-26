/// Parámetros opcionales enviados por `extra` desde Agenda, Clientes y Servicios.
class DatosInicialesTurno {
  const DatosInicialesTurno({this.clienteId, this.servicioId, this.fecha});
  final String? clienteId;
  final String? servicioId;
  final DateTime? fecha;
}

/// Resultado que vuelve a la pantalla anterior mediante `context.pop(valor)`.
class ResultadoTurno {
  const ResultadoTurno({required this.turnoId, required this.fecha, required this.editado});
  final String turnoId;
  final DateTime fecha;
  final bool editado;
}
