import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../core/theme/tipografia_detalle.dart';
import '../../core/utils/fechas.dart';
import '../../data/turco_repository.dart';
import '../../models/servicio.dart';
import '../../models/turno.dart';
import '../../models/datos_formulario_turno.dart';
import '../../viewmodels/detalle_turno_viewmodel.dart';

/// RF2: Detalle sobre la barra inferior, conectado al repositorio de Agenda.
class DetalleTurnoView extends StatefulWidget {
  const DetalleTurnoView({
    super.key,
    required this.id,
    required this.repository,
  });

  final String id;
  final TurcoRepository repository;

  @override
  State<DetalleTurnoView> createState() => _DetalleTurnoViewState();
}

class _DetalleTurnoViewState extends State<DetalleTurnoView> {
  late final DetalleTurnoViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = DetalleTurnoViewModel(widget.repository, widget.id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      // También funciona al abrir /turno/:id directamente desde un enlace.
      context.go('/agenda');
    }
  }

  Future<void> _confirmarCambio(EstadoTurno nuevoEstado) async {
    if (!_vm.sePuedeModificar) return;
    final turno = _vm.turno;
    final cliente = _vm.cliente;
    if (turno == null || cliente == null) return;

    final cancelando = nuevoEstado == EstadoTurno.cancelado;
    final aceptado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final esquema = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            cancelando ? Icons.cancel_outlined : Icons.task_alt_outlined,
            color: cancelando ? esquema.error : esquema.tertiary,
          ),
          title: Text(
            cancelando ? '¿Cancelar este turno?' : '¿Completar este turno?',
          ),
          content: Text(
            cancelando
                ? 'El horario de ${cliente.nombre} '
                    '(${horaMinuto(turno.inicio)} a '
                    '${horaMinuto(_vm.fin!)}) quedará libre. '
                    'Esta acción no se puede deshacer.'
                : '¿Confirmás que el turno de ${cliente.nombre} fue '
                    'completado? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                cancelando ? 'Cancelar turno' : 'Completar',
                style: TextStyle(
                  color: cancelando ? esquema.error : esquema.primary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || aceptado != true) return;
    // Vuelve a comprobar el estado: otro cambio podría haber ocurrido mientras
    // el diálogo estaba abierto.
    final guardado = _vm.cambiarEstado(nuevoEstado);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(guardado
          ? (cancelando ? 'Turno cancelado' : 'Turno completado')
          : 'No se pudo modificar el turno.'),
    ));
  }

  Future<void> _editar() async {
    if (!_vm.sePuedeModificar) return;
    final resultado = await context.push<ResultadoTurno>(
        '/turno/${widget.id}/editar');
    if (!mounted || resultado == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Turno actualizado correctamente'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: _volver,
        ),
        titleSpacing: 0,
        title: Text('Detalle del turno', style: t.encabezadoDetalle),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final turno = _vm.turno;
          if (turno == null || _vm.cliente == null || _vm.estilista == null) {
            return _TurnoNoEncontrado(onVolver: () => context.go('/agenda'));
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // Pequeñas pantallas: todo el contenido se desplaza.
                  key: const PageStorageKey('detalle-turno-contenido'),
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.margenHorizontal, 4,
                    Medidas.margenHorizontal, 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HorarioDetalle(vm: _vm, turno: turno),
                      const SizedBox(height: Medidas.detalleSeparacionTarjetas),
                      _ServiciosDetalle(vm: _vm),
                      const SizedBox(height: Medidas.detalleSeparacionTarjetas),
                      _NotasDetalle(notas: turno.notas),
                      const SizedBox(height: Medidas.detalleSeparacionTarjetas),
                      Text(
                        'Creado el ${fechaCorta(turno.fechaCreacion)} · '
                        'Modificado el ${fechaCorta(turno.fechaModificacion)}',
                        style: t.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              _AccionesDetalle(
                estado: turno.estado,
                onEditar: _editar,
                onCompletar: () => _confirmarCambio(EstadoTurno.completado),
                onCancelar: () => _confirmarCambio(EstadoTurno.cancelado),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HorarioDetalle extends StatelessWidget {
  const _HorarioDetalle({required this.vm, required this.turno});

  final DetalleTurnoViewModel vm;
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cliente = vm.cliente!;
    final estilista = vm.estilista!;
    final chip = _coloresEstado(turno.estado, esquema);

    return _TarjetaDetalle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final identidad = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: Medidas.detalleAvatar / 2,
                    backgroundColor: esquema.primaryContainer,
                    child: Text(
                      cliente.nombre.trim().isEmpty
                          ? '?'
                          : cliente.nombre.trim()[0].toUpperCase(),
                      style: t.encabezadoDetalle.copyWith(
                        color: esquema.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.nombreClienteDetalle),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 13, color: esquema.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                cliente.telefono,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelLarge?.copyWith(
                                  color: esquema.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final estado = _EstadoChip(
                etiqueta: chip.etiqueta,
                fondo: chip.fondo,
                texto: chip.texto,
              );
              if (constraints.maxWidth < 310) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identidad, const SizedBox(height: 8), estado],
                );
              }
              return Row(
                children: [
                  Expanded(child: identidad),
                  const SizedBox(width: 5),
                  estado,
                ],
              );
            },
          ),
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          _DatoDetalle(
            icono: Icons.calendar_month_outlined,
            etiqueta: 'Fecha',
            valor: fechaDetalle(turno.inicio),
          ),
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          _DatoDetalle(
            icono: Icons.schedule_outlined,
            etiqueta: 'Hora',
            valor: '${horaMinuto(turno.inicio)} a '
                '${horaMinuto(vm.fin!)} '
                '(${duracionLegible(vm.duracionMinutos)})',
          ),
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          _DatoDetalle(
            icono: Icons.person_outline,
            etiqueta: 'Estilista',
            valor: estilista.nombre,
          ),
        ],
      ),
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: Medidas.detalleIconoDato, color: esquema.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: t.etiquetaDatoDetalle),
              Text(valor, style: t.valorDatoDetalle),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiciosDetalle extends StatelessWidget {
  const _ServiciosDetalle({required this.vm});
  final DetalleTurnoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final servicios = vm.servicios;
    return _TarjetaDetalle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Servicios', style: t.encabezadoSeccionDetalle),
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          for (var i = 0; i < servicios.length; i++) ...[
            if (i != 0) ...[
              const SizedBox(height: Medidas.detalleSeparacionInterna),
              Divider(height: 1, thickness: 1, color: esquema.outlineVariant),
              const SizedBox(height: Medidas.detalleSeparacionInterna),
            ],
            _FilaServicioDetalle(servicio: servicios[i]),
          ],
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          Divider(height: 1, thickness: 1, color: esquema.outlineVariant),
          const SizedBox(height: Medidas.detalleSeparacionInterna),
          Row(
            children: [
              Expanded(
                child: Text('Total', style: t.encabezadoSeccionDetalle),
              ),
              Text(
                '\$ ${vm.precioTotal}',
                style: t.totalDetalle.copyWith(color: esquema.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaServicioDetalle extends StatelessWidget {
  const _FilaServicioDetalle({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(servicio.nombre, style: t.valorDatoDetalle),
              Text('${servicio.duracionMinutos} min', style: t.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('\$ ${servicio.precio}', style: t.precioServicioDetalle),
      ],
    );
  }
}

class _NotasDetalle extends StatelessWidget {
  const _NotasDetalle({required this.notas});
  final String? notas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final texto = notas == null || notas!.trim().isEmpty
        ? 'Sin notas'
        : notas!;
    return _TarjetaDetalle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Notas', style: t.encabezadoSeccionDetalle),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: Medidas.detalleAlturaMaxNotas,
            ),
            // Scroll independiente para las notas extensas (RF2).
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Text(texto, style: t.notasDetalle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDetalle extends StatelessWidget {
  const _TarjetaDetalle({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Medidas.detallePaddingTarjeta),
      decoration: BoxDecoration(
        color: esquema.surfaceContainer,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: child,
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({
    required this.etiqueta,
    required this.fondo,
    required this.texto,
  });
  final String etiqueta;
  final Color fondo;
  final Color texto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medidas.detalleRadioEstado),
      ),
      child: Text(
        etiqueta,
        style: t.labelSmall?.copyWith(
          color: texto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ColoresEstado {
  const _ColoresEstado(this.etiqueta, this.fondo, this.texto);
  final String etiqueta;
  final Color fondo;
  final Color texto;
}

_ColoresEstado _coloresEstado(EstadoTurno estado, ColorScheme esquema) {
  switch (estado) {
    case EstadoTurno.programado:
      return _ColoresEstado(
        'Programado', esquema.primaryContainer, esquema.onPrimaryContainer);
    case EstadoTurno.completado:
      return _ColoresEstado(
        'Completado', esquema.tertiaryContainer, esquema.onTertiaryContainer);
    case EstadoTurno.cancelado:
      return _ColoresEstado(
        'Cancelado', esquema.errorContainer, esquema.onErrorContainer);
  }
}

class _AccionesDetalle extends StatelessWidget {
  const _AccionesDetalle({
    required this.estado,
    required this.onEditar,
    required this.onCompletar,
    required this.onCancelar,
  });

  final EstadoTurno estado;
  final VoidCallback onEditar;
  final VoidCallback onCompletar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: esquema.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: SafeArea(
        top: false,
        child: estado != EstadoTurno.programado
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: esquema.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Turno ${estado == EstadoTurno.completado ? 'completado' : 'cancelado'}: solo lectura',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final editar = OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: esquema.primary,
                      side: BorderSide(color: esquema.outline),
                      minimumSize: const Size(0, Medidas.detalleAltoBoton),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            Medidas.detalleRadioBoton),
                      ),
                    ),
                  );
                  final completar = FilledButton.icon(
                    onPressed: onCompletar,
                    icon: const Icon(Icons.task_alt_outlined, size: 18),
                    label: const Text('Completar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: esquema.secondaryContainer,
                      foregroundColor: esquema.onSecondaryContainer,
                      minimumSize: const Size(0, Medidas.detalleAltoBoton),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            Medidas.detalleRadioBoton),
                      ),
                    ),
                  );
                  final cancelar = TextButton.icon(
                    onPressed: onCancelar,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: esquema.error,
                      minimumSize: const Size(0, Medidas.detalleAltoBoton),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            Medidas.detalleRadioBoton),
                      ),
                    ),
                  );
                  if (constraints.maxWidth < 345) {
                    // En anchos excepcionales no desbordan los tres botones.
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Expanded(child: editar),
                          const SizedBox(width: 6),
                          Expanded(child: completar),
                        ]),
                        SizedBox(width: double.infinity, child: cancelar),
                      ],
                    );
                  }
                  return Row(children: [
                    Expanded(child: editar),
                    const SizedBox(width: 6),
                    Expanded(child: completar),
                    const SizedBox(width: 6),
                    Expanded(child: cancelar),
                  ]);
                },
              ),
      ),
    );
  }
}

class _TurnoNoEncontrado extends StatelessWidget {
  const _TurnoNoEncontrado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 32),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: esquema.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_outlined,
                size: 52, color: esquema.error),
          ),
          const SizedBox(height: 14),
          Text(
            'No encontramos este turno',
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 260,
            child: Text(
              'El turno no existe o ya no está disponible.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onVolver,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver a la agenda'),
          ),
        ],
      ),
    );
  }
}
