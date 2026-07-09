import 'package:go_router/go_router.dart';

import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/recover_password/recover_password_screen.dart';

import '../../features/home/home_page.dart';

import '../../features/profile/profile_page.dart';
import '../../features/profile/profile_edit_page.dart';
import '../../features/profile/profile_listings_page.dart';
import '../../features/profile/profile_history_page.dart';
import '../../features/profile/profile_security_page.dart';
import '../../features/profile/profile_payment_methods_page.dart';
import '../../features/profile/profile_language_page.dart';
import '../../features/profile/models/profile_models.dart';

import '../../features/product/product_list_page.dart';
import '../../features/product/product_detail_page.dart';
import '../../features/product/product_edit_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',

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

    // ---- Feature "profile" ----
    // Pantalla principal de perfil.
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    // Editar perfil: recibe el UserProfile actual por `extra` (ver
    // ProfilePage._openEditProfile) y lo devuelve actualizado al hacer pop.
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) =>
          ProfileEditPage(user: state.extra as UserProfile?),
    ),
    // Publicaciones del usuario: activas / pausadas / vendidas.
    GoRoute(
      path: '/profile/listings',
      builder: (context, state) => const ProfileListingsPage(),
    ),
    // Historial de compras y ventas.
    GoRoute(
      path: '/profile/history',
      builder: (context, state) => const ProfileHistoryPage(),
    ),
    // Privacidad y seguridad: contraseña, biometría, 2FA, sesiones activas.
    GoRoute(
      path: '/profile/security',
      builder: (context, state) => const ProfileSecurityPage(),
    ),
    // Métodos de pago guardados.
    GoRoute(
      path: '/profile/payment-methods',
      builder: (context, state) => const ProfilePaymentMethodsPage(),
    ),
    // Selección de idioma.
    GoRoute(
      path: '/profile/language',
      builder: (context, state) => const ProfileLanguagePage(),
    ),

    // ---- Feature "product" ----
    // Listado/buscador con todos los productos, filtros y orden.
    GoRoute(
      path: '/search',
      builder: (context, state) => const ProductListPage(),
    ),
    // Detalle de un producto (llega desde una ProductCard: /product/1).
    GoRoute(
      path: '/product/:id',
      builder: (context, state) =>
          ProductDetailPage(productId: state.pathParameters['id']!),
    ),
    // Edición de una publicación existente: /product/1/edit
    GoRoute(
      path: '/product/:id/edit',
      builder: (context, state) =>
          ProductEditPage(productId: state.pathParameters['id']!),
    ),
    // Crear una publicación nueva (usada desde "Mis publicaciones").
    // TODO: no conozco la firma real de tu ProductEditPage. Si productId es
    // `required String`, cámbialo por un parámetro opcional o crea un
    // método factory / constructor separado para el modo "crear".
    GoRoute(
      path: '/product/new',
      builder: (context, state) => const ProductEditPage(productId: 'new'),
    ),
  ],
);
