import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/turco_repository.dart';
import 'package:app/models/servicio.dart';
import 'package:app/viewmodels/servicios_viewmodel.dart';

void main() {
  late TurcoRepository repository;
  late ServiciosViewModel vm;

  setUp(() {
    repository = TurcoRepository();
    vm = ServiciosViewModel(repository);
  });

  tearDown(() {
    vm.dispose();
    repository.dispose();
  });

  test('el catálogo tiene los 12 servicios del enunciado', () {
    expect(vm.serviciosVisibles.length, 12);
    expect(vm.categoria, isNull);
    expect(vm.publico, FiltroPublicoServicios.todos);
  });

  test('filtrar una categoría devuelve solo sus servicios', () {
    vm.cambiarCategoria(CategoriaServicio.barba);
    expect(vm.serviciosVisibles, isNotEmpty);
    expect(vm.serviciosVisibles.every(
      (s) => s.categoria == CategoriaServicio.barba), isTrue);
  });

  test('unisex aparece tanto en Mujeres como en Hombres', () {
    vm.cambiarPublico(FiltroPublicoServicios.mujeres);
    expect(vm.serviciosVisibles.every(
      (s) => s.publico != PublicoServicio.hombres), isTrue);
    expect(vm.serviciosVisibles.any(
      (s) => s.publico == PublicoServicio.unisex), isTrue);
    vm.cambiarPublico(FiltroPublicoServicios.hombres);
    expect(vm.serviciosVisibles.every(
      (s) => s.publico != PublicoServicio.mujeres), isTrue);
    expect(vm.serviciosVisibles.any(
      (s) => s.publico == PublicoServicio.unisex), isTrue);
  });

  test('combinar filtros puede dejar vacío y luego restablecer catálogo', () {
    vm.cambiarCategoria(CategoriaServicio.barba);
    vm.cambiarPublico(FiltroPublicoServicios.mujeres);
    expect(vm.serviciosVisibles, isEmpty);
    vm.cambiarCategoria(null);
    vm.cambiarPublico(FiltroPublicoServicios.todos);
    expect(vm.serviciosVisibles.length, 12);
  });

  test('ChangeNotifier emite cambios de filtro', () {
    var cambios = 0;
    vm.addListener(() => cambios++);
    vm.cambiarCategoria(CategoriaServicio.corte);
    vm.cambiarPublico(FiltroPublicoServicios.hombres);
    vm.cambiarPublico(FiltroPublicoServicios.hombres); // sin cambio real
    expect(cambios, 2);
  });
}
