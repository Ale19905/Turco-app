import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/turco_repository.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'app_router.dart';

class TurcoApp extends StatefulWidget {
  const TurcoApp({super.key});

  @override
  State<TurcoApp> createState() => _TurcoAppState();
}

class _TurcoAppState extends State<TurcoApp> {
  final ThemeViewModel _themeViewModel = ThemeViewModel();
  final TurcoRepository _repository = TurcoRepository();
  late final _router = createAppRouter(_themeViewModel, _repository);

  @override
  void dispose() {
    _router.dispose();
    _themeViewModel.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeViewModel,
      builder: (context, _) => MaterialApp.router(
        title: 'Turco',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeViewModel.themeMode,
        routerConfig: _router,
      ),
    );
  }
}
