import 'package:flutter/material.dart';
import '../integrations/supabase_service.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;

  bool _isConfirmObscure = true;

  bool _agreedToTerms = false;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF023047),
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14.0,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF1B9E56),
                width: 1.5,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9E9E9E),
                size: 20.0,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms and Conditions'),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await SupabaseService().signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
          data: {'full_name': nameController.text.trim()},
        );
        if (mounted) {
          if (response.user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registration successful! Please check your email for verification.',
                ),
                backgroundColor: Color(0xFF1B9E56),
              ),
            );
            context.pushNamed('login');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F8E9),
              Color(0xFFFFFFFF),
              Color(0xFFFFF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20.0),
                    Center(
                      child: SizedBox(
                        width: 100.0,
                        height: 100.0,
                        child: Image.asset(
                          'assets/GrocerEase Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF023047),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Join GrocerEase and start planning smarter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFF5E6472),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    _buildInputField(
                      label: 'Name',
                      hint: 'Enter your name',
                      controller: nameController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20.0),
                    _buildInputField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$',
                        ).hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    _buildInputField(
                      label: 'Password',
                      hint: 'Create a password',
                      controller: passwordController,
                      isPassword: true,
                      obscureText: _isObscure,
                      onToggleVisibility: () =>
                          setState(() => _isObscure = !_isObscure),
                      validator: (value) => value != null && value.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 20.0),
                    _buildInputField(
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      controller: confirmPasswordController,
                      isPassword: true,
                      obscureText: _isConfirmObscure,
                      onToggleVisibility: () => setState(
                            () => _isConfirmObscure = !_isConfirmObscure,
                      ),
                      validator: (value) => value != passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) =>
                                setState(() => _agreedToTerms = value ?? false),
                            activeColor: const Color(0xFF1B9E56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text(
                                'I agree to the ',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Color(0xFF5E6472),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Terms and Conditions',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFF1B9E56),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),
                    SizedBox(
                      height: 56.0,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B9E56),
                          foregroundColor: Colors.white,
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                            : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Color(0xFF5E6472),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed('login'),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF1B9E56),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
