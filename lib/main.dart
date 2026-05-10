import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/routes/app_router.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );
  runApp(const UniControlApp());
}

class UniControlApp extends StatelessWidget {
  const UniControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
          lazy: true,
        ),
        ChangeNotifierProvider<JwtAuthService>(
          create: (_) => JwtAuthService(),
        ),
      ],
      child: Consumer<JwtAuthService>(
        builder: (context, jwtAuthService, _) {
          final authService = context.read<AuthService>();
          final router = AppRouter(
            authService: authService,
            jwtAuthService: jwtAuthService,
          ).router;
          return MaterialApp.router(
            title: 'UniControl UCEVA',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }
}