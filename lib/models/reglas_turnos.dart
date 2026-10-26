import 'cliente.dart';
import 'estilista.dart';
import 'servicio.dart';
import 'turno.dart';

/// Reglas centrales del dominio. Serán reutilizadas en el formulario de turno.
abstract final class ReglasTurnos {
  static String? validar({
    required Turno candidato,
    required Iterable<Turno> existentes,
    required Map<String, Servicio> catalogo,
    required Map<String, Estilista> estilistas,
    required Map<String, Cliente> clientes,
    required DateTime ahora,
  }) {
    if (!clientes.containsKey(candidato.clienteId)) {
      return 'Seleccioná un cliente válido.';
    }
    final estilista = estilistas[candidato.estilistaId];
    if (estilista == null) return 'Seleccioná un estilista válido.';
    if (candidato.serviciosIds.isEmpty) {
      return 'Elegí al menos un servicio.';
    }
    if (candidato.serviciosIds.any((id) => !catalogo.containsKey(id))) {
      return 'Hay servicios que no existen en el catálogo.';
    }
    if (!estilista.realizaTodos(candidato.serviciosIds)) {
      return 'El estilista no realiza todos los servicios elegidos.';
    }
    final inicio = candidato.inicio;
    if (inicio.weekday == DateTime.sunday) {
      return 'El salón no atiende los domingos.';
    }
    if (inicio.minute % 30 != 0 || inicio.second != 0 ||
        inicio.millisecond != 0 || inicio.microsecond != 0) {
      return 'Los turnos comienzan cada 30 minutos.';
    }
    if (!inicio.isAfter(ahora)) {
      return 'No se pueden programar turnos en el pasado.';
    }
    final apertura = DateTime(inicio.year, inicio.month, inicio.day, 9);
    final cierre = DateTime(inicio.year, inicio.month, inicio.day, 19);
    final fin = candidato.fin(catalogo);
    if (inicio.isBefore(apertura) || fin.isAfter(cierre)) {
      return 'El turno debe estar entre las 09:00 y las 19:00.';
    }
    for (final otro in existentes) {
      if (otro.id == candidato.id || otro.estado == EstadoTurno.cancelado) {
        continue; // En edición no se solapa consigo mismo.
      }
      final compartenRecurso = otro.estilistaId == candidato.estilistaId ||
          otro.clienteId == candidato.clienteId;
      // Los intervalos [inicio, fin) permiten comenzar justo al terminar otro.
      if (compartenRecurso && inicio.isBefore(otro.fin(catalogo)) &&
          otro.inicio.isBefore(fin)) {
        return 'El cliente o el estilista ya tiene un turno en ese horario.';
      }
    }
    return null;
  }
}
