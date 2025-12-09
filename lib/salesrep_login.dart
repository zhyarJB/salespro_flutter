import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'home_screen.dart';

class SalesRepLoginScreen extends StatefulWidget {
  const SalesRepLoginScreen({Key? key}) : super(key: key);

  @override
  State<SalesRepLoginScreen> createState() => _SalesRepLoginScreenState();
}

class _SalesRepLoginScreenState extends State<SalesRepLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (success) {
          _errorMessage = null;
        } else {
          _errorMessage = 'Invalid email or password';
        }
      });

      if (success) {
        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: ${e.toString().replaceAll('Exception: ', '')}\n\nPlease check:\n1. Server is running on port 8000\n2. CORS is configured\n3. Network connection';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Rep Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _login();
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 