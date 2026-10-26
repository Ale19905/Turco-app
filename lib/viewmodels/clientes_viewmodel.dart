import 'package:flutter/foundation.dart';

import '../data/turco_repository.dart';
import '../models/cliente.dart';
import '../models/turno.dart';

enum FiltroGeneroClientes { todos, mujeres, hombres }

/// Estado propio de la pestaña Clientes. No depende de sus widgets.
class ClientesViewModel extends ChangeNotifier {
  ClientesViewModel(this.repository) {
    repository.addListener(_actualizar);
  }

  final TurcoRepository repository;
  String _busqueda = '';
  FiltroGeneroClientes _filtro = FiltroGeneroClientes.todos;

  String get busqueda => _busqueda;
  FiltroGeneroClientes get filtro => _filtro;
  int get total => repository.clientes.length;
  int get totalMujeres => repository.clientes
      .where((c) => c.genero == GeneroCliente.mujer).length;
  int get totalHombres => repository.clientes
      .where((c) => c.genero == GeneroCliente.hombre).length;

  /// Ignora mayúsculas y acentos, incluida la ñ, para buscar por nombre.
  @visibleForTesting
  static String normalizar(String texto) => texto.toLowerCase().trim()
      .replaceAll(RegExp(r'[áàâäãå]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôöõ]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');

  List<Cliente> get clientesFiltrados {
    final consulta = normalizar(_busqueda);
    return repository.clientes.where((c) {
      final correspondeGenero = switch (_filtro) {
        FiltroGeneroClientes.todos => true,
        FiltroGeneroClientes.mujeres => c.genero == GeneroCliente.mujer,
        FiltroGeneroClientes.hombres => c.genero == GeneroCliente.hombre,
      };
      return correspondeGenero && (consulta.isEmpty ||
          normalizar(c.nombre).contains(consulta) ||
          c.telefono.contains(consulta));
    }).toList();
  }

  void cambiarBusqueda(String texto) {
    if (_busqueda == texto) return;
    _busqueda = texto;
    notifyListeners();
  }

  void cambiarFiltro(FiltroGeneroClientes filtro) {
    if (_filtro == filtro) return;
    _filtro = filtro;
    notifyListeners();
  }

  List<Turno> historial(String clienteId) {
    final resultado = repository.turnos.where((t) => t.clienteId == clienteId).toList();
    resultado.sort((a, b) => b.inicio.compareTo(a.inicio));
    return resultado;
  }

  int cantidadTurnos(String clienteId) => historial(clienteId).length;

  int programados(String clienteId) => repository.turnos.where((t) =>
      t.clienteId == clienteId && t.estado == EstadoTurno.programado).length;

  String? eliminarCliente(String id) => repository.eliminarCliente(id);

  void _actualizar() => notifyListeners();

  @override
  void dispose() {
    repository.removeListener(_actualizar);
    super.dispose();
  }
}
