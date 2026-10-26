import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medidas.dart';
import '../../data/turco_repository.dart';
import '../../models/servicio.dart';
import '../../viewmodels/estilistas_viewmodel.dart';

/// RF6: CustomScrollView, SliverAppBar pinned/expandible y SliverList.
class EstilistasView extends StatefulWidget {
  const EstilistasView({super.key, required this.repository});

  final TurcoRepository repository;

  @override
  State<EstilistasView> createState() => _EstilistasViewState();
}

class _EstilistasViewState extends State<EstilistasView> {
  late final EstilistasViewModel _vm;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = EstilistasViewModel(widget.repository);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final items = _vm.estilistas;
          return CustomScrollView(
            key: const PageStorageKey<String>('estilistas-scroll'),
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: Medidas.estilistasAlturaCabecera,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: colores.primary,
                foregroundColor: colores.onPrimary,
                automaticallyImplyLeading: false,
                flexibleSpace: _cabecera(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenHorizontal,
                  Medidas.estilistasMargenSuperior,
                  Medidas.margenHorizontal,
                  Medidas.margenHorizontal,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1
                            ? 0
                            : Medidas.estilistasSeparacion,
                      ),
                      child: _tarjeta(context, items[index]),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabecera(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final altoMinimo = kToolbarHeight + MediaQuery.paddingOf(context).top;
        final contraido = constraints.maxHeight < altoMinimo + 44;
        return SafeArea(
          bottom: false,
          child: contraido
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.estilistasPaddingCabecera,
                    ),
                    child: Text(
                      'Estilistas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleLarge?.copyWith(
                        color: colores.onPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.estilistasPaddingCabecera,
                    8,
                    Medidas.estilistasPaddingCabecera,
                    Medidas.estilistasPaddingInferiorCabecera,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: Medidas.estilistasIconoCabecera,
                        color: colores.onPrimary,
                      ),
                      const SizedBox(height: Medidas.estilistasGapCabecera),
                      Text(
                        'Estilistas',
                        style: tema.textTheme.headlineSmall?.copyWith(
                          color: colores.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: Medidas.estilistasGapCabecera),
                      Text(
                        '${_vm.totalProfesionales} profesionales · '
                        '${_vm.programadosHoy} turnos programados hoy',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: colores.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _tarjeta(BuildContext context, ResumenEstilista resumen) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final estilista = resumen.estilista;
    final nombre = estilista.nombre.trim();
    final inicial = nombre.isEmpty ? '?' : nombre.substring(0, 1).toUpperCase();

    return Material(
      color: colores.surfaceContainer,
      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          '/agenda?estilista=${Uri.encodeComponent(estilista.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(Medidas.estilistasPaddingTarjeta),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: Medidas.estilistasAvatar / 2,
                backgroundColor: colores.primaryContainer,
                child: Text(
                  inicial,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontSize: Medidas.estilistasTextoAvatar,
                    fontWeight: FontWeight.w600,
                    color: colores.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: Medidas.estilistasGapTarjeta),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colores.onSurface,
                      ),
                    ),
                    const SizedBox(height: Medidas.estilistasGapContenido),
                    Wrap(
                      spacing: Medidas.estilistasGapCategorias,
                      runSpacing: Medidas.estilistasGapCategorias,
                      children: [
                        for (final categoria in resumen.categorias)
                          _chipCategoria(
                            context,
                            categoria,
                            resumen.serviciosPorCategoria[categoria]!,
                          ),
                      ],
                    ),
                    const SizedBox(height: Medidas.estilistasGapContenido),
                    Text(
                      _etiquetaTurnos(resumen.programadosHoy),
                      style: tema.textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        color: resumen.programadosHoy == 0
                            ? colores.onSurfaceVariant
                            : colores.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Medidas.estilistasGapChevron),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: Medidas.estilistasIconoChevron,
                  color: colores.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipCategoria(
    BuildContext context,
    CategoriaServicio categoria,
    List<Servicio> servicios,
  ) {
    final colores = Theme.of(context).colorScheme;
    return Tooltip(
      message: servicios.map((s) => s.nombre).join(', '),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: Medidas.estilistasAltoChip,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Medidas.estilistasPaddingChip,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colores.outlineVariant),
          borderRadius: BorderRadius.circular(Medidas.radioChip),
        ),
        child: Text(
          _nombreCategoria(categoria),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colores.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static String _nombreCategoria(CategoriaServicio categoria) => switch (categoria) {
    CategoriaServicio.corte => 'Corte',
    CategoriaServicio.color => 'Color',
    CategoriaServicio.barba => 'Barba',
    CategoriaServicio.peinado => 'Peinado',
    CategoriaServicio.tratamiento => 'Tratamiento',
  };

  static String _etiquetaTurnos(int cantidad) => switch (cantidad) {
    0 => 'Sin turnos hoy',
    1 => '1 turno hoy',
    _ => '$cantidad turnos hoy',
  };
}
