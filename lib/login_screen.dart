import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final Widget destination;

  const LoginScreen({
    super.key,
    required this.destination,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email address and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

final user = credential.user;
var role = 'customer';

if (user != null) {

  final profileReference = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  final profile = await profileReference.get();

if (profile.exists) {
  role = profile.data()?['role'] as String? ?? 'customer';
}

if (!profile.exists) {
    await profileReference.set({
      'name': email.split('@').first,
      'email': email,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => role == 'provider'
    ? const ProviderDashboardScreen()
    : widget.destination,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      if (error.code == 'invalid-email') {
        _showMessage('Enter a valid email address');
      } else if (error.code == 'invalid-credential' ||
          error.code == 'user-not-found' ||
          error.code == 'wrong-password') {
        _showMessage('Incorrect email address or password');
      } else {
        _showMessage(error.message ?? 'Login failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.handyman,
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to SkillLink',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find trusted local skills and services',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(
                          destination: widget.destination,
                        ),
                      ),
                    );
                  },
                  child: const Text('Create a new account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}