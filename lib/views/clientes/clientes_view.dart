import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../data/turco_repository.dart';
import '../../models/cliente.dart';
import '../../models/datos_formulario_turno.dart';
import '../../viewmodels/clientes_viewmodel.dart';
import '../../widgets/cliente_detalle_sheet.dart';
import '../../widgets/cliente_form_sheet.dart';

/// RF4. Lista de clientes con filtros, historial y acciones en hojas inferiores.
class ClientesView extends StatefulWidget {
  const ClientesView({super.key, required this.repository});
  final TurcoRepository repository;

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  late final ClientesViewModel _vm;
  final _busqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ClientesViewModel(widget.repository);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _nuevoCliente() async {
    final creado = await mostrarFormularioCliente(context, widget.repository);
    if (!mounted || creado == null) return;
    _aviso('Cliente registrado correctamente');
  }

  Future<void> _abrirCliente(Cliente cliente) async {
    final accion = await mostrarDetalleCliente(context, _vm, cliente.id);
    if (!mounted || accion == null) return;
    switch (accion) {
      case AccionDetalleCliente.nuevoTurno:
        final resultado = await context.push<ResultadoTurno>(
          '/turno/nuevo', extra: DatosInicialesTurno(clienteId: cliente.id),
        );
        if (!mounted || resultado == null) return;
        _aviso('Turno guardado correctamente');
        return;
      case AccionDetalleCliente.editar:
        final editado = await mostrarFormularioCliente(
          context, widget.repository, cliente: cliente,
        );
        if (!mounted || editado == null) return;
        _aviso('Cliente actualizado correctamente');
        return;
      case AccionDetalleCliente.eliminar:
        await _eliminarCliente(cliente);
        return;
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final pendientes = _vm.programados(cliente.id);
    if (pendientes > 0) {
      final error = 'No se puede eliminar: ${cliente.nombre} tiene $pendientes '
          '${pendientes == 1 ? 'turno programado' : 'turnos programados'}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            if (mounted) _abrirCliente(cliente);
          },
        ),
      ));
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colores = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_outline, color: colores.error),
          title: Text('¿Eliminar a ${cliente.nombre}?'),
          content: const Text('Se eliminará el cliente junto con su historial '
              'de turnos completados y cancelados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Eliminar', style: TextStyle(color: colores.error)),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmar != true) return;
    final error = _vm.eliminarCliente(cliente.id);
    _aviso(error ?? 'Cliente eliminado correctamente');
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        titleSpacing: Medidas.margenHorizontal,
        title: Text('Clientes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 22),
            tooltip: 'Nuevo cliente',
            onPressed: _nuevoCliente,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoCliente,
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
        label: const Text('Nuevo cliente'),
        backgroundColor: colores.primaryContainer,
        foregroundColor: colores.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta)),
      ),
      // Una sola lista desplazable: los filtros también pueden salir del área
      // visible cuando se abre el teclado o el dispositivo está en horizontal.
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final visibles = _vm.clientesFiltrados;
          return ListView.separated(
            key: const PageStorageKey('clientes-lista'),
            padding: const EdgeInsets.fromLTRB(Medidas.margenHorizontal, 4,
                Medidas.margenHorizontal, 110),
            itemCount: visibles.isEmpty ? 2 : visibles.length + 1,
            separatorBuilder: (context, index) => index == 0
                ? const SizedBox.shrink()
                : Divider(height: 1, thickness: 1, color: colores.outlineVariant),
            itemBuilder: (context, index) {
              if (index == 0) return _controles(context);
              if (visibles.isEmpty) return _estadoVacio(context);
              return _filaCliente(context, visibles[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _controles(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final selector = SegmentedButton<FiltroGeneroClientes>(
      showSelectedIcon: true,
      segments: const [
        ButtonSegment(value: FiltroGeneroClientes.todos, label: Text('Todos')),
        ButtonSegment(value: FiltroGeneroClientes.mujeres, label: Text('Mujeres')),
        ButtonSegment(value: FiltroGeneroClientes.hombres, label: Text('Hombres')),
      ],
      selected: {_vm.filtro},
      onSelectionChanged: (seleccion) => _vm.cambiarFiltro(seleccion.first),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: _busqueda,
            onChanged: _vm.cambiarBusqueda,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o teléfono',
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              prefixIcon: Icon(Icons.search,
                  color: colores.onSurfaceVariant, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              fillColor: colores.surfaceContainerHigh,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colores.primary, width: 1.5),
              ),
              suffixIcon: _vm.busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _busqueda.clear();
                        _vm.cambiarBusqueda('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, restricciones) => restricciones.maxWidth < 330
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal, child: selector)
              : SizedBox(width: double.infinity, child: selector),
        ),
        const SizedBox(height: 10),
        Text('${_vm.total} clientes · ${_vm.totalMujeres} mujeres · '
            '${_vm.totalHombres} hombres',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _estadoVacio(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final buscando = _vm.busqueda.trim().isNotEmpty ||
        _vm.filtro != FiltroGeneroClientes.todos;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 58, color: esquema.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(buscando ? 'No se encontraron clientes' : 'Aún no hay clientes',
              style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(buscando ? 'Probá con otra búsqueda o filtro.'
              : 'Registrá el primer cliente para comenzar.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _filaCliente(BuildContext context, Cliente cliente) {
    final esquema = Theme.of(context).colorScheme;
    final mujer = cliente.genero == GeneroCliente.mujer;
    final turnos = _vm.cantidadTurnos(cliente.id);
    return InkWell(
      onTap: () => _abrirCliente(cliente),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: mujer ? esquema.primaryContainer : esquema.tertiaryContainer,
            child: Text(cliente.nombre.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18, fontWeight: FontWeight.w600,
                color: mujer ? esquema.onPrimaryContainer : esquema.onTertiaryContainer)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cliente.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 1),
              Text('${_telefonoVisible(cliente.telefono)} · ${mujer ? 'Mujer' : 'Hombre'}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 8),
          Text('$turnos ${turnos == 1 ? 'turno' : 'turnos'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

String _telefonoVisible(String telefono) => telefono.length == 8
    ? '${telefono.substring(0, 2)} ${telefono.substring(2, 5)} ${telefono.substring(5)}'
    : telefono;
