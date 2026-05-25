import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/birth_date_utils.dart';
import '../../utils/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/region_label_utils.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/common_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _dateOfBirth;
  String? _selectedRegion;

  final List<String> _regions = RegionLabelUtils.options;

  @override
  void initState() {
    super.initState();
    _selectedRegion = _regions.isNotEmpty ? _regions[0] : null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = BirthDateUtils.fromPicker(picked);
      });
    }
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày sinh'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      bool success = false;
      try {
        success = await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          dateOfBirth: _dateOfBirth!,
          region: RegionLabelUtils.normalize(_selectedRegion!) ?? _selectedRegion!,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(AuthErrorMessages.signupFromException(e)),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          final errorMsg = authProvider.error ?? 'Lỗi đăng ký';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              action: errorMsg.contains('Email này đã được sử dụng')
                  ? SnackBarAction(
                      label: 'Đăng nhập',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                    )
                  : null,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthLayout(
      title: 'Tạo tài khoản',
      subtitle: 'Tham gia cộng đồng tư vấn tuyển sinh & định hướng ngành.',
      showBackToWelcome: true,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: AppStrings.fullName,
                  hint: 'Nhập họ và tên',
                  controller: _fullNameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Họ và tên không được để trống';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMd),

                // Email
                CustomTextField(
                  label: AppStrings.email,
                  hint: 'Nhập email',
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

                // Phone
                CustomTextField(
                  label: AppStrings.phoneNumber,
                  hint: 'Nhập số điện thoại',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Số điện thoại không được để trống';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMd),

                // Date of Birth
                Text(
                  AppStrings.dateOfBirth,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd,
                      vertical: AppDimensions.paddingMd,
                    ),
                    decoration: BoxDecoration(
                      color: context.tc.inputFill,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                      border: Border.all(color: context.tc.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateOfBirth == null
                              ? 'Chọn ngày sinh'
                              : BirthDateUtils.formatVi(_dateOfBirth!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _dateOfBirth == null
                                ? context.tc.textMuted
                                : context.tc.textPrimary,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMd),

                // Region
                Text(
                  AppStrings.region,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMd,
                  ),
                  decoration: BoxDecoration(
                    color: context.tc.inputFill,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(color: context.tc.border),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                      });
                    },
                    items: _regions
                        .map((region) => DropdownMenuItem(
                              value: region,
                              child: Text(region),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMd),

                // Password
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
                const SizedBox(height: AppDimensions.paddingMd),

                // Confirm Password
                CustomTextField(
                  label: AppStrings.confirmPassword,
                  hint: 'Xác nhận mật khẩu',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không trùng khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      label: AppStrings.signUp,
                      isLoading: authProvider.isLoading,
                      onPressed: _handleSignUp,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}
