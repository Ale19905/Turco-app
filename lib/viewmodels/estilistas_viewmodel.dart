import 'package:flutter/foundation.dart';

import '../core/utils/fechas.dart';
import '../data/turco_repository.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Valores derivados para una tarjeta; no duplica ni persiste información.
class ResumenEstilista {
  const ResumenEstilista({
    required this.estilista,
    required this.serviciosPorCategoria,
    required this.programadosHoy,
  });

  final Estilista estilista;
  final Map<CategoriaServicio, List<Servicio>> serviciosPorCategoria;
  final int programadosHoy;

  List<CategoriaServicio> get categorias =>
      serviciosPorCategoria.keys.toList(growable: false);
}

/// RF6: estado reactivo en ChangeNotifier, sin lógica de negocio en la vista.
class EstilistasViewModel extends ChangeNotifier {
  EstilistasViewModel(this.repository) {
    repository.addListener(_datosCambiaron);
  }

  final TurcoRepository repository;

  List<ResumenEstilista> get estilistas {
    final hoy = soloFecha(DateTime.now());
    final cantidades = <String, int>{};
    for (final turno in repository.turnos) {
      if (turno.estado != EstadoTurno.programado ||
          soloFecha(turno.inicio) != hoy) {
        continue;
      }
      cantidades.update(turno.estilistaId, (n) => n + 1, ifAbsent: () => 1);
    }

    return repository.estilistas.map((estilista) {
      final grupos = <CategoriaServicio, List<Servicio>>{};
      for (final servicioId in estilista.serviciosIds) {
        final servicio = repository.catalogo[servicioId];
        if (servicio == null) continue;
        grupos.putIfAbsent(servicio.categoria, () => []).add(servicio);
      }
      return ResumenEstilista(
        estilista: estilista,
        serviciosPorCategoria: grupos,
        programadosHoy: cantidades[estilista.id] ?? 0,
      );
    }).toList(growable: false);
  }

  int get totalProfesionales => repository.estilistas.length;

  int get programadosHoy {
    final hoy = soloFecha(DateTime.now());
    return repository.turnos.where((turno) =>
        turno.estado == EstadoTurno.programado &&
        soloFecha(turno.inicio) == hoy).length;
  }

  void _datosCambiaron() => notifyListeners();

  @override
  void dispose() {
    repository.removeListener(_datosCambiaron);
    super.dispose();
  }
}
