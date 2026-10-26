import 'package:flutter/foundation.dart';

import '../data/turco_repository.dart';
import '../models/servicio.dart';

enum FiltroPublicoServicios { todos, mujeres, hombres }

/// RF5: filtros combinados y catálogo de solo lectura. No almacena servicios.
/// La instancia pertenece a la pestaña, por eso sus filtros sobreviven a
/// cambios entre destinos de StatefulShellRoute.indexedStack.
class ServiciosViewModel extends ChangeNotifier {
  ServiciosViewModel(this.repository);

  final TurcoRepository repository;

  CategoriaServicio? _categoria;
  FiltroPublicoServicios _publico = FiltroPublicoServicios.todos;

  CategoriaServicio? get categoria => _categoria;
  FiltroPublicoServicios get publico => _publico;

  List<Servicio> get serviciosVisibles => repository.servicios.where((servicio) {
        final coincideCategoria = _categoria == null ||
            servicio.categoria == _categoria;
        final coincidePublico = switch (_publico) {
          FiltroPublicoServicios.todos => true,
          // Unisex también está disponible para mujeres y para hombres.
          FiltroPublicoServicios.mujeres =>
            servicio.publico != PublicoServicio.hombres,
          FiltroPublicoServicios.hombres =>
            servicio.publico != PublicoServicio.mujeres,
        };
        return coincideCategoria && coincidePublico;
      }).toList(growable: false);

  void cambiarCategoria(CategoriaServicio? categoria) {
    if (_categoria == categoria) return;
    _categoria = categoria;
    notifyListeners();
  }

  void cambiarPublico(FiltroPublicoServicios publico) {
    if (_publico == publico) return;
    _publico = publico;
    notifyListeners();
  }
}
