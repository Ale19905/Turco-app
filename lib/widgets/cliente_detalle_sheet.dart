import 'package:flutter/material.dart';

import '../core/utils/fechas.dart';
import '../models/cliente.dart';
import '../models/turno.dart';
import '../viewmodels/clientes_viewmodel.dart';

enum AccionDetalleCliente { nuevoTurno, editar, eliminar }

Future<AccionDetalleCliente?> mostrarDetalleCliente(
  BuildContext context,
  ClientesViewModel viewModel,
  String clienteId,
) => showModalBottomSheet<AccionDetalleCliente>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheetContext) => _DetalleCliente(
    viewModel: viewModel,
    clienteId: clienteId,
  ),
);

class _DetalleCliente extends StatelessWidget {
  const _DetalleCliente({required this.viewModel, required this.clienteId});

  final ClientesViewModel viewModel;
  final String clienteId;

  @override
  Widget build(BuildContext context) {
    final altoPantalla = MediaQuery.sizeOf(context).height;
    final alto = (altoPantalla * .64).clamp(0.0, 560.0).toDouble();
    final colores = Theme.of(context).colorScheme;
    return SizedBox(
      height: alto,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final cliente = viewModel.repository.clientesPorId[clienteId];
          if (cliente == null) {
            return const Center(child: Text('Este cliente ya no está disponible.'));
          }
          final historial = viewModel.historial(clienteId);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                _cabecera(context, cliente),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Historial de turnos · ${historial.length}',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: historial.isEmpty
                      ? Center(child: Text('Este cliente no tiene turnos registrados.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.separated(
                          itemCount: historial.length,
                          itemBuilder: (context, index) => _filaTurno(
                              context, historial[index]),
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                        ),
                ),
                const SizedBox(height: 12),
                _acciones(context, colores),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecera(BuildContext context, Cliente cliente) {
    final colores = Theme.of(context).colorScheme;
    final esMujer = cliente.genero == GeneroCliente.mujer;
    final fondo = esMujer ? colores.primaryContainer : colores.tertiaryContainer;
    final texto = esMujer ? colores.onPrimaryContainer : colores.onTertiaryContainer;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: fondo,
          child: Text(cliente.nombre.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22, color: texto)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cliente.nombre,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.phone_outlined, size: 13, color: colores.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_mostrarTelefono(cliente.telefono),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13)),
              ]),
              if (cliente.correo != null && cliente.correo!.trim().isNotEmpty)
                Row(children: [
                  Icon(Icons.mail_outline, size: 13, color: colores.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(cliente.correo!, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13)),
                  ),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaTurno(BuildContext context, Turno turno) {
    final colores = Theme.of(context).colorScheme;
    final estado = switch (turno.estado) {
      EstadoTurno.programado => 'Programado',
      EstadoTurno.completado => 'Completado',
      EstadoTurno.cancelado => 'Cancelado',
    };
    final fondo = switch (turno.estado) {
      EstadoTurno.programado => colores.primaryContainer,
      EstadoTurno.completado => colores.tertiaryContainer,
      EstadoTurno.cancelado => colores.errorContainer,
    };
    final texto = switch (turno.estado) {
      EstadoTurno.programado => colores.onPrimaryContainer,
      EstadoTurno.completado => colores.onTertiaryContainer,
      EstadoTurno.cancelado => colores.onErrorContainer,
    };
    final servicios = viewModel.repository.serviciosDe(turno)
        .map((servicio) => servicio.nombre).join(' + ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text('${fechaCorta(turno.inicio).substring(0, 5)} · $servicios',
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400))),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(estado, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11, color: texto)),
        ),
      ]),
    );
  }

  Widget _acciones(BuildContext context, ColorScheme colores) {
    void devolver(AccionDetalleCliente accion) => Navigator.of(context).pop(accion);
    final anchoEstrecho = MediaQuery.sizeOf(context).width < 350;
    return SafeArea(
      top: false,
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: () => devolver(AccionDetalleCliente.nuevoTurno),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo turno', maxLines: 1),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 46,
          child: anchoEstrecho
              ? OutlinedButton(
                  onPressed: () => devolver(AccionDetalleCliente.editar),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18),
                )
              : OutlinedButton.icon(
                  onPressed: () => devolver(AccionDetalleCliente.editar),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 46, height: 46,
          child: IconButton.filledTonal(
            tooltip: 'Eliminar cliente',
            onPressed: () => devolver(AccionDetalleCliente.eliminar),
            icon: const Icon(Icons.delete_outline, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colores.errorContainer,
              foregroundColor: colores.onErrorContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

String _mostrarTelefono(String telefono) => telefono.length == 8
    ? '${telefono.substring(0, 2)} ${telefono.substring(2, 5)} ${telefono.substring(5)}'
    : telefono;
