const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime comienzoSemana(DateTime fecha) =>
    soloFecha(fecha).subtract(Duration(days: fecha.weekday - 1));

String mesAnio(DateTime fecha) {
  final mes = _meses[fecha.month - 1];
  return '${mes[0].toUpperCase()}${mes.substring(1)} ${fecha.year}';
}

String horaMinuto(DateTime fecha) =>
    '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

String fechaLarga(DateTime fecha) =>
    '${diasCortos[fecha.weekday - 1].toLowerCase()} ${fecha.day} de ${_meses[fecha.month - 1]}';

const diasLargos = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

/// Fecha completa que figura en la ficha, según el formato del .pen.
String fechaDetalle(DateTime fecha) =>
    '${diasLargos[fecha.weekday - 1]} ${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';

String fechaCorta(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

String duracionLegible(int minutos) {
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '$resto min';
  if (resto == 0) return '$horas h';
  return '$horas h $resto min';
}
