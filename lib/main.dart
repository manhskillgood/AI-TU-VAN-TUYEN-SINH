import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/chat_provider.dart';
import 'providers/career_guidance_provider.dart';
import 'services/ai_service.dart';
import 'services/guidance_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'models/login_route_args.dart';
import 'screens/home/home_screen.dart';
import 'widgets/app_shell.dart';
import 'screens/charts/charts_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
import 'screens/forum/forum_screen.dart';
import 'screens/career_guidance/career_guidance_screen.dart';
import 'screens/career_guidance/guidance_history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'providers/recommender_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/recommender_demo.dart';
import 'utils/theme_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    debugPrint('Existing Firebase apps before init: ${Firebase.apps.map((a) => a.name).join(', ')}');
    if (Firebase.apps.isEmpty) {
      debugPrint('Calling Firebase.initializeApp()');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase.initializeApp() completed');

      // Activate Firebase App Check so requests include valid App Check tokens.
      // Use Play Integrity on Android and DeviceCheck on iOS. For web, set
      // `webRecaptchaSiteKey` if you use web and have a reCAPTCHA site key.
      try {
        // Use debug provider during development (kDebugMode) so App Check
        // works on local/dev devices without Play Integrity setup. Switch to
        // Play Integrity for production.
        if (kDebugMode) {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
          );
        } else {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.deviceCheck,
          );
        }
      } catch (e) {
        debugPrint('Firebase App Check activation failed: $e');
      }

      // Disable reCAPTCHA enforcement completely for testing
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    } else {
      debugPrint('Firebase already initialized, skipping initializeApp()');
    }
  } catch (e) {
    // Common non-fatal case: duplicate-app. Log and continue.
    final msg = e.toString();
    if (msg.contains('duplicate-app') || msg.contains('already exists')) {
      debugPrint('Firebase already initialized elsewhere: $e');
    } else {
      debugPrint('Firebase initialization error: $e');
    }
  }
  
  // Initialize AI Service. Read API key from --dart-define=GEN_AI_KEY=<key>.
  const genAiKey = String.fromEnvironment('GEN_AI_KEY');
  if (genAiKey.isEmpty) {
    debugPrint('GEN_AI_KEY not provided. Run with --dart-define=GEN_AI_KEY=<YOUR_KEY>');
  }

  try {
    _aiService = AIService(apiKey: genAiKey);
  } catch (e) {
    debugPrint('AIService initialization failed: $e');
    // Fallback to empty key to avoid null issues; calls will fail until a valid key is provided.
    _aiService = AIService(apiKey: '');
  }
  // Guidance dataset will be loaded from the SplashScreen to avoid
  // blocking startup work on the main thread.

  runApp(const AppRoot());
}

// Global AI Service instance
late AIService _aiService;

// Getter for AI Service
AIService get aiService => _aiService;

/// Gốc widget — đăng ký toàn bộ Provider tại đây (tránh null sau hot reload).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) {
            final provider = ThemeProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider<auth.AuthProvider>(
          create: (_) => auth.AuthProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<CareerGuidanceProvider>(
          create: (_) => CareerGuidanceProvider(),
        ),
        ChangeNotifierProvider<RecommenderProvider>(
          create: (_) => RecommenderProvider(),
        ),
      ],
      child: const _AppMaterial(),
    );
  }
}

class _AppMaterial extends StatelessWidget {
  const _AppMaterial();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Tư vấn ngành học',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.themeMode,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final returnOnSuccess =
              args is LoginRouteArgs && args.returnOnSuccess;
          return LoginScreen(returnOnSuccess: returnOnSuccess);
        },
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/charts': (context) => const ChartsTrendsScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/forum': (context) => const ForumScreen(),
        '/guidance': (context) => const CareerGuidanceScreen(),
        '/guidance-history': (context) => const GuidanceHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminShellScreen(),
        '/recommender_demo': (context) => const RecommenderDemoScreen(),
      },
    );
  }
}

/// Alias giữ tương thích test / import cũ.
typedef MyApp = AppRoot;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();

    // Load guidance dataset in background (do not await to avoid blocking UI)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await GuidanceService.initializeDataset();
        debugPrint('Guidance dataset initialized from SplashScreen');
      } catch (e) {
        debugPrint('Guidance dataset load failed: $e');
      }
    });
  }

  _navigateToHome() async {
    final authProvider = context.read<auth.AuthProvider>();
    await authProvider.restoreSession();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppGradientBackdrop(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: tc.cardShadow,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<auth.AuthProvider>().restoreSession();
    });
  }

  List<Widget> get _screens => [
    HomeScreen(onOpenProfile: () => setState(() => _selectedIndex = 5)),
    const ChartsTrendsScreen(),
    const ChatbotScreen(),
    const ForumScreen(),
    const CareerGuidanceScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackdrop(child: _screens[_selectedIndex]),
      bottomNavigationBar: AppStyledNavigationBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Biểu đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Chat AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Diễn đàn',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Định hướng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
