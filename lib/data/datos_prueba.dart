import '../core/utils/fechas.dart';
import '../models/cliente.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Todo se crea en memoria. No hay servidor ni persistencia local.
abstract final class DatosPrueba {
  // Primeras seis tarjetas en el mismo orden y con los mismos valores que
  // «Servicios / cuadrícula» en Turco Parcial Design.pen.
  static final servicios = <Servicio>[
    const Servicio(id: 's1', nombre: 'Corte mujer', categoria: CategoriaServicio.corte, duracionMinutos: 60, precio: 30, publico: PublicoServicio.mujeres),
    const Servicio(id: 's2', nombre: 'Corte caballero', categoria: CategoriaServicio.corte, duracionMinutos: 45, precio: 25, publico: PublicoServicio.hombres),
    const Servicio(id: 's4', nombre: 'Color completo', categoria: CategoriaServicio.color, duracionMinutos: 120, precio: 70, publico: PublicoServicio.mujeres),
    const Servicio(id: 's3', nombre: 'Barba', categoria: CategoriaServicio.barba, duracionMinutos: 45, precio: 20, publico: PublicoServicio.hombres),
    const Servicio(id: 's11', nombre: 'Peinado evento', categoria: CategoriaServicio.peinado, duracionMinutos: 60, precio: 40, publico: PublicoServicio.unisex),
    const Servicio(id: 's12', nombre: 'Hidratación', categoria: CategoriaServicio.tratamiento, duracionMinutos: 45, precio: 28, publico: PublicoServicio.unisex),
    const Servicio(id: 's5', nombre: 'Peinado', categoria: CategoriaServicio.peinado, duracionMinutos: 30, precio: 15, publico: PublicoServicio.mujeres),
    const Servicio(id: 's6', nombre: 'Tratamiento', categoria: CategoriaServicio.tratamiento, duracionMinutos: 60, precio: 28, publico: PublicoServicio.unisex),
    const Servicio(id: 's7', nombre: 'Arreglo de barba', categoria: CategoriaServicio.barba, duracionMinutos: 30, precio: 10, publico: PublicoServicio.hombres),
    const Servicio(id: 's8', nombre: 'Corte unisex', categoria: CategoriaServicio.corte, duracionMinutos: 30, precio: 20, publico: PublicoServicio.unisex),
    const Servicio(id: 's9', nombre: 'Alisado', categoria: CategoriaServicio.tratamiento, duracionMinutos: 90, precio: 50, publico: PublicoServicio.mujeres),
    const Servicio(id: 's10', nombre: 'Retoque color', categoria: CategoriaServicio.color, duracionMinutos: 60, precio: 30, publico: PublicoServicio.unisex),
  ];
  // Las rutas de avatar se usarán al agregar los recursos gráficos del .pen.
  static final estilistas = <Estilista>[
    const Estilista(id: '1', nombre: 'Marta Salazar', rutaAvatar: 'assets/images/marta.png', serviciosIds: ['s1', 's4', 's5', 's9']),
    const Estilista(id: '2', nombre: 'Pedro Vega', rutaAvatar: 'assets/images/pedro.png', serviciosIds: ['s2', 's3', 's7']),
    const Estilista(id: '3', nombre: 'Lucía Torres', rutaAvatar: 'assets/images/lucia.png', serviciosIds: ['s1', 's6', 's8', 's10', 's11', 's12']),
    const Estilista(id: '4', nombre: 'Rafael Núñez', rutaAvatar: 'assets/images/andres.png', serviciosIds: ['s2', 's3', 's6', 's7', 's8']),
    const Estilista(id: '5', nombre: 'Valentina', rutaAvatar: 'assets/images/valentina.png', serviciosIds: ['s1', 's4', 's5', 's9', 's10', 's11', 's12']),
  ];

  static List<Cliente> clientes(DateTime ahora) {
    final registro = ahora.subtract(const Duration(days: 45));
    return [
      Cliente(id: 'c1', nombre: 'Laura Gómez', telefono: '71110001', genero: GeneroCliente.mujer, correo: 'laura@example.com', fechaRegistro: registro),
      Cliente(id: 'c2', nombre: 'Carlos Ruiz', telefono: '71110002', genero: GeneroCliente.hombre, fechaRegistro: registro),
      Cliente(id: 'c3', nombre: 'Ana Martín', telefono: '71110003', genero: GeneroCliente.mujer, fechaRegistro: registro),
      Cliente(id: 'c4', nombre: 'Diego Pérez', telefono: '71110004', genero: GeneroCliente.hombre, fechaRegistro: registro),
      Cliente(id: 'c5', nombre: 'Sofía Díaz', telefono: '71110005', genero: GeneroCliente.mujer, fechaRegistro: registro),
      Cliente(id: 'c6', nombre: 'Mateo López', telefono: '71110006', genero: GeneroCliente.hombre, fechaRegistro: registro),
      Cliente(id: 'c7', nombre: 'Camila Torres', telefono: '71110007', genero: GeneroCliente.mujer, fechaRegistro: registro),
      Cliente(id: 'c8', nombre: 'Pablo Castro', telefono: '71110008', genero: GeneroCliente.hombre, fechaRegistro: registro),
      Cliente(id: 'c9', nombre: 'Julieta Silva', telefono: '71110009', genero: GeneroCliente.mujer, fechaRegistro: registro),
      Cliente(id: 'c10', nombre: 'Martín Rojas', telefono: '71110010', genero: GeneroCliente.hombre, fechaRegistro: registro),
    ];
  }

  /// Avanza o retrocede días LABORABLES. Si hoy es domingo, toma el lunes.
  static DateTime _diaLaborable(DateTime hoy, int desplazamiento) {
    var fecha = soloFecha(hoy);
    if (fecha.weekday == DateTime.sunday) {
      fecha = fecha.add(const Duration(days: 1));
    }
    final paso = desplazamiento >= 0 ? 1 : -1;
    for (var i = 0; i < desplazamiento.abs(); i++) {
      do {
        fecha = fecha.add(Duration(days: paso));
      } while (fecha.weekday == DateTime.sunday);
    }
    return fecha;
  }

  static List<Turno> turnos(DateTime ahora) {
    final creacion = ahora.subtract(const Duration(days: 10));
    DateTime inicio(int dia, int hora, [int minuto = 0]) {
      final fecha = _diaLaborable(ahora, dia);
      return DateTime(fecha.year, fecha.month, fecha.day, hora, minuto);
    }

    EstadoTurno segunFecha(DateTime fecha, {bool cancelado = false}) {
      if (fecha.isBefore(ahora)) {
        return cancelado ? EstadoTurno.cancelado : EstadoTurno.completado;
      }
      return EstadoTurno.programado;
    }

    Turno crear(String id, int dia, int hora, int minuto, String clienteId,
        String estilistaId, List<String> servicioIds,
        {bool cancelado = false, String? notas}) {
      final fecha = inicio(dia, hora, minuto);
      return Turno(
        id: id,
        clienteId: clienteId,
        estilistaId: estilistaId,
        serviciosIds: List.unmodifiable(servicioIds),
        inicio: fecha,
        estado: segunFecha(fecha, cancelado: cancelado),
        fechaCreacion: creacion,
        fechaModificacion: creacion,
        notas: notas,
      );
    }

    // Entre 301 y 500 caracteres, como exige el enunciado.
    final notasLargas =
        'La clienta comenta que su cabello quedó sensibilizado tras el último alisado. '
        'Antes de empezar, revisar el estado de las puntas y conversar sobre los productos '
        'que se utilizarán. Evitar temperaturas altas y aplicar protección térmica. '
        'Prefiere un resultado natural y sin exceso de volumen. '
        'Al finalizar, explicar los cuidados recomendados para mantener el tratamiento y '
        'confirmar si siente alguna molestia durante el procedimiento.';

    return [
      // Cinco turnos del día, inspirados en la pantalla de referencia.
      crear('t1', 0, 9, 0, 'c1', '1', ['s1']),
      crear('t2', 0, 10, 0, 'c2', '2', ['s2', 's3']),
      crear('t3', 0, 10, 30, 'c3', '1', ['s4', 's5']),
      crear('t4', 0, 12, 0, 'c4', '2', ['s7'], cancelado: true),
      crear('t5', 0, 14, 0, 'c5', '3', ['s6', 's8'], notas: 'Prefiere poca temperatura.'),
      // Tres días laborables anteriores.
      crear('t6', -3, 9, 0, 'c7', '3', ['s6']),
      crear('t7', -3, 13, 0, 'c8', '2', ['s2'], cancelado: true),
      crear('t8', -2, 11, 0, 'c9', '5', ['s9']),
      crear('t9', -2, 14, 0, 'c6', '4', ['s8']),
      crear('t10', -1, 9, 0, 'c4', '2', ['s7'], cancelado: true),
      crear('t11', -1, 18, 0, 'c1', '1', ['s1']), // Termina exactamente a las 19:00.
      // Tres días laborables posteriores.
      crear('t12', 1, 9, 0, 'c8', '2', ['s2', 's3', 's7']), // Tres servicios.
      crear('t13', 1, 11, 0, 'c9', '5', ['s9'], notas: notasLargas),
      crear('t14', 2, 11, 0, 'c7', '3', ['s6']),
      crear('t15', 2, 13, 30, 'c2', '4', ['s8']),
      crear('t16', 3, 16, 0, 'c5', '3', ['s8', 's12']),
    ];
  }
}
