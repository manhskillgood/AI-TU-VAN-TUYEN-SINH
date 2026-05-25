import 'package:flutter/material.dart';
import 'package:education_guidance_app/screens/admin/rule_management_screen.dart';
import 'package:education_guidance_app/screens/charts/charts_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String charts = '/charts';
  static const String chatbot = '/chatbot';
  static const String forum = '/forum';
  static const String guidance = '/guidance';
  static const String profile = '/profile';
  static const String ruleManagement = '/admin/rules';
}

class RouteManager {
  static Map<String, WidgetBuilder> routes() {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signup: (context) => const SignUpScreen(),
      AppRoutes.home: (context) => const MainScreen(),
      AppRoutes.charts: (context) => const ChartsTrendsScreen(),
      AppRoutes.chatbot: (context) => const ChatbotScreen(),
      AppRoutes.forum: (context) => const ForumScreen(),
      AppRoutes.guidance: (context) => const CareerGuidanceScreen(),
      AppRoutes.ruleManagement: (context) => const RuleManagementScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
    };
  }
}

// Placeholder imports - replace with actual imports
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

// real RuleManagementScreen is imported from screens/admin

class ForumScreen extends StatelessWidget {
  const ForumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class CareerGuidanceScreen extends StatelessWidget {
  const CareerGuidanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
