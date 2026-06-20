import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuth(),
      child: const MangetoutApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    if (auth.state == AuthState.initial) return null;
    final isAuth = auth.isAuthenticated;
    final isAuthRoute =
        state.matchedLocation == '/' || state.matchedLocation == '/register';
    if (!isAuth && !isAuthRoute) return '/';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/category/:slug',
      builder: (_, __) => const HomeScreen(),
    ),
  ],
);

class MangetoutApp extends StatelessWidget {
  const MangetoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mangetout',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    const spotifyGreen = Color(0xFF1DB954);
    const black = Color(0xFF000000);
    const surface = Color(0xFF121212);
    const card = Color(0xFF181818);
    const elevated = Color(0xFF282828);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFFB3B3B3);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: spotifyGreen,
        onPrimary: black,
        secondary: spotifyGreen,
        onSecondary: black,
        surface: card,
        onSurface: textPrimary,
        surfaceContainerHighest: elevated,
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF535353)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF535353)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: textPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        errorStyle: const TextStyle(color: Color(0xFFCF6679)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: spotifyGreen,
          foregroundColor: black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF282828)),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w900, letterSpacing: -1.5),
        headlineLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineSmall: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary, fontSize: 11),
        labelLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    );
  }
}
