import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscureNewPassword = true;

  String _getTranslatedError(String error, AppStrings s) {
    if (error.contains('No account found for this phone number')) {
      return s.noAccountForPhone;
    }
    if (error.contains('Phone number not found')) {
      return s.noAccountForPhone;
    }
    if (error.contains('Account not found for this phone number')) {
      return s.noAccountForPhone;
    }
    if (error.toLowerCase().contains('cannot connect') || error.toLowerCase().contains('connection')) {
      return s.langCode == 'lo' ? 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້. ກວດສອບການເຊື່ອມຕໍ່ຂອງທ່ານ.' : 'Cannot connect to server. Please check your connection.';
    }
    if (error == 'Reset password failed') {
      return s.resetPasswordFailed;
    }
    return error;
  }

  
  @override
  void initState() {
    super.initState();
    // Clear any previous errors when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).clearError();
      }
    });
  }

  String _getTranslatedSuccess(String message, AppStrings s) {
    if (message.contains('Password reset successful')) {
      return s.resetSuccessBackend;
    }
    return message;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showToast(String title, String message, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final s = ref.read(languageProvider);
      final result = await ref.read(authControllerProvider.notifier).resetPassword(
        phoneNumber: _phoneController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (result != null && mounted) {
        // Success toast
        _showToast(
          s.resetSuccess,
          s.resetSuccessMessage,
          Colors.green.shade600,
          Icons.check_circle_rounded,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      } else {
        // Error toast
        final error = ref.read(authControllerProvider).error ?? 'Reset password failed';
        _showToast(
          s.error,
          _getTranslatedError(error, s),
          Colors.red.shade600,
          Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final s = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    s.resetPasswordTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.resetPasswordSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Phone Number Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: s.phoneNumber,
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: s.newPassword,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  // if (authState.error != null)
                  //   Container(
                  //     padding: const EdgeInsets.all(12),
                  //     decoration: BoxDecoration(
                  //       color: Colors.red.shade50,
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         Icon(Icons.error, color: Colors.red.shade700),
                  //         const SizedBox(width: 8),
                  //         Expanded(
                  //           child: Text(
                  //             _getTranslatedError(authState.error!, s),
                  //             style: TextStyle(color: Colors.red.shade700),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // if (authState.error != null) const SizedBox(height: 16),

                  // Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              s.resetButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Back to login link
                  TextButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).clearError();
                      context.go('/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: Text(
                      s.backToLogin,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
