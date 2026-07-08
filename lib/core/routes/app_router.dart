import 'package:go_router/go_router.dart';

import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/recover_password/recover_password_screen.dart';

import '../../features/home/home_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',

  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/recover-password',
      builder: (context, state) => const RecoverPasswordScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],

  redirect: (context, state) {
    final bool loggedIn = false;

    final bool goingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/recover-password';

    if (!loggedIn && !goingToAuth) return '/login';
    if (loggedIn && goingToAuth) return '/home';
    return null;
  },
);
