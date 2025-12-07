import 'package:flutter/material.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/inner_shadow_input.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/auth_service.dart';

class AuthPopup extends StatefulWidget {
  final bool isSignUp;

  const AuthPopup({super.key, required this.isSignUp});

  static Future<bool?> showSignUp(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const AuthPopup(isSignUp: true);
      },
    );
  }

  static Future<bool?> showLogin(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const AuthPopup(isSignUp: false);
      },
    );
  }

  @override
  State<AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.isSignUp) {
      await _signUp();
    } else {
      await _login();
    }
  }

  Future<void> _signUp() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.signUp(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await AuthService.saveAuthData(
        token: response["token"],
        userId: response["userId"],
        username: response["username"],
        isGuest: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        _showError("Sign up failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      await AuthService.saveAuthData(
        token: response["token"],
        userId: response["userId"],
        username: response["username"],
        isGuest: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        _showError("Login failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hintText,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(100),
        color: Theme.of(context).colorScheme.tertiary,
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 6, right: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            const BoxShadow(color: Color(0xFF5B7B76)),
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary,
              blurRadius: 4,
              spreadRadius: -2,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.tertiary.withAlpha(150),
              fontWeight: FontWeight.bold,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isSignUp ? "SIGN UP" : "LOG IN",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Form fields
                if (widget.isSignUp) ...[
                  InnerShadowInput(
                    controller: _usernameController,
                    hintText: "Username",
                    onSubmit: _submit,
                    width: MediaQuery.sizeOf(context).width * 0.1,
                    showIcon: false,
                  ),
                  const SizedBox(height: 16),
                  InnerShadowInput(
                    controller: _emailController,
                    hintText: "Email",
                    onSubmit: _submit,
                    width: MediaQuery.sizeOf(context).width * 0.1,
                    showIcon: false,
                  ),
                ] else ...[
                  InnerShadowInput(
                    controller: _usernameController,
                    hintText: "Username",
                    onSubmit: _submit,
                    width: MediaQuery.sizeOf(context).width * 0.1,
                    showIcon: false,
                  ),
                ],

                const SizedBox(height: 16),

                _buildPasswordField(_passwordController, "Password"),

                if (widget.isSignUp) ...[
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    _confirmPasswordController,
                    "Confirm Password",
                  ),
                ],

                const SizedBox(height: 24),

                // Submit button
                _isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : RetroButton(
                        text: widget.isSignUp ? "CREATE ACCOUNT" : "LOG IN",
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        onPressed: _submit,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
