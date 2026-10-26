import 'package:flutter/foundation.dart';

import '../data/turco_repository.dart';
import '../models/cliente.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Orquesta el detalle y reacciona a cambios del repositorio compartido.
/// La vista no calcula precios, duración ni cambia reglas de negocio.
class DetalleTurnoViewModel extends ChangeNotifier {
  DetalleTurnoViewModel(this.repository, this.turnoId) {
    repository.addListener(_alCambiarDatos);
  }

  final TurcoRepository repository;
  final String turnoId;

  Turno? get turno => repository.buscarTurno(turnoId);

  Cliente? get cliente {
    final actual = turno;
    return actual == null ? null : repository.clientesPorId[actual.clienteId];
  }

  Estilista? get estilista {
    final actual = turno;
    return actual == null ? null : repository.estilistasPorId[actual.estilistaId];
  }

  List<Servicio> get servicios {
    final actual = turno;
    return actual == null ? const [] : repository.serviciosDe(actual);
  }

  DateTime? get fin {
    final actual = turno;
    return actual == null ? null : repository.finDe(actual);
  }

  int get duracionMinutos {
    final actual = turno;
    return actual == null ? 0 : actual.duracionMinutos(repository.catalogo);
  }

  int get precioTotal {
    final actual = turno;
    return actual == null ? 0 : repository.precioDe(actual);
  }

  bool get sePuedeModificar => turno?.estado == EstadoTurno.programado;

  bool cambiarEstado(EstadoTurno nuevo) =>
      repository.actualizarEstado(turnoId, nuevo);

  void _alCambiarDatos() => notifyListeners();

  @override
  void dispose() {
    repository.removeListener(_alCambiarDatos);
    super.dispose();
  }
}
