import 'package:flutter/foundation.dart';

import '../core/utils/fechas.dart';
import '../data/turco_repository.dart';
import '../models/cliente.dart';
import '../models/datos_formulario_turno.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

enum FiltroPublico { todos, mujeres, hombres }

/// Estado y reglas del formulario, sin depender de los widgets.
class FormularioTurnoViewModel extends ChangeNotifier {
  FormularioTurnoViewModel(
    this.repository, {
    String? turnoId,
    DatosInicialesTurno? iniciales,
  }) : _turnoOriginal = turnoId == null
           ? null
           : repository.buscarTurno(turnoId) {
    final original = _turnoOriginal;
    if (original != null) {
      _clienteId = original.clienteId;
      _estilistaId = original.estilistaId;
      _serviciosIds.addAll(original.serviciosIds);
      _fecha = soloFecha(original.inicio);
      _minutos = original.inicio.hour * 60 + original.inicio.minute;
      _notas = original.notas ?? '';
      _ajustarPublico(original.clienteId);
    } else {
      final clienteInicial = iniciales?.clienteId;
      _clienteId =
          clienteInicial != null &&
              repository.clientesPorId.containsKey(clienteInicial)
          ? clienteInicial
          : null;
      if (_clienteId != null) _ajustarPublico(_clienteId!);
      final servicioInicial = iniciales?.servicioId;
      if (servicioInicial != null &&
          repository.catalogo.containsKey(servicioInicial)) {
        _serviciosIds.add(servicioInicial);
      }
      _fecha = iniciales?.fecha == null
          ? null
          : _primeraFechaHabil(iniciales!.fecha!);
    }
    _solicitoEdicion = turnoId != null;
    _baseCliente = _clienteId;
    _baseEstilista = _estilistaId;
    _baseServicios = Set.of(_serviciosIds);
    _baseFecha = _fecha;
    _baseMinutos = _minutos;
    _baseNotas = _notas;
    _basePublico = _publico;
    repository.addListener(_repoCambio);
  }

  final TurcoRepository repository;
  final Turno? _turnoOriginal;
  late final String? _baseCliente;
  late final String? _baseEstilista;
  late final Set<String> _baseServicios;
  late final DateTime? _baseFecha;
  late final int? _baseMinutos;
  late final String _baseNotas;
  late final FiltroPublico _basePublico;
  // Un identificador inexistente no debe abrir un formulario nuevo.
  late final bool _solicitoEdicion;
  final Set<String> _serviciosIds = {};
  String? _clienteId;
  String? _estilistaId;
  DateTime? _fecha;
  int? _minutos;
  String _notas = '';
  FiltroPublico _publico = FiltroPublico.todos;

  bool get editando => _solicitoEdicion;
  bool get editable =>
      !editando || _turnoOriginal?.estado == EstadoTurno.programado;
  String? get clienteId => _clienteId;
  String? get estilistaId => _estilistaId;
  DateTime? get fecha => _fecha;
  int? get minutos => _minutos;
  String get notas => _notas;
  FiltroPublico get publico => _publico;
  Set<String> get serviciosIds => Set.unmodifiable(_serviciosIds);

  static DateTime _primeraFechaHabil(DateTime fecha) {
    var valor = soloFecha(fecha);
    final hoy = soloFecha(DateTime.now());
    if (valor.isBefore(hoy)) valor = hoy;
    if (valor.weekday == DateTime.sunday) {
      valor = valor.add(const Duration(days: 1));
    }
    return valor;
  }

  List<Servicio> get serviciosVisibles => repository.servicios
      .where(
        (s) =>
            _publico == FiltroPublico.todos ||
            (_publico == FiltroPublico.mujeres &&
                s.publico != PublicoServicio.hombres) ||
            (_publico == FiltroPublico.hombres &&
                s.publico != PublicoServicio.mujeres),
      )
      .toList();

  List<Estilista> get estilistasCompatibles => _serviciosIds.isEmpty
      ? []
      : repository.estilistas
            .where((e) => e.realizaTodos(_serviciosIds))
            .toList();

  int get duracion => _serviciosIds.fold(
    0,
    (suma, id) => suma + (repository.catalogo[id]?.duracionMinutos ?? 0),
  );
  int get precio => _serviciosIds.fold(
    0,
    (suma, id) => suma + (repository.catalogo[id]?.precio ?? 0),
  );
  DateTime? get horaFin => _fecha == null || _minutos == null
      ? null
      : DateTime(
          _fecha!.year,
          _fecha!.month,
          _fecha!.day,
        ).add(Duration(minutes: _minutos! + duracion));

  bool get tieneCambios =>
      _baseCliente != _clienteId ||
      _baseEstilista != _estilistaId ||
      !setEquals(_baseServicios, _serviciosIds) ||
      _baseFecha != _fecha ||
      _baseMinutos != _minutos ||
      _baseNotas != _notas ||
      _basePublico != _publico;

  void _ajustarPublico(String id) {
    final c = repository.clientesPorId[id];
    _publico = c?.genero == GeneroCliente.mujer
        ? FiltroPublico.mujeres
        : FiltroPublico.hombres;
  }

  void elegirCliente(String? id) {
    _clienteId = id;
    if (id != null) _ajustarPublico(id);
    _minutos = null;
    notifyListeners();
  }

  void cambiarPublico(FiltroPublico filtro) {
    _publico = filtro;
    notifyListeners();
  }

  /// True si hubo que limpiar un estilista incompatible.
  bool alternarServicio(String id) {
    if (_serviciosIds.contains(id)) {
      _serviciosIds.remove(id);
    } else {
      _serviciosIds.add(id);
    }
    final incompatible =
        _estilistaId != null &&
        (_serviciosIds.isEmpty ||
            !(repository.estilistasPorId[_estilistaId]?.realizaTodos(
                  _serviciosIds,
                ) ??
                false));
    if (incompatible) _estilistaId = null;
    _minutos = null;
    notifyListeners();
    return incompatible;
  }

  void elegirEstilista(String? id) {
    _estilistaId = id;
    _minutos = null;
    notifyListeners();
  }

  void elegirFecha(DateTime fecha) {
    _fecha = soloFecha(fecha);
    _minutos = null;
    notifyListeners();
  }

  void elegirHora(int minutos) {
    if (!franjaLibre(minutos)) return;
    _minutos = minutos;
    notifyListeners();
  }

  void cambiarNotas(String texto) {
    _notas = texto;
    notifyListeners();
  }

  List<int> get franjas => List.generate(20, (i) => 9 * 60 + i * 30);

  String horaTexto(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutos % 60).toString().padLeft(2, '0')}';

  bool franjaLibre(int minutos) {
    final fecha = _fecha;
    if (fecha == null ||
        fecha.weekday == DateTime.sunday ||
        _clienteId == null ||
        _estilistaId == null ||
        duracion == 0 ||
        !(repository.estilistasPorId[_estilistaId]?.realizaTodos(
              _serviciosIds,
            ) ??
            false) ||
        minutos < 9 * 60 ||
        minutos % 30 != 0 ||
        minutos + duracion > 19 * 60) {
      return false;
    }
    final inicio = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).add(Duration(minutes: minutos));
    if (!inicio.isAfter(DateTime.now())) return false;
    final fin = inicio.add(Duration(minutes: duracion));
    for (final otro in repository.turnos) {
      if (otro.id == _turnoOriginal?.id || otro.estado == EstadoTurno.cancelado)
        continue;
      if (otro.clienteId != _clienteId && otro.estilistaId != _estilistaId)
        continue;
      if (inicio.isBefore(repository.finDe(otro)) &&
          otro.inicio.isBefore(fin)) {
        return false;
      }
    }
    return true;
  }

  bool get tieneFranjasLibres => franjas.any(franjaLibre);

  String? get errorCliente =>
      _clienteId == null ? 'Selecciona un cliente' : null;
  String? get errorServicios =>
      _serviciosIds.isEmpty ? 'Elige al menos un servicio' : null;
  String? get errorEstilista =>
      _estilistaId == null ? 'Selecciona un estilista' : null;
  String? get errorFecha =>
      _fecha == null ||
          _fecha!.weekday == DateTime.sunday ||
          soloFecha(_fecha!).isBefore(soloFecha(DateTime.now()))
      ? 'Elige una fecha válida (no domingos)'
      : null;
  String? get errorHora => _minutos == null || !franjaLibre(_minutos!)
      ? 'Elige una hora disponible para el turno'
      : null;

  /// El repositorio valida nuevamente antes de guardar.
  String? guardar() {
    if (!editable) return 'Solo se pueden editar turnos programados.';
    if (errorCliente != null) return errorCliente;
    if (errorServicios != null) return errorServicios;
    if (errorEstilista != null) return errorEstilista;
    if (errorFecha != null) return errorFecha;
    if (errorHora != null) return errorHora;
    if (_notas.length > 500)
      return 'Las notas no pueden superar 500 caracteres.';
    final ahora = DateTime.now();
    final inicio = DateTime(
      _fecha!.year,
      _fecha!.month,
      _fecha!.day,
    ).add(Duration(minutes: _minutos!));
    final original = _turnoOriginal;
    final turno = Turno(
      id: original?.id ?? 't${ahora.microsecondsSinceEpoch}',
      clienteId: _clienteId!,
      estilistaId: _estilistaId!,
      serviciosIds: List.unmodifiable(_serviciosIds),
      inicio: inicio,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
      estado: EstadoTurno.programado,
      fechaCreacion: original?.fechaCreacion ?? ahora,
      fechaModificacion: ahora,
    );
    final error = repository.guardarTurno(turno, edicion: editando);
    if (error == null) {
      _ultimoGuardado = ResultadoTurno(
        turnoId: turno.id,
        fecha: soloFecha(inicio),
        editado: editando,
      );
    }
    return error;
  }

  ResultadoTurno? _ultimoGuardado;
  ResultadoTurno? get ultimoGuardado => _ultimoGuardado;

  void _repoCambio() => notifyListeners();

  @override
  void dispose() {
    repository.removeListener(_repoCambio);
    super.dispose();
  }
}
