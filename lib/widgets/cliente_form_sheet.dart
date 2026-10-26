import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/turco_repository.dart';
import '../models/cliente.dart';

/// Se reutilizará también desde la pantalla Clientes (RF4).
Future<Cliente?> mostrarFormularioCliente(
  BuildContext context, TurcoRepository repository, {Cliente? cliente}
) => showModalBottomSheet<Cliente>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => _ClienteFormSheet(repository: repository, cliente: cliente),
);

class _ClienteFormSheet extends StatefulWidget {
  const _ClienteFormSheet({required this.repository, this.cliente});
  final TurcoRepository repository;
  final Cliente? cliente;

  @override
  State<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<_ClienteFormSheet> {
  final _clave = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final TextEditingController _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final TextEditingController _correo = TextEditingController(text: widget.cliente?.correo);
  final _telefonoFocus = FocusNode();
  final _correoFocus = FocusNode();
  GeneroCliente? _genero;
  bool _errorGenero = false;

  @override
  void initState() {
    super.initState();
    _genero = widget.cliente?.genero;
  }

  @override
  void dispose() {
    _nombre.dispose(); _telefono.dispose(); _correo.dispose();
    _telefonoFocus.dispose(); _correoFocus.dispose();
    super.dispose();
  }

  void _guardar() {
    final camposValidos = _clave.currentState!.validate();
    setState(() => _errorGenero = _genero == null);
    if (!camposValidos || _genero == null) return;
    final ahora = DateTime.now();
    final c = Cliente(
      id: widget.cliente?.id ?? 'c${ahora.microsecondsSinceEpoch}',
      nombre: _nombre.text.trim(), telefono: _telefono.text.trim(),
      genero: _genero!, correo: _correo.text.trim().isEmpty ? null : _correo.text.trim(),
      fechaRegistro: widget.cliente?.fechaRegistro ?? ahora,
    );
    final error = widget.repository.guardarCliente(c, edicion: widget.cliente != null);
    if (error == null) {
      Navigator.of(context).pop(c);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final medios = MediaQuery.of(context);
    final altoDisponible = medios.size.height - medios.viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: medios.viewInsets.bottom),
      child: SizedBox(
        height: altoDisponible * .82,
        child: Form(
          key: _clave,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(children: [
                Expanded(child: Text(widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
                  style: Theme.of(context).textTheme.titleLarge)),
                IconButton(onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close), tooltip: 'Cerrar'),
              ]),
            ),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
              TextFormField(
                controller: _nombre, textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => v == null || v.trim().length < 3 || v.trim().length > 60
                  ? 'El nombre debe tener entre 3 y 60 caracteres' : null,
                onFieldSubmitted: (_) => _telefonoFocus.requestFocus(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefono, focusNode: _telefonoFocus,
                keyboardType: TextInputType.phone, textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (v) {
                  if (!RegExp(r'^\d{8}$').hasMatch(v?.trim() ?? '')) {
                    return 'El teléfono debe tener 8 dígitos';
                  }
                  if (widget.repository.clientes.any((c) =>
                      c.telefono == v!.trim() && c.id != widget.cliente?.id)) {
                    return 'Ese teléfono ya está registrado';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _correoFocus.requestFocus(),
              ),
              const SizedBox(height: 14),
              Text('Género', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 7),
              SegmentedButton<GeneroCliente>(
                segments: const [
                  ButtonSegment(value: GeneroCliente.mujer, label: Text('Mujer')),
                  ButtonSegment(value: GeneroCliente.hombre, label: Text('Hombre')),
                ],
                emptySelectionAllowed: true,
                selected: _genero == null ? {} : {_genero!},
                onSelectionChanged: (s) => setState(() {
                  _genero = s.isEmpty ? null : s.first;
                  _errorGenero = false;
                }),
              ),
              if (_errorGenero) Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Selecciona un género', style: TextStyle(color: esquema.error, fontSize: 12)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _correo, focusNode: _correoFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                validator: (v) => v == null || v.trim().isEmpty ||
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                    ? null : 'Ingresá un correo válido',
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 16),
            ])),
            SafeArea(top: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: _guardar,
                    child: const Text('Guardar cliente'))),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}
