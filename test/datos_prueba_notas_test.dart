import 'package:flutter_test/flutter_test.dart';

import '../lib/data/turco_repository.dart';

void main() {
  test('Las notas precargadas cumplen el límite de caracteres', () {
    final repository = TurcoRepository();
    addTearDown(repository.dispose);

    final turnos = repository.turnos;

    final notas = turnos
        .map((turno) => turno.notas)
        .whereType<String>()
        .toList();

    expect(notas, isNotEmpty);

    // Ninguna nota puede superar los 500 caracteres.
    expect(
      notas.every((nota) => nota.length <= 500),
      isTrue,
      reason: 'Ninguna nota debe superar los 500 caracteres.',
    );

    // Al menos una nota debe superar los 300 caracteres.
    expect(
      notas.any((nota) => nota.length > 300),
      isTrue,
      reason: 'Debe existir una nota de más de 300 caracteres.',
    );
  });
}
