import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/credential_storage_service.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  /// true = đăng nhập xong quay lại màn gọi (Hồ sơ, Định hướng…).
  final bool returnOnSuccess;

  const LoginScreen({Key? key, this.returnOnSuccess = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _credentialStorage = CredentialStorageService();

  bool _rememberPassword = false;
  bool _loadingCredentials = true;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _emailController.addListener(_clearLoginError);
    _passwordController.addListener(_clearLoginError);
  }

  void _clearLoginError() {
    if (_loginError != null) {
      setState(() => _loginError = null);
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final remember = await _credentialStorage.isRememberEnabled();
      final saved = await _credentialStorage.loadSaved();
      if (!mounted) return;
      setState(() {
        _rememberPassword = remember;
        if (saved.email != null && saved.email!.isNotEmpty) {
          _emailController.text = saved.email!;
        }
        if (saved.password != null && saved.password!.isNotEmpty) {
          _passwordController.text = saved.password!;
        }
        _loadingCredentials = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCredentials = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearLoginError);
    _passwordController.removeListener(_clearLoginError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _persistCredentialsIfNeeded() async {
    if (_rememberPassword) {
      await _credentialStorage.save(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await _credentialStorage.clear();
    }
  }

  void _navigateAfterLogin(BuildContext context) {
    if (widget.returnOnSuccess && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white.withValues(alpha: 0.95)),
            const SizedBox(width: 10),
            const Expanded(child: Text('Đăng nhập thành công')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loginError = null);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await _persistCredentialsIfNeeded();
      _navigateAfterLogin(context);
    } else {
      setState(() {
        _loginError = authProvider.error ??
            'Không thể đăng nhập. Vui lòng kiểm tra email và mật khẩu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthLayout(
      title: AppStrings.appName,
      subtitle: AppStrings.appTagline,
      showBackToWelcome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loginError != null) ...[
            AppFormAlert(
              title: 'Không đăng nhập được',
              message: _loginError!,
              onDismiss: () => setState(() => _loginError = null),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
          ],
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    label: AppStrings.email,
                    hint: 'Nhập email của bạn',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email không được để trống';
                      }
                      if (!value!.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  CustomTextField(
                    label: AppStrings.password,
                    hint: 'Nhập mật khẩu',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Mật khẩu không được để trống';
                      }
                      if ((value?.length ?? 0) < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Align(
            alignment: Alignment.centerLeft,
            child: CheckboxListTile(
              value: _rememberPassword,
              onChanged: _loadingCredentials
                  ? null
                  : (value) {
                      setState(() {
                        _rememberPassword = value ?? false;
                      });
                    },
              title: const Text(
                AppStrings.rememberPassword,
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(AppStrings.forgotPassword),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return CustomButton(
                label: AppStrings.signIn,
                isLoading: authProvider.isLoading,
                onPressed: _handleLogin,
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Chưa có tài khoản?', style: Theme.of(context).textTheme.bodyMedium),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/signup'),
                child: const Text(AppStrings.signUp),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLg),
        ],
      ),
    );
  }
}
