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
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await AuthService.saveAuthData(
        token: response["token"],
        userId: response["userId"],
        username: response["username"],
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
        horizontal: MediaQuery.sizeOf(context).width * 0.05,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(100),
        color: Theme.of(context).colorScheme.tertiary,
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary.withAlpha(150),
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  width: 0,
                  showIcon: false,
                ),
                const SizedBox(height: 16),
              ],

              InnerShadowInput(
                controller: _emailController,
                hintText: "Email",
                onSubmit: _submit,
                width: 0,
                showIcon: false,
              ),

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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
