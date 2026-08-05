import 'package:go_router/go_router.dart';

import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/recover_password/recover_password_screen.dart';

import '../../features/admin/admin_dashboard.txt';

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

import '../../features/dev/migration_page.dart';
import '../../features/profile/profile_purchase_requests_page.dart';
import 'package:flutter_application_1/features/admin/user_page.dart';
import '../../features/admin/user_page.dart';
import '../../features/admin/user_detail_page.dart';
import '../../features/admin/products_page.dart';
import '../../features/admin/categories_page.dart';
import '../../features/admin/transactions_page.dart';
import '../../features/admin/reports_page.dart';
import '../../features/admin/statistics_page.dart';
import '../../features/admin/settings_page.dart';

import '../../features/profile/seller_profile_page.dart';
import '../../features/profile/profile_my_requests_page.dart';

import '../../features/favorites/favorites_page.dart';

final GoRouter router = GoRouter(
  //initialLocation: '/login',
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

    // -----ADMIN-----
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),

    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UsersPage(),
    ),

    GoRoute(
      path: '/admin/user',
      builder: (context, state) {
        final user = state.extra as UserProfile;

        return UserDetailPage(user: user);
      },
    ),

    GoRoute(
      path: '/admin/products',
      builder: (context, state) => const ProductsPage(),
    ),

    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const CategoriesPage(),
    ),

    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const ReportsPage(),
    ),

    GoRoute(path: '/home', builder: (context, state) => const HomePage()),

    GoRoute(
      path: '/admin/transactions',
      builder: (context, state) => const TransactionsPage(),
    ),

    GoRoute(
      path: '/admin/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),

    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // ---- Feature "profile" ----
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) =>
          ProfileEditPage(user: state.extra as UserProfile?),
    ),
    GoRoute(
      path: '/profile/listings',
      builder: (context, state) => const ProfileListingsPage(),
    ),
    GoRoute(
      path: '/profile/history',
      builder: (context, state) => const ProfileHistoryPage(),
    ),
    GoRoute(
      path: '/profile/security',
      builder: (context, state) => const ProfileSecurityPage(),
    ),
    GoRoute(
      path: '/profile/payment-methods',
      builder: (context, state) => const ProfilePaymentMethodsPage(),
    ),
    GoRoute(
      path: '/profile/language',
      builder: (context, state) => const ProfileLanguagePage(),
    ),

    // ---- Feature "product" ----
    GoRoute(
      path: '/search',
      builder: (context, state) => const ProductListPage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) =>
          ProductDetailPage(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/product/:id/edit',
      builder: (context, state) =>
          ProductEditPage(productId: state.pathParameters['id']!),
    ),
    // Crear una publicación nueva. productId null = modo "crear".
    GoRoute(
      path: '/product/new',
      builder: (context, state) => const ProductEditPage(),
    ),
    // Alias usado por el banner/drawer del Home ("Publicar" / "Vender").
    GoRoute(
      path: '/publish',
      builder: (context, state) => const ProductEditPage(),
    ),

    // ... dentro de tu lista de GoRoute:
    GoRoute(
      path: '/dev-migration',
      builder: (context, state) => const MigrationPage(),
    ),
    GoRoute(
      path: '/profile/purchase-requests',
      builder: (context, state) => const ProfilePurchaseRequestsPage(),
    ),
    GoRoute(
      path: '/seller/:id',
      builder: (context, state) =>
          SellerProfilePage(userId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/profile/my-requests',
      builder: (context, state) => const ProfileMyRequestsPage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
  ],
);
