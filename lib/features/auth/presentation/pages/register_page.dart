import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankbookController = TextEditingController();
  final _vbCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Backend validation errors
  String? _usernameError;
  bool _isCheckingUsername = false;

  @override
  void dispose() {
    _bankbookController.dispose();
    _vbCodeController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getTranslatedError(String error, AppStrings s) {
    if (error.contains('Invalid village code or bankbook number')) {
      return s.invalidClientInfo;
    }
    if (error.contains('Invalid phone number, village code, or bankbook number')) {
      return s.invalidClientInfo;
    }
    if (error.contains('Username is already taken')) {
      return s.usernameTaken;
    }
    if (error.contains('You already have an account')) {
      return s.alreadyHaveAccount;
    }
    if (error.contains('Password and confirm password do not match')) {
      return s.passwordConfirmMismatch;
    }
    if (error.contains('bankbookNumber must be shorter than or equal to 5 characters')) {
      return s.bankbookTooLong;
    }
    if (error.toLowerCase().contains('cannot connect') || error.toLowerCase().contains('connection')) {
      return s.langCode == 'lo' ? 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້. ກວດສອບການເຊື່ອມຕໍ່ຂອງທ່ານ.' : 'Cannot connect to server. Please check your connection.';
    }
    if (error == 'Registration failed') {
      return s.registrationFailed;
    }
    return error;
  }

  // Real-time username availability check
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.checkUsernameAvailability(username);
      
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          if (!result['available']) {
            _usernameError = result['message'] ?? 'Username is already taken';
          } else {
            _usernameError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = null; // Don't show error for network issues, just clear
        });
      }
    }
  }

  // Debounced username check
  Timer? _usernameCheckTimer;
  void _onUsernameChanged(String value) {
    _usernameCheckTimer?.cancel();
    _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkUsernameAvailability(value);
      }
    });
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

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final s = ref.read(languageProvider);
      final result = await ref.read(authControllerProvider.notifier).register(
        bankbookNumber: _bankbookController.text.trim(),
        vbCode: _vbCodeController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (result != null && mounted) {
        // Success toast
        _showToast(
          s.registerSuccess,
          s.registerSuccessMessage,
          Colors.green.shade600,
          Icons.check_circle_rounded,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      } else {
        // Error toast
        final error = ref.read(authControllerProvider).error ?? 'Registration failed';
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
                    s.registerTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.registerSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bankbook Number Field
                  TextFormField(
                    controller: _bankbookController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.bankbookNumber,
                      prefixIcon: const Icon(Icons.book_outlined),
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

                  // Village Code Field
                  TextFormField(
                    controller: _vbCodeController,
                    decoration: InputDecoration(
                      labelText: s.vbCode,
                      prefixIcon: const Icon(Icons.location_on_outlined),
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

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: s.username,
                      prefixIcon: _isCheckingUsername 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _usernameError != null ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      errorText: _usernameError,
                      errorStyle: const TextStyle(color: Colors.red),
                      suffixIcon: _usernameError != null
                          ? const Icon(Icons.error, color: Colors.red, size: 20)
                          : (_usernameController.text.length >= 3 && _usernameError == null && !_isCheckingUsername)
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : null,
                    ),
                    onChanged: _onUsernameChanged,
                  ),
                  const SizedBox(height: 16),

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

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
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
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: s.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                    obscureText: _obscureConfirmPassword,
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

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _register,
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
                              s.registerButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Already have account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.haveAccount,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).clearError();
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        child: Text(
                          s.loginNow,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
