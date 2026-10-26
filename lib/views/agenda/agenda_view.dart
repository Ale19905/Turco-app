import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../core/utils/fechas.dart';
import '../../data/turco_repository.dart';
import '../../models/turno.dart';
import '../../models/datos_formulario_turno.dart';
import '../../viewmodels/agenda_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({
    super.key,
    required this.themeViewModel,
    required this.repository,
    this.estilistaInicial,
  });

  final ThemeViewModel themeViewModel;
  final TurcoRepository repository;
  final String? estilistaInicial;

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  late final AgendaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AgendaViewModel(
      widget.repository,
      estilistaInicial: widget.estilistaInicial,
    );
  }

  @override
  void didUpdateWidget(covariant AgendaView anterior) {
    super.didUpdateWidget(anterior);
    if (widget.estilistaInicial != anterior.estilistaInicial) {
      _vm.filtrarEstilista(widget.estilistaInicial);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _nuevoTurno() async {
    final resultado = await context.push<ResultadoTurno>(
      '/turno/nuevo',
      extra: DatosInicialesTurno(fecha: _vm.fechaSeleccionada),
    );
    if (!mounted || resultado == null) return;
    _vm.seleccionarFecha(resultado.fecha);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Turno guardado correctamente'),
    ));
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vm.fechaSeleccionada,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'Elegir fecha de la agenda',
    );
    if (fecha != null && mounted) _vm.seleccionarFecha(fecha);
  }

  Future<void> _accionesRapidas(Turno turno) async {
    if (turno.estado != EstadoTurno.programado) return;
    final esquema = Theme.of(context).colorScheme;
    final repo = widget.repository;
    final nombre = repo.cliente(turno.clienteId).nombre;
    final servicios = repo.serviciosDe(turno).map((s) => s.nombre).join(' + ');
    final estilista = repo.estilista(turno.estilistaId).nombre;

    final seleccion = await showModalBottomSheet<EstadoTurno>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$nombre · ${horaMinuto(turno.inicio)}',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$servicios · $estilista',
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.task_alt_outlined, color: esquema.tertiary),
                title: const Text('Marcar como completado'),
                onTap: () => Navigator.of(sheetContext).pop(EstadoTurno.completado),
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: esquema.error),
                title: Text('Cancelar turno', style: TextStyle(color: esquema.error)),
                onTap: () => Navigator.of(sheetContext).pop(EstadoTurno.cancelado),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || seleccion == null) return;

    final cancelando = seleccion == EstadoTurno.cancelado;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(cancelando ? Icons.cancel_outlined : Icons.task_alt_outlined,
            color: cancelando
                ? Theme.of(dialogContext).colorScheme.error
                : Theme.of(dialogContext).colorScheme.tertiary),
        title: Text(cancelando ? '¿Cancelar este turno?' : '¿Completar este turno?'),
        content: Text(cancelando
            ? 'El horario de $nombre (${horaMinuto(turno.inicio)} a '
                '${horaMinuto(repo.finDe(turno))}) quedará libre. '
                'Esta acción no se puede deshacer.'
            : '¿Confirmás que el turno de $nombre fue completado? '
                'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(cancelando ? 'Cancelar turno' : 'Completar',
                style: TextStyle(color: cancelando
                    ? Theme.of(dialogContext).colorScheme.error
                    : Theme.of(dialogContext).colorScheme.primary)),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;
    final actualizado = _vm.cambiarEstado(turno.id, seleccion);
    if (actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(cancelando ? 'Turno cancelado' : 'Turno completado'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        titleSpacing: Medidas.margenHorizontal,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colores.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.content_cut, size: 18, color: colores.onPrimary),
          ),
          const SizedBox(width: 12),
          Text('Turco', style: textos.titleLarge),
        ]),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Cambiar tema',
            icon: Icon(widget.themeViewModel.themeMode == ThemeMode.light
                ? Icons.light_mode_outlined
                : widget.themeViewModel.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.brightness_auto_outlined),
            onSelected: widget.themeViewModel.setThemeMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: ThemeMode.system,
                  child: Row(children: [Icon(Icons.brightness_auto_outlined), SizedBox(width: 12), Text('Sistema')])),
              PopupMenuItem(value: ThemeMode.light,
                  child: Row(children: [Icon(Icons.light_mode_outlined), SizedBox(width: 12), Text('Claro')])),
              PopupMenuItem(value: ThemeMode.dark,
                  child: Row(children: [Icon(Icons.dark_mode_outlined), SizedBox(width: 12), Text('Oscuro')])),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      // El formulario devuelve el resultado y sitúa Agenda en la fecha guardada.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoTurno,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo turno'),
        elevation: 3,
        backgroundColor: colores.primaryContainer,
        foregroundColor: colores.onPrimaryContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta)),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final turnos = _vm.turnosFiltrados;
          return ListView.builder(
            key: const PageStorageKey('agenda-scroll'),
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenHorizontal, 4,
              Medidas.margenHorizontal, 110,
            ),
            itemCount: turnos.isEmpty ? 2 : turnos.length + 1,
            itemBuilder: (context, indice) {
              if (indice == 0) {
                return _EncabezadoAgenda(vm: _vm, onElegirFecha: _elegirFecha);
              }
              if (turnos.isEmpty) {
                if (indice == 1) return const _EstadoVacio();
                return const SizedBox.shrink();
              }
              if (indice > turnos.length) return const SizedBox.shrink();
              final turno = turnos[indice - 1];
              return Padding(
                padding: const EdgeInsets.only(top: Medidas.espacioSeccion),
                child: _TarjetaTurno(
                  turno: turno,
                  repository: widget.repository,
                  onTap: () => context.push('/turno/${turno.id}'),
                  onLongPress: turno.estado == EstadoTurno.programado
                      ? () => _accionesRapidas(turno)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EncabezadoAgenda extends StatelessWidget {
  const _EncabezadoAgenda({required this.vm, required this.onElegirFecha});

  final AgendaViewModel vm;
  final VoidCallback onElegirFecha;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Semana(vm: vm, onElegirFecha: onElegirFecha),
        if (vm.turnosDelDia.isNotEmpty) ...[
          const SizedBox(height: Medidas.espacioSeccion),
          _Resumen(vm: vm),
        ],
        const SizedBox(height: Medidas.espacioSeccion),
        _FiltroEstilista(vm: vm),
        const SizedBox(height: Medidas.espacioSeccion),
        _FiltroEstado(vm: vm),
      ],
    );
  }
}

class _Semana extends StatelessWidget {
  const _Semana({required this.vm, required this.onElegirFecha});
  final AgendaViewModel vm;
  final VoidCallback onElegirFecha;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton(
          tooltip: 'Semana anterior',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: () => vm.moverSemana(-1),
        ),
        Flexible(child: Text(mesAnio(vm.fechaSeleccionada),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: t.titleSmall)),
        IconButton(
          tooltip: 'Semana siguiente',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.chevron_right, size: 22),
          onPressed: () => vm.moverSemana(1),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onElegirFecha,
          icon: Icon(Icons.calendar_month_outlined,
              size: 18, color: esquema.primary),
          label: Text('Elegir fecha',
              style: t.labelMedium?.copyWith(color: esquema.primary)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 32),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        final ancho = (constraints.maxWidth - 6 * Medidas.espacioDias) / 7;
        return SizedBox(
          height: Medidas.altoDia,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, indice) {
              final fecha = vm.lunesSemana.add(Duration(days: indice));
              final activo = soloFecha(fecha) == vm.fechaSeleccionada;
              final domingo = fecha.weekday == DateTime.sunday;
              return Padding(
                padding: EdgeInsets.only(
                    right: indice == 6 ? 0 : Medidas.espacioDias),
                child: SizedBox(
                  width: ancho,
                  child: Opacity(
                    opacity: domingo && !activo ? 0.4 : 1,
                    child: Material(
                      color: activo ? esquema.primary : esquema.surface,
                      borderRadius: BorderRadius.circular(Medidas.radioDia),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Medidas.radioDia),
                        onTap: () => vm.seleccionarFecha(fecha),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(diasCortos[indice], style: t.labelSmall?.copyWith(
                                color: activo ? esquema.onPrimary : esquema.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text('${fecha.day}', style: t.titleMedium?.copyWith(
                                color: activo ? esquema.onPrimary : esquema.onSurface,
                                fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
      const SizedBox(height: 8),
      Text('Domingo: salón cerrado', style: t.labelSmall),
    ]);
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vm});
  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    Widget tarjeta(String valor, String titulo) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          borderRadius: BorderRadius.circular(Medidas.radioResumen),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: t.titleLarge?.copyWith(fontSize: 20, color: c.primary)),
          Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: t.labelSmall),
        ]),
      ),
    );
    return Row(children: [
      tarjeta('${vm.totalProgramados}', 'Programados'),
      const SizedBox(width: 8),
      tarjeta('${vm.totalCompletados}', 'Completados'),
      const SizedBox(width: 8),
      tarjeta('\$ ${vm.ingresoEstimado}', 'Ingreso est.'),
    ]);
  }
}

class _FiltroEstilista extends StatelessWidget {
  const _FiltroEstilista({required this.vm});
  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final estilistas = vm.repository.estilistas;
    return SizedBox(
      height: Medidas.altoChip,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: estilistas.length + 1,
        separatorBuilder: (context, index) =>
          const SizedBox(width: Medidas.espacioChips),
        itemBuilder: (context, index) {
          final id = index == 0 ? null : estilistas[index - 1].id;
          final nombre = index == 0 ? 'Todos' : estilistas[index - 1].nombre;
          final seleccionado = vm.estilistaId == id;
          return Material(
            color: seleccionado ? esquema.secondaryContainer : esquema.surface,
            borderRadius: BorderRadius.circular(Medidas.radioChip),
            child: InkWell(
              borderRadius: BorderRadius.circular(Medidas.radioChip),
              onTap: () => vm.filtrarEstilista(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (seleccionado) ...[
                    Icon(Icons.check, size: 14, color: esquema.onSecondaryContainer),
                    const SizedBox(width: 6),
                  ],
                  Text(nombre, style: texto.labelLarge?.copyWith(
                    color: seleccionado ? esquema.onSecondaryContainer : esquema.onSurface,
                  )),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FiltroEstado extends StatelessWidget {
  const _FiltroEstado({required this.vm});
  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final seleccionado = vm.filtroEstado == null ? 0 : vm.filtroEstado!.index + 1;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        showSelectedIcon: true,
        selectedIcon: const Icon(Icons.check, size: 14),
        segments: const [
          ButtonSegment(value: 0, label: Text('Todos')),
          ButtonSegment(value: 1, label: Text('Program.')),
          ButtonSegment(value: 2, label: Text('Complet.')),
          ButtonSegment(value: 3, label: Text('Cancel.')),
        ],
        selected: {seleccionado},
        onSelectionChanged: (valores) {
          final valor = valores.first;
          vm.filtrarEstado(valor == 0 ? null : EstadoTurno.values[valor - 1]);
        },
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, Medidas.altoSegmento)),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 5, vertical: 0)),
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

class _TarjetaTurno extends StatelessWidget {
  const _TarjetaTurno({
    required this.turno,
    required this.repository,
    required this.onTap,
    this.onLongPress,
  });

  final Turno turno;
  final TurcoRepository repository;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final nombre = repository.cliente(turno.clienteId).nombre;
    final estilista = repository.estilista(turno.estilistaId).nombre;
    final servicios = repository.serviciosDe(turno).map((s) => s.nombre).join(' + ');
    final esCancelado = turno.estado == EstadoTurno.cancelado;
    final colorEstado = esCancelado ? esquema.error
        : turno.estado == EstadoTurno.completado ? esquema.tertiary : esquema.primary;
    final fondoEtiqueta = esCancelado ? esquema.errorContainer
        : turno.estado == EstadoTurno.completado
            ? esquema.tertiaryContainer : esquema.primaryContainer;
    final textoEtiqueta = esCancelado ? esquema.onErrorContainer
        : turno.estado == EstadoTurno.completado
            ? esquema.onTertiaryContainer : esquema.onPrimaryContainer;
    final etiqueta = esCancelado ? 'Cancelado'
        : turno.estado == EstadoTurno.completado ? 'Completado' : 'Programado';

    return Opacity(
      opacity: esCancelado ? 0.75 : 1,
      child: Material(
        color: esquema.surfaceContainer,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(width: 4, decoration: BoxDecoration(
                    color: colorEstado, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                SizedBox(width: 48, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(horaMinuto(turno.inicio), style: t.titleSmall),
                    const SizedBox(height: 2),
                    Text(horaMinuto(repository.finDe(turno)), style: t.bodySmall),
                  ],
                )),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: t.titleSmall),
                    const SizedBox(height: 4),
                    Text(servicios, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: t.bodySmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.person_outline, size: 13,
                          color: esquema.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(child: Text(estilista, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelMedium)),
                      Container(
                        decoration: BoxDecoration(
                          color: fondoEtiqueta,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        child: Text(etiqueta,
                          style: t.labelSmall?.copyWith(
                            color: textoEtiqueta, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ],
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: esquema.surfaceContainer,
          ),
          child: Icon(Icons.event_busy_outlined,
              size: 56, color: esquema.primary),
        ),
        const SizedBox(height: 16),
        Text('No hay turnos para este día',
            textAlign: TextAlign.center, style: texto.titleMedium),
        const SizedBox(height: 8),
        Text('Crea el primer turno con el botón de abajo o cambia los filtros.',
            textAlign: TextAlign.center, style: texto.bodyMedium),
      ]),
    );
  }
}
