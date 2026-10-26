import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../core/utils/fechas.dart';
import '../../data/turco_repository.dart';
import '../../models/datos_formulario_turno.dart';
import '../../models/servicio.dart';
import '../../viewmodels/formulario_turno_viewmodel.dart';
import '../../widgets/cliente_form_sheet.dart';

/// RF3. Un mismo Form para crear/editar, con VM y persistencia solo en memoria.
class FormularioTurnoView extends StatefulWidget {
  const FormularioTurnoView({super.key, required this.repository, this.turnoId, this.iniciales});
  final TurcoRepository repository;
  final String? turnoId;
  final DatosInicialesTurno? iniciales;

  @override
  State<FormularioTurnoView> createState() => _FormularioTurnoViewState();
}

class _FormularioTurnoViewState extends State<FormularioTurnoView> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _clienteKey = GlobalKey();
  final _serviciosKey = GlobalKey();
  final _estilistaKey = GlobalKey();
  final _fechaKey = GlobalKey();
  final _horaKey = GlobalKey();
  final _clienteFocus = FocusNode();
  final _serviciosFocus = FocusNode();
  final _estilistaFocus = FocusNode();
  final _fechaFocus = FocusNode();
  final _horaFocus = FocusNode();
  final _notasFocus = FocusNode();
  late final TextEditingController _notas;
  late final FormularioTurnoViewModel _vm;
  bool _permitirSalida = false;
  String? _errorGuardar;

  @override
  void initState() {
    super.initState();
    _vm = FormularioTurnoViewModel(widget.repository,
        turnoId: widget.turnoId, iniciales: widget.iniciales);
    _notas = TextEditingController(text: _vm.notas);
  }

  @override
  void dispose() {
    _scroll.dispose(); _notas.dispose(); _vm.dispose();
    _clienteFocus.dispose(); _serviciosFocus.dispose();
    _estilistaFocus.dispose(); _fechaFocus.dispose();
    _horaFocus.dispose(); _notasFocus.dispose();
    super.dispose();
  }

  void _enfocarPrimerError() {
    GlobalKey? clave;
    FocusNode? foco;
    if (_vm.errorCliente != null) {
      clave = _clienteKey; foco = _clienteFocus;
    } else if (_vm.errorServicios != null) {
      clave = _serviciosKey; foco = _serviciosFocus;
    } else if (_vm.errorEstilista != null) {
      clave = _estilistaKey; foco = _estilistaFocus;
    } else if (_vm.errorFecha != null) {
      clave = _fechaKey; foco = _fechaFocus;
    } else if (_vm.errorHora != null) {
      clave = _horaKey; foco = _horaFocus;
    } else if (_notas.text.length > 500) {
      _notasFocus.requestFocus();
    }
    if (foco != null) foco.requestFocus();
    final objetivo = clave;
    if (objetivo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final contexto = objetivo.currentContext;
        if (contexto != null) {
          Scrollable.ensureVisible(contexto,
              duration: const Duration(milliseconds: 280),
              alignment: .12, curve: Curves.easeInOut);
        }
      });
    }
  }

  void _guardar() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _errorGuardar = null; });
    final valido = _formKey.currentState!.validate();
    if (!valido || _vm.errorServicios != null ||
        _vm.errorHora != null || _vm.errorFecha != null) {
      _enfocarPrimerError();
      return;
    }
    final error = _vm.guardar();
    if (error != null) {
      setState(() => _errorGuardar = error);
      _enfocarPrimerError();
      return;
    }
    final resultado = _vm.ultimoGuardado;
    if (!mounted || resultado == null) return;
    setState(() => _permitirSalida = true);
    context.pop<ResultadoTurno>(resultado);
  }

  Future<void> _salir() async {
    if (_permitirSalida || !_vm.tieneCambios) {
      _cerrar(); return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(c).colorScheme.error),
        title: const Text('¿Descartar los cambios?'),
        content: const Text('Tienes cambios sin guardar en este turno. Si sales ahora se perderán.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Seguir editando')),
          TextButton(onPressed: () => Navigator.of(c).pop(true),
              child: Text('Descartar', style: TextStyle(color: Theme.of(c).colorScheme.error))),
        ],
      ),
    );
    if (!mounted || descartar != true) return;
    _cerrar();
  }

  void _cerrar() {
    setState(() => _permitirSalida = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/agenda');
    }
  }

  Future<void> _elegirFecha(FormFieldState<DateTime> campo) async {
    final hoy = soloFecha(DateTime.now());
    var inicial = _vm.fecha ?? hoy;
    if (inicial.isBefore(hoy)) inicial = hoy;
    if (inicial.weekday == DateTime.sunday) {
      inicial = inicial.add(const Duration(days: 1));
    }
    final seleccion = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoy,
      lastDate: DateTime(2100, 12, 31),
      selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
      helpText: 'Elegir fecha del turno',
    );
    if (seleccion != null && mounted) {
      campo.didChange(seleccion);
      _vm.elegirFecha(seleccion);
    }
  }

  Future<void> _crearCliente() async {
    final cliente = await mostrarFormularioCliente(context, widget.repository);
    if (!mounted || cliente == null) return;
    _vm.elegirCliente(cliente.id);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente registrado correctamente')));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _permitirSalida,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          toolbarHeight: 56,
          leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Volver',
            onPressed: _salir),
          title: Text(_vm.editando ? 'Editar turno' : 'Nuevo turno',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        ),
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) => !_vm.editable
            ? Center(child: Padding(padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Este turno no existe o ya no se puede editar.'),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _salir, child: const Text('Volver')),
                ])))
            : Column(children: [
                Expanded(child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(Medidas.margenHorizontal, 4,
                        Medidas.margenHorizontal, 20),
                    children: [
                      _campoCliente(),
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerLeft,
                        child: TextButton.icon(onPressed: _crearCliente,
                          icon: const Icon(Icons.person_add_alt_1, size: 17),
                          label: const Text('Crear cliente nuevo'))),
                      const SizedBox(height: 8),
                      _filtroPublico(),
                      const SizedBox(height: 14),
                      _campoServicios(esquema),
                      const SizedBox(height: 14),
                      _campoEstilista(),
                      const SizedBox(height: 14),
                      _campoFecha(),
                      const SizedBox(height: 14),
                      _campoHoras(esquema),
                      const SizedBox(height: 14),
                      _campoNotas(),
                    ],
                  ),
                )),
                _barraInferior(esquema),
              ]),
        ),
      ),
    );
  }

  Widget _campoCliente() => Focus(
    focusNode: _clienteFocus,
    child: Column(key: _clienteKey, crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _etiqueta('Cliente'),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('cliente-${_vm.clienteId}'),
          initialValue: _vm.clienteId,
          isExpanded: true,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline),
              hintText: 'Selecciona un cliente'),
          items: widget.repository.clientes.map((c) => DropdownMenuItem(
              value: c.id, child: Text(c.nombre, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => _vm.elegirCliente(v),
          validator: (_) => _vm.errorCliente,
        ),
      ],
    ),
  );

  Widget _filtroPublico() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _etiqueta('Servicios para'),
      const SizedBox(height: 4),
      SizedBox(width: double.infinity, child: SegmentedButton<FiltroPublico>(
        showSelectedIcon: true,
        segments: const [
          ButtonSegment(value: FiltroPublico.todos, label: Text('Todos')),
          ButtonSegment(value: FiltroPublico.mujeres, label: Text('Mujeres')),
          ButtonSegment(value: FiltroPublico.hombres, label: Text('Hombres')),
        ],
        selected: {_vm.publico},
        onSelectionChanged: (v) => _vm.cambiarPublico(v.first),
      )),
    ],
  );

  Widget _campoServicios(ColorScheme esquema) {
    final visibles = _vm.serviciosVisibles;
    return Focus(focusNode: _serviciosFocus, child: FormField<bool>(
      validator: (_) => _vm.errorServicios,
      builder: (campo) => Column(
        key: _serviciosKey, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Servicios', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final categoria in CategoriaServicio.values)
            if (visibles.any((s) => s.categoria == categoria)) ...[
              Text(categoria.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Wrap(spacing: 8, runSpacing: 6,
                children: visibles.where((s) => s.categoria == categoria).map((s) {
                  final seleccionado = _vm.serviciosIds.contains(s.id);
                  return FilterChip(
                    label: Text(s.nombre),
                    selected: seleccionado, showCheckmark: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (_) {
                      final limpiado = _vm.alternarServicio(s.id);
                      campo.didChange(_vm.serviciosIds.isNotEmpty);
                      if (limpiado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Se quitó el estilista: no realiza todos los servicios seleccionados.',
                            ),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 9),
            ],
          if (_vm.serviciosIds.any((id) => !visibles.any((s) => s.id == id)))
            Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Text('Hay servicios seleccionados fuera de este filtro.',
                  style: Theme.of(context).textTheme.bodySmall)),
          if (campo.hasError) _errorBajoCampo(campo.errorText!, esquema),
        ],
      ),
    ));
  }

  Widget _campoEstilista() => Focus(focusNode: _estilistaFocus,
    child: Column(key: _estilistaKey, crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _etiqueta('Estilista'),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('estilista-${_vm.estilistaId}'),
          initialValue: _vm.estilistaId,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.content_cut),
            hintText: _vm.serviciosIds.isEmpty
                ? 'Primero elige los servicios' : 'Selecciona un estilista'),
          items: _vm.estilistasCompatibles.map((e) => DropdownMenuItem(
            value: e.id, child: Text(e.nombre))).toList(),
          onChanged: _vm.serviciosIds.isEmpty ? null : (v) => _vm.elegirEstilista(v),
          validator: (_) => _vm.errorEstilista,
        ),
        const SizedBox(height: 6),
        Text('Solo se muestran estilistas que realizan todos los servicios elegidos.',
          style: Theme.of(context).textTheme.labelSmall),
      ],
    ));

  Widget _campoFecha() => Focus(focusNode: _fechaFocus,
    child: FormField<DateTime>(
      initialValue: _vm.fecha,
      validator: (_) => _vm.errorFecha,
      builder: (campo) => Column(key: _fechaKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiqueta('Fecha'), const SizedBox(height: 4),
          InkWell(onTap: () => _elegirFecha(campo), borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                errorText: campo.errorText,
              ),
              child: Text(_vm.fecha == null ? 'Selecciona una fecha' : fechaDetalle(_vm.fecha!),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    ));

  Widget _campoHoras(ColorScheme esquema) => Focus(focusNode: _horaFocus,
    child: FormField<int>(
      initialValue: _vm.minutos,
      validator: (_) => _vm.errorHora,
      builder: (campo) => Column(key: _horaKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _etiqueta('Hora de inicio'),
          const SizedBox(height: 6),
          Wrap(spacing: 13, runSpacing: 5, children: [
            _leyenda(esquema.primaryContainer, 'Libre', esquema),
            _leyenda(esquema.surfaceContainerHighest, 'No disponible', esquema),
            _leyenda(esquema.primary, 'Elegida', esquema),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vm.franjas.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth < 335 ? 3 : 4,
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.05),
            itemBuilder: (context, index) {
              final minuto = _vm.franjas[index];
              final libre = _vm.franjaLibre(minuto);
              final elegido = _vm.minutos == minuto;
              return OutlinedButton(
                onPressed: libre ? () {
                  campo.didChange(minuto);
                  _vm.elegirHora(minuto);
                } : null,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: elegido ? esquema.primary : libre
                    ? esquema.surface : esquema.surfaceContainer,
                  foregroundColor: elegido ? esquema.onPrimary : esquema.onSurface,
                  disabledForegroundColor: esquema.onSurfaceVariant,
                  side: BorderSide(color: elegido ? esquema.primary :
                    libre ? esquema.outline : esquema.surfaceContainerHighest),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_vm.horaTexto(minuto), style: const TextStyle(fontSize: 12)),
              );
            },
          )),
          if (!_vm.tieneFranjasLibres)
            Padding(padding: const EdgeInsets.only(top: 8),
              child: Text('No hay franjas disponibles con la selección actual.',
                style: Theme.of(context).textTheme.bodySmall)),
          if (campo.hasError) _errorBajoCampo(campo.errorText!, esquema),
        ],
      ),
    ));

  Widget _campoNotas() => Column(crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _etiqueta('Notas (opcional)'),
      const SizedBox(height: 4),
      TextFormField(
        controller: _notas, focusNode: _notasFocus,
        textInputAction: TextInputAction.done,
        minLines: 3, maxLines: 5, maxLength: 500,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(hintText: 'Indicaciones especiales para el turno'),
        onChanged: _vm.cambiarNotas,
        validator: (v) => v != null && v.length > 500
          ? 'Máximo 500 caracteres' : null,
      ),
    ],
  );

  Widget _barraInferior(ColorScheme esquema) {
    final t = Theme.of(context).textTheme;
    return Container(
      color: esquema.surfaceContainer,
      child: SafeArea(top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: esquema.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _datoResumen(Icons.schedule, duracionLegible(_vm.duracion), esquema),
                _datoResumen(Icons.access_time, 'Fin ${_vm.horaFin == null ? '--:--' : horaMinuto(_vm.horaFin!)}', esquema),
                _datoResumen(Icons.payments_outlined, '\$ ${_vm.precio}', esquema),
              ]),
            ),
            if (_errorGuardar != null) Padding(padding: const EdgeInsets.only(top: 5),
              child: Text(_errorGuardar!, style: t.labelSmall?.copyWith(color: esquema.error))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _salir,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46),
                  shape: const StadiumBorder()), child: const Text('Cancelar'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _guardar,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Guardar turno', maxLines: 1),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: const StadiumBorder()))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _datoResumen(IconData icono, String texto, ColorScheme esquema) =>
    Expanded(child: FittedBox(fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: esquema.primary),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: esquema.onPrimaryContainer,
            fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ));

  Widget _etiqueta(String texto) => Text(texto,
    style: Theme.of(context).textTheme.labelMedium);

  Widget _leyenda(Color color, String texto, ColorScheme esquema) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3),
          border: Border.all(color: esquema.outlineVariant))),
      const SizedBox(width: 5),
      Text(texto, style: Theme.of(context).textTheme.labelSmall),
    ]);

  Widget _errorBajoCampo(String texto, ColorScheme esquema) =>
    Padding(padding: const EdgeInsets.only(top: 4, left: 12),
      child: Text(texto, style: TextStyle(color: esquema.error, fontSize: 12)));
}
