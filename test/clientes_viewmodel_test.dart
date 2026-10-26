import 'package:flutter_test/flutter_test.dart';
import '../lib/data/turco_repository.dart';
import '../lib/models/cliente.dart';
import '../lib/models/turno.dart';
import '../lib/viewmodels/clientes_viewmodel.dart';

void main() {
  late TurcoRepository repository;
  late ClientesViewModel vm;

  setUp(() {
    repository = TurcoRepository();
    vm = ClientesViewModel(repository);
  });

  tearDown(() {
    vm.dispose();
    repository.dispose();
  });

  test('Busca clientes por nombre sin importar mayúsculas ni acentos', () {
    vm.cambiarBusqueda('SOFIA');
    expect(vm.clientesFiltrados.map((c) => c.nombre), contains('Sofía Díaz'));

    vm.cambiarBusqueda('martin');
    expect(vm.clientesFiltrados.map((c) => c.nombre), contains('Ana Martín'));
    expect(vm.clientesFiltrados.map((c) => c.nombre), contains('Martín Rojas'));
  });

  test('La búsqueda se combina con el filtro de género', () {
    vm.cambiarBusqueda('martin');
    vm.cambiarFiltro(FiltroGeneroClientes.mujeres);
    expect(vm.clientesFiltrados.map((c) => c.nombre), ['Ana Martín']);

    vm.cambiarFiltro(FiltroGeneroClientes.hombres);
    expect(vm.clientesFiltrados.map((c) => c.nombre), ['Martín Rojas']);
  });

  test('Se puede buscar por teléfono', () {
    vm.cambiarBusqueda('71110005');
    expect(vm.clientesFiltrados.length, 1);
    expect(vm.clientesFiltrados.single.nombre, 'Sofía Díaz');
  });

  test('Los contadores se actualizan al agregar un cliente', () {
    final totalAntes = vm.total;
    final resultado = repository.guardarCliente(Cliente(
      id: 'nuevo-cliente',
      nombre: 'María Flores',
      telefono: '59998888',
      genero: GeneroCliente.mujer,
      fechaRegistro: DateTime.now(),
    ));
    expect(resultado, isNull);
    expect(vm.total, totalAntes + 1);
    expect(vm.clientesFiltrados.any((c) => c.nombre == 'María Flores'), isTrue);
  });

  test('No permite eliminar un cliente con turnos programados', () {
    final seleccionado = repository.turnos.firstWhere(
      (t) => t.estado == EstadoTurno.programado,
    );
    final id = seleccionado.clienteId;
    final totalAntes = repository.clientes.length;

    final error = vm.eliminarCliente(id);
    expect(error, contains('No se puede eliminar'));
    expect(repository.clientes.length, totalAntes);
    expect(repository.clientesPorId.containsKey(id), isTrue);
    expect(repository.buscarTurno(seleccionado.id), isNotNull);
  });

  test('Elimina cliente e historial cuando no hay turnos programados', () {
    const id = 'c8';
    final turnosAntes = repository.turnos.where((t) => t.clienteId == id).toList();
    expect(turnosAntes, isNotEmpty);

    for (final turno in turnosAntes) {
      if (turno.estado == EstadoTurno.programado) {
        expect(repository.actualizarEstado(turno.id, EstadoTurno.cancelado), isTrue);
      }
    }
    expect(vm.programados(id), 0);
    expect(vm.eliminarCliente(id), isNull);
    expect(repository.clientesPorId.containsKey(id), isFalse);
    expect(repository.turnos.where((t) => t.clienteId == id), isEmpty);
  });
}
