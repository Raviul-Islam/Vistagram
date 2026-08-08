import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/home/presentation/pages/home_page.dart';
import 'features/explore/presentation/pages/explore_page.dart';
import 'features/post/presentation/pages/add_post_page.dart';
import 'features/reels/presentation/pages/reels_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';
import 'features/auth/data/auth_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/chat/presentation/pages/inbox_page.dart';
import 'features/chat/presentation/pages/new_chat_page.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'shared/widgets/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: VistagramApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    if (state.uri.path == '/splash') {
      return null;
    }

    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return null;

    final isAuthenticated = authState.value != null;
    final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/signup';
      
    if (!isAuthenticated && !isLoggingIn) return '/login';
    if (isAuthenticated && isLoggingIn) return '/';
      
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewChatPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final chatTitle = state.extra as String? ?? 'Chat';
          return ChatPage(chatId: chatId, chatTitle: chatTitle);
        },
      ),
      GoRoute(
        path: '/edit_profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExplorePage(),
          ),
          GoRoute(
            path: '/post',
            builder: (context, state) {
              final imagePath = state.extra as String?;
              return AddPostPage(initialImagePath: imagePath);
            },
          ),
          GoRoute(
            path: '/reels',
            builder: (context, state) => const ReelsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return ProfilePage(userId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class VistagramApp extends ConsumerWidget {
  const VistagramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vistagram',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
