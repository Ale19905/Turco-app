import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/theme_viewmodel.dart';
import '../data/turco_repository.dart';
import '../models/datos_formulario_turno.dart';
import '../views/turnos/formulario_turno_view.dart';
import '../views/agenda/agenda_view.dart';
import '../views/clientes/clientes_view.dart';
import '../views/estilistas/estilistas_view.dart';
import '../views/turnos/detalle_turno_view.dart';
import '../views/servicios/servicios_view.dart';
import 'app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(ThemeViewModel themeViewModel, TurcoRepository repository) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/agenda',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/agenda',
              builder: (context, state) =>
                  AgendaView(
                    themeViewModel: themeViewModel,
                    repository: repository,
                    estilistaInicial: state.uri.queryParameters['estilista'],
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/clientes',
              builder: (context, state) => ClientesView(repository: repository),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servicios',
              builder: (context, state) => ServiciosView(repository: repository),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/estilistas',
              builder: (context, state) => EstilistasView(repository: repository),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/turno/nuevo',
      builder: (context, state) => FormularioTurnoView(
        repository: repository,
        iniciales: state.extra is DatosInicialesTurno
            ? state.extra as DatosInicialesTurno : null,
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/turno/:id/editar',
      builder: (context, state) => FormularioTurnoView(
        repository: repository,
        turnoId: state.pathParameters['id'],
      ),
    ),
    // En el navegador raíz: la barra inferior no se muestra en Detalle.
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/turno/:id',
      builder: (context, state) => DetalleTurnoView(
        id: state.pathParameters['id']!,
        repository: repository,
      ),
    ),
  ],
);
