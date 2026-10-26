import 'package:flutter/foundation.dart';

import '../core/utils/fechas.dart';
import '../models/cliente.dart';
import '../models/estilista.dart';
import '../models/reglas_turnos.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'datos_prueba.dart';

/// Única fuente de datos en memoria. Notifica a TODAS las vistas al cambiar.
class TurcoRepository extends ChangeNotifier {
  TurcoRepository() {
    final ahora = DateTime.now();
    _servicios = List.unmodifiable(DatosPrueba.servicios);
    _estilistas = List.unmodifiable(DatosPrueba.estilistas);
    _clientes = DatosPrueba.clientes(ahora);
    _turnos = DatosPrueba.turnos(ahora);
    catalogo = Map.unmodifiable({for (final s in _servicios) s.id: s});
    estilistasPorId = Map.unmodifiable({for (final e in _estilistas) e.id: e});
    clientesPorId = {for (final c in _clientes) c.id: c};
  }

  late final List<Servicio> _servicios;
  late final List<Estilista> _estilistas;
  late final List<Cliente> _clientes;
  late final List<Turno> _turnos;
  late final Map<String, Servicio> catalogo;
  late final Map<String, Estilista> estilistasPorId;
  late final Map<String, Cliente> clientesPorId;

  List<Servicio> get servicios => List.unmodifiable(_servicios);
  List<Estilista> get estilistas => List.unmodifiable(_estilistas);
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Turno> get turnos => List.unmodifiable(_turnos);

  List<Turno> turnosDelDia(DateTime fecha) {
    final dia = soloFecha(fecha);
    final lista = _turnos.where((t) => soloFecha(t.inicio) == dia).toList();
    lista.sort((a, b) => a.inicio.compareTo(b.inicio));
    return lista;
  }

  /// Devuelve null cuando el ID no existe; las rutas inválidas no rompen la app.
  Turno? buscarTurno(String id) {
    for (final turno in _turnos) {
      if (turno.id == id) return turno;
    }
    return null;
  }

  Cliente cliente(String id) => clientesPorId[id]!;
  Estilista estilista(String id) => estilistasPorId[id]!;
  List<Servicio> serviciosDe(Turno turno) =>
      turno.serviciosIds.map((id) => catalogo[id]!).toList();
  DateTime finDe(Turno turno) => turno.fin(catalogo);
  int precioDe(Turno turno) => turno.precioTotal(catalogo);

  String? validarTurno(Turno candidato) => ReglasTurnos.validar(
    candidato: candidato,
    existentes: _turnos,
    catalogo: catalogo,
    estilistas: estilistasPorId,
    clientes: clientesPorId,
    ahora: DateTime.now(),
  );

  /// Validación transaccional: el formulario y el repositorio aplican
  /// las mismas reglas, incluso si algo cambió mientras estaba abierto.
  String? guardarTurno(Turno candidato, {required bool edicion}) {
    if (edicion) {
      final anterior = buscarTurno(candidato.id);
      if (anterior == null || anterior.estado != EstadoTurno.programado) {
        return 'Este turno ya no puede editarse.';
      }
    } else if (buscarTurno(candidato.id) != null) {
      return 'El identificador del turno ya existe.';
    }
    final error = validarTurno(candidato);
    if (error != null) return error;
    if (edicion) {
      final index = _turnos.indexWhere((t) => t.id == candidato.id);
      _turnos[index] = candidato;
    } else {
      _turnos.add(candidato);
    }
    notifyListeners();
    return null;
  }

  String? validarCliente({
    required String nombre,
    required String telefono,
    required GeneroCliente? genero,
    required String? correo,
    String? excluirId,
  }) {
    if (nombre.trim().length < 3 || nombre.trim().length > 60) {
      return 'El nombre debe tener entre 3 y 60 caracteres.';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(telefono)) {
      return 'El teléfono debe tener exactamente 8 dígitos.';
    }
    if (_clientes.any((c) => c.telefono == telefono && c.id != excluirId)) {
      return 'Ese teléfono ya está registrado.';
    }
    if (genero == null) return 'Seleccioná el género.';
    if (correo != null && correo.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo.trim())) {
      return 'Ingresá un correo válido.';
    }
    return null;
  }

  /// Alta/edición reutilizable en la hoja inferior de Clientes y Turnos.
  String? guardarCliente(Cliente candidato, {bool edicion = false}) {
    final error = validarCliente(
      nombre: candidato.nombre, telefono: candidato.telefono,
      genero: candidato.genero, correo: candidato.correo,
      excluirId: edicion ? candidato.id : null,
    );
    if (error != null) return error;
    if (edicion) {
      final indice = _clientes.indexWhere((c) => c.id == candidato.id);
      if (indice < 0) return 'El cliente no existe.';
      _clientes[indice] = candidato;
    } else {
      if (clientesPorId.containsKey(candidato.id)) return 'Cliente duplicado.';
      _clientes.add(candidato);
    }
    clientesPorId[candidato.id] = candidato;
    notifyListeners();
    return null;
  }

  /// Elimina un cliente únicamente si no conserva turnos programados.
  /// Los turnos completados y cancelados se borran junto con su historial.
  /// Devuelve null si se eliminó; en caso contrario devuelve el motivo.
  String? eliminarCliente(String id) {
    final indice = _clientes.indexWhere((c) => c.id == id);
    if (indice < 0) return 'El cliente no existe.';

    final pendientes = _turnos.where((t) =>
        t.clienteId == id && t.estado == EstadoTurno.programado).length;
    if (pendientes > 0) {
      final unidad = pendientes == 1 ? 'turno programado' : 'turnos programados';
      return 'No se puede eliminar: ${_clientes[indice].nombre} tiene '
          '$pendientes $unidad.';
    }

    _turnos.removeWhere((t) => t.clienteId == id);
    _clientes.removeAt(indice);
    clientesPorId.remove(id);
    notifyListeners();
    return null;
  }

  bool actualizarEstado(String id, EstadoTurno nuevoEstado) {
    if (nuevoEstado == EstadoTurno.programado) return false;
    final posicion = _turnos.indexWhere((t) => t.id == id);
    if (posicion == -1 || _turnos[posicion].estado != EstadoTurno.programado) {
      return false;
    }
    _turnos[posicion] = _turnos[posicion].conEstado(nuevoEstado, DateTime.now());
    notifyListeners();
    return true;
  }
}
