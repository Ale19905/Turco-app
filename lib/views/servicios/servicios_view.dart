import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../data/turco_repository.dart';
import '../../models/datos_formulario_turno.dart';
import '../../models/servicio.dart';
import '../../viewmodels/servicios_viewmodel.dart';

/// RF5. El catálogo es de solo lectura. Las reglas y los filtros viven en VM.
class ServiciosView extends StatefulWidget {
  const ServiciosView({super.key, required this.repository});

  final TurcoRepository repository;

  @override
  State<ServiciosView> createState() => _ServiciosViewState();
}

class _ServiciosViewState extends State<ServiciosView> {
  late final ServiciosViewModel _vm;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = ServiciosViewModel(widget.repository);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _cambiarCategoria(CategoriaServicio? categoria) {
    _vm.cambiarCategoria(categoria);
    _volverAlInicio();
  }

  void _cambiarPublico(FiltroPublicoServicios filtro) {
    _vm.cambiarPublico(filtro);
    _volverAlInicio();
  }

  void _volverAlInicio() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  Future<void> _reservar(Servicio servicio) async {
    final resultado = await context.push<ResultadoTurno>(
      '/turno/nuevo',
      extra: DatosInicialesTurno(servicioId: servicio.id),
    );
    if (!mounted || resultado == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turno guardado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Medidas.serviciosAlturaBarra,
        titleSpacing: Medidas.margenHorizontal,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicios', style: tema.textTheme.titleLarge?.copyWith(fontSize: 20)),
            Text('Toca un servicio para reservar',
                style: tema.textTheme.bodySmall),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final servicios = _vm.serviciosVisibles;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenHorizontal, 4, Medidas.margenHorizontal, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _filtrosCategoria(context),
                const SizedBox(height: Medidas.serviciosSeparacionCabecera),
                _filtroPublico(context),
                const SizedBox(height: Medidas.serviciosSeparacionCabecera),
                Expanded(
                  child: servicios.isEmpty
                      ? _sinResultados(context)
                      : _cuadricula(context, servicios),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filtrosCategoria(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final categorias = <CategoriaServicio?>[
      null,
      ...CategoriaServicio.values,
    ];

    return SizedBox(
      height: Medidas.serviciosAltoCategoria,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        key: const PageStorageKey('servicios-categorias'),
        itemCount: categorias.length,
        separatorBuilder: (_, index) =>
            const SizedBox(width: Medidas.espacioChips),
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final seleccionado = _vm.categoria == categoria;
          return FilterChip(
            label: Text(_nombreCategoria(categoria)),
            selected: seleccionado,
            showCheckmark: seleccionado,
            checkmarkColor: esquema.onSecondaryContainer,
            onSelected: (_) => _cambiarCategoria(categoria),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: seleccionado
                  ? esquema.onSecondaryContainer
                  : esquema.onSurfaceVariant,
            ),
            backgroundColor: esquema.surface,
            selectedColor: esquema.secondaryContainer,
            side: seleccionado
                ? BorderSide.none
                : BorderSide(color: esquema.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            labelPadding: const EdgeInsets.symmetric(horizontal: 3),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Medidas.radioChip),
            ),
          );
        },
      ),
    );
  }

  Widget _filtroPublico(BuildContext context) {
    return SizedBox(
      height: Medidas.serviciosAltoPublico,
      child: SegmentedButton<FiltroPublicoServicios>(
        showSelectedIcon: true,
        expandedInsets: EdgeInsets.zero,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: const [
          ButtonSegment(value: FiltroPublicoServicios.todos,
              label: Text('Todos')),
          ButtonSegment(value: FiltroPublicoServicios.mujeres,
              label: Text('Mujeres')),
          ButtonSegment(value: FiltroPublicoServicios.hombres,
              label: Text('Hombres')),
        ],
        selected: {_vm.publico},
        onSelectionChanged: (seleccion) => _cambiarPublico(seleccion.first),
      ),
    );
  }

  Widget _cuadricula(BuildContext context, List<Servicio> servicios) {
    // RF5: columnas según el ancho físico de la pantalla en dp, no los filtros.
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho < 600 ? 2 : (ancho <= 840 ? 3 : 4);

    return GridView.builder(
      key: const PageStorageKey('servicios-cuadricula'),
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: Medidas.margenHorizontal),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        crossAxisSpacing: Medidas.serviciosSeparacion,
        mainAxisSpacing: Medidas.serviciosSeparacion,
        mainAxisExtent: Medidas.serviciosAltoTarjeta,
      ),
      itemCount: servicios.length,
      itemBuilder: (context, index) {
        final servicio = servicios[index];
        return _tarjetaServicio(context, servicio);
      },
    );
  }

  Widget _tarjetaServicio(BuildContext context, Servicio servicio) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final estiloNombre = tema.textTheme.titleSmall?.copyWith(fontSize: 14);

    return Material(
      color: esquema.surfaceContainer,
      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      child: InkWell(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        onTap: () => _reservar(servicio),
        child: Padding(
          padding: const EdgeInsets.all(Medidas.serviciosPaddingTarjeta),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: Medidas.serviciosAltoImagen,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: esquema.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    Medidas.serviciosRadioImagen,
                  ),
                ),
                child: Image.asset(
                  _imagenCategoria(servicio.categoria),
                  width: Medidas.serviciosTamanoIcono,
                  height: Medidas.serviciosTamanoIcono,
                  color: esquema.primary,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ilustración de ${_nombreCategoria(servicio.categoria)}',
                ),
              ),
              const SizedBox(height: Medidas.serviciosSeparacionInterior),
              Text(
                servicio.nombre,
                style: estiloNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Medidas.serviciosSeparacionInterior),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: esquema.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text('${servicio.duracionMinutos} min',
                      style: tema.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text('\$ ${servicio.precio}',
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: esquema.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Medidas.serviciosSeparacionInterior),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: esquema.secondaryContainer,
                  borderRadius: BorderRadius.circular(Medidas.radioChip),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  child: Text(
                    _nombrePublico(servicio.publico),
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: esquema.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sinResultados(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.margenHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined, color: esquema.primary, size: 52),
              const SizedBox(height: Medidas.serviciosSeparacion),
              Text('No hay servicios para estos filtros',
                textAlign: TextAlign.center,
                style: tema.textTheme.titleMedium,
              ),
              const SizedBox(height: Medidas.espacioChips),
              Text('Probá otra categoría o público.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: Medidas.serviciosSeparacion),
              TextButton(
                onPressed: () {
                  _vm.cambiarCategoria(null);
                  _vm.cambiarPublico(FiltroPublicoServicios.todos);
                  _volverAlInicio();
                },
                child: const Text('Ver todos los servicios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _nombreCategoria(CategoriaServicio? categoria) => switch (categoria) {
  null => 'Todas',
  CategoriaServicio.corte => 'Corte',
  CategoriaServicio.color => 'Color',
  CategoriaServicio.barba => 'Barba',
  CategoriaServicio.peinado => 'Peinado',
  CategoriaServicio.tratamiento => 'Tratamiento',
};

String _nombrePublico(PublicoServicio publico) => switch (publico) {
  PublicoServicio.mujeres => 'Mujeres',
  PublicoServicio.hombres => 'Hombres',
  PublicoServicio.unisex => 'Unisex',
};

String _imagenCategoria(CategoriaServicio categoria) => switch (categoria) {
  CategoriaServicio.corte => 'assets/images/servicio_corte.png',
  CategoriaServicio.color => 'assets/images/servicio_color.png',
  CategoriaServicio.barba => 'assets/images/servicio_barba.png',
  CategoriaServicio.peinado => 'assets/images/servicio_peinado.png',
  CategoriaServicio.tratamiento => 'assets/images/servicio_tratamiento.png',
};
