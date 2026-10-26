import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/fechas.dart';
import 'package:app/data/turco_repository.dart';
import 'package:app/models/servicio.dart';
import 'package:app/models/turno.dart';
import 'package:app/viewmodels/estilistas_viewmodel.dart';

void main() {
  late TurcoRepository repo;
  late EstilistasViewModel vm;

  setUp(() {
    repo = TurcoRepository();
    vm = EstilistasViewModel(repo);
  });

  tearDown(() {
    vm.dispose();
    repo.dispose();
  });

  test('Hay 5 estilistas y sus servicios se agrupan por categoría', () {
    expect(vm.totalProfesionales, 5);
    expect(vm.estilistas.length, 5);
    final marta = vm.estilistas.firstWhere((e) => e.estilista.id == '1');
    expect(marta.estilista.nombre, 'Marta Salazar');
    expect(marta.categorias, contains(CategoriaServicio.corte));
    expect(marta.categorias, contains(CategoriaServicio.color));
    expect(marta.serviciosPorCategoria[CategoriaServicio.corte], isNotEmpty);
  });

  test('Cuenta solo turnos programados con fecha de hoy', () {
    final hoy = soloFecha(DateTime.now());
    final programados = repo.turnos.where((t) =>
        t.estado == EstadoTurno.programado &&
        soloFecha(t.inicio) == hoy).toList();
    expect(vm.programadosHoy, programados.length);
    for (final resumen in vm.estilistas) {
      expect(
        resumen.programadosHoy,
        programados.where((t) => t.estilistaId == resumen.estilista.id).length,
      );
    }
  });

  test('Conserva al menos un estilista sin turnos programados hoy', () {
    expect(vm.estilistas.any((e) => e.programadosHoy == 0), isTrue);
  });

  test('Reacciona cuando se cancela un turno programado', () {
    var cantidadAvisos = 0;
    void listener() => cantidadAvisos++;
    vm.addListener(listener);
    final programados = repo.turnos.where(
      (t) => t.estado == EstadoTurno.programado,
    ).toList();
    expect(programados, isNotEmpty);
    expect(
      repo.actualizarEstado(programados.first.id, EstadoTurno.cancelado),
      isTrue,
    );
    expect(cantidadAvisos, 1);
    vm.removeListener(listener);
  });
}
