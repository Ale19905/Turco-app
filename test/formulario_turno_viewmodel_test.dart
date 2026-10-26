import 'package:flutter_test/flutter_test.dart';
import '../lib/data/turco_repository.dart';
import '../lib/models/turno.dart';
import '../lib/viewmodels/formulario_turno_viewmodel.dart';

DateTime proximoDiaHabil() {
  var d = DateTime.now().add(const Duration(days: 14));
  d = DateTime(d.year, d.month, d.day);
  while (d.weekday == DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

void main() {
  test('crear turno, bloquear solape, editar sin solaparse y liberar cancelación', () {
    final repo = TurcoRepository();
    final dia = proximoDiaHabil();
    final vm = FormularioTurnoViewModel(repo);
    vm.elegirCliente('c2');
    vm.alternarServicio('s2');
    vm.elegirEstilista('2');
    vm.elegirFecha(dia);
    expect(vm.franjaLibre(9 * 60), isTrue);
    vm.elegirHora(9 * 60);
    expect(vm.guardar(), isNull);
    final id = vm.ultimoGuardado!.turnoId;
    expect(repo.buscarTurno(id), isNotNull);

    final otro = FormularioTurnoViewModel(repo);
    otro.elegirCliente('c4');
    otro.alternarServicio('s2');
    otro.elegirEstilista('2');
    otro.elegirFecha(dia);
    expect(otro.franjaLibre(9 * 60), isFalse); // El estilista ocupado.
    expect(otro.franjaLibre(10 * 60), isTrue); // Justo después, permitido.

    final mismoCliente = FormularioTurnoViewModel(repo);
    mismoCliente.elegirCliente('c2');
    mismoCliente.alternarServicio('s8');
    mismoCliente.elegirEstilista('4');
    mismoCliente.elegirFecha(dia);
    expect(mismoCliente.franjaLibre(9 * 60), isFalse); // Cliente ocupado.

    final editar = FormularioTurnoViewModel(repo, turnoId: id);
    expect(editar.franjaLibre(9 * 60), isTrue); // No se solapa consigo mismo.
    expect(editar.guardar(), isNull);
    expect(repo.actualizarEstado(id, EstadoTurno.cancelado), isTrue);
    expect(otro.franjaLibre(9 * 60), isTrue); // Liberación inmediata.

    editar.dispose(); mismoCliente.dispose(); otro.dispose(); vm.dispose(); repo.dispose();
  });

  test('domingo cerrado y cierre estricto a las 19:00', () {
    final repo = TurcoRepository();
    var fecha = proximoDiaHabil();
    while (fecha.weekday != DateTime.sunday) {
      fecha = fecha.add(const Duration(days: 1));
    }
    final vm = FormularioTurnoViewModel(repo);
    vm.elegirCliente('c2');
    vm.alternarServicio('s3'); // 45 minutos según diseño .pen.
    vm.elegirEstilista('2');
    vm.elegirFecha(fecha);
    expect(vm.franjaLibre(18 * 60 + 30), isFalse);
    vm.elegirFecha(fecha.add(const Duration(days: 1)));
    expect(vm.franjaLibre(18 * 60), isTrue);
    vm.alternarServicio('s2'); // Total 90 minutos.
    expect(vm.franjaLibre(18 * 60 + 30), isFalse);
    vm.dispose(); repo.dispose();
  });
}
