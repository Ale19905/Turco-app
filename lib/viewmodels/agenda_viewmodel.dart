import 'package:flutter/foundation.dart';

import '../core/utils/fechas.dart';
import '../data/turco_repository.dart';
import '../models/turno.dart';

/// Estado propio de la pestaña Agenda. Se conserva al cambiar de pestaña.
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel(this.repository, {String? estilistaInicial})
      : _fecha = soloFecha(DateTime.now()),
        _estilistaId = estilistaInicial {
    repository.addListener(_datosCambiaron);
  }

  final TurcoRepository repository;
  DateTime _fecha;
  String? _estilistaId;
  EstadoTurno? _estado;

  DateTime get fechaSeleccionada => _fecha;
  DateTime get lunesSemana => comienzoSemana(_fecha);
  String? get estilistaId => _estilistaId;
  EstadoTurno? get filtroEstado => _estado;

  List<Turno> get turnosDelDia => repository.turnosDelDia(_fecha);

  List<Turno> get turnosFiltrados => turnosDelDia.where((turno) {
    return (_estilistaId == null || turno.estilistaId == _estilistaId) &&
        (_estado == null || turno.estado == _estado);
  }).toList();

  int get totalProgramados => turnosDelDia
      .where((t) => t.estado == EstadoTurno.programado).length;

  int get totalCompletados => turnosDelDia
      .where((t) => t.estado == EstadoTurno.completado).length;

  int get ingresoEstimado => turnosDelDia
      .where((t) => t.estado != EstadoTurno.cancelado)
      .fold(0, (total, t) => total + repository.precioDe(t));

  void seleccionarFecha(DateTime fecha) {
    final dia = soloFecha(fecha);
    if (dia == _fecha) return;
    _fecha = dia;
    notifyListeners();
  }

  void moverSemana(int semanas) =>
      seleccionarFecha(_fecha.add(Duration(days: semanas * 7)));

  void filtrarEstilista(String? id) {
    if (_estilistaId == id) return;
    _estilistaId = id;
    notifyListeners();
  }

  void filtrarEstado(EstadoTurno? estado) {
    if (_estado == estado) return;
    _estado = estado;
    notifyListeners();
  }

  bool cambiarEstado(String id, EstadoTurno estado) =>
      repository.actualizarEstado(id, estado);

  void _datosCambiaron() => notifyListeners();

  @override
  void dispose() {
    repository.removeListener(_datosCambiaron);
    super.dispose();
  }
}
