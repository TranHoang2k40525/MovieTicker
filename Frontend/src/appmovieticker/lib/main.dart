import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/liquid_glass_theme.dart';
import 'core/widgets/liquid_glass_background.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'package:appmovieticker/features/movies/movie/presentation/pages/movie/movies_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rap chieu phim MTB 67CS1',
        theme: LiquidGlassTheme.build(),
        builder: (context, child) {
          return LiquidGlassBackground(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MoviesPage(),
      ),
    );
  }
}
