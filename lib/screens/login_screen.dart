
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
const emerald = Color(0xFF10B981);
const mint = Color(0xFF6EE7B7);
const darkGreen = Color(0xFF041B14);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool isResettingPassword = false;


  Future<void> login() async {
    if (isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user == null) {
        throw Exception('Login failed');
      }

      // AuthGate handles navigation after sign-in.

    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' => 'Invalid email address.',
        'invalid-credential' || 'wrong-password' =>
        'Incorrect email or password.',
        'user-not-found' => 'Account not found.',
        'too-many-requests' =>
        'Too many attempts. Try again later.',
        'network-request-failed' =>
        'Check your internet connection.',
        _ => 'Unable to sign in. Please try again.',
      };

      _showMessage(message);

    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage('Unable to complete sign in.');

    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email first.');
      return;
    }

    if (isResettingPassword) return;

    setState(() => isResettingPassword = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'If an account exists, a password reset email will be sent.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code}');
      _showMessage('Unable to send password reset email.');
    } catch (e) {
      debugPrint('Password reset error: $e');
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isResettingPassword = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF123D2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: mint,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CareerWise',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: mint),
                      prefixIcon: Icon(Icons.email, color: mint),
                      border: OutlineInputBorder(),
                    ),

                    // Email validation
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Email is required';
                      }

                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(email)) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: mint),
                      prefixIcon:
                      const Icon(Icons.lock, color: mint),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: mint,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading || isResettingPassword
                          ? null
                          : forgotPassword,
                      child: Text(
                        isResettingPassword
                            ? 'Sending...'
                            : 'Forgot Password?',
                        style: const TextStyle(
                          color: mint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),



                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      child: const Text('Sign In'),
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
