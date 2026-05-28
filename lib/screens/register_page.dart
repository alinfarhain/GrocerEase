import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  // ── Input field builder ───────────────────────────────────────────────────

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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red),
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

  // ── Form submission ───────────────────────────────────────────────────────

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
      setState(() => _isLoading = true);
      try {
        final response = await SupabaseService().signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
          data: {'full_name': nameController.text.trim()},
          emailRedirectTo: 'grocerease://login-callback',
        );

        if (mounted && response.user != null) {
          // ── Create the user_profiles row immediately after signup ─────────
          // This ensures budget, dietary preferences, and name are persisted
          // from the very first login.
          await Supabase.instance.client.from('user_profiles').upsert({
            'id': response.user!.id,
            'full_name': nameController.text.trim(),
            'budget': 400.0,
            'dietary_preference': 'None',
          });

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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ── Terms dialog ──────────────────────────────────────────────────────────

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF023047),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Icon(Icons.close,
                          size: 18.0, color: Color(0xFF1B9E56)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms and Conditions for GrocerEase',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5E6472),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Last Updated: May 13, 2026',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Welcome to GrocerEase. These Terms and Conditions ("Terms") govern your use of the GrocerEase mobile application and related services operated by GrocerEase ("we," "our," or "us").\n\n'
                            'By creating an account or using GrocerEase, you agree to these Terms. If you do not agree, please do not use the application.',
                        style:
                        TextStyle(fontSize: 14.0, color: Color(0xFF5E6472)),
                      ),
                      const Divider(height: 32.0),
                      _buildTermsSection('1. About GrocerEase',
                          'GrocerEase is a mobile application designed to assist users with:\n\n• Meal planning\n• Grocery list optimization\n• Pantry tracking\n• Budget tracking\n• Basic health-related meal guidance\n\nThe application is intended for personal and non-commercial use only.'),
                      _buildTermsSection('2. Eligibility',
                          'You must be at least 7 years old to use GrocerEase.\n\nIf you are under the age of majority in your jurisdiction, you must use the application under the supervision of a parent or guardian.'),
                      _buildTermsSection('3. User Accounts',
                          'To access certain features, users must create an account using a valid email address and password.\n\nYou are responsible for:\n\n• Maintaining the confidentiality of your account credentials\n• All activities conducted under your account\n• Providing accurate and updated information\n\nYou may delete your account at any time through the application settings or by contacting support.'),
                      _buildTermsSection('4. Acceptable Use',
                          'Users agree not to:\n\n• Attempt to hack, disrupt, or damage the application\n• Create fake or misleading accounts\n• Upload offensive, abusive, harmful, or inappropriate content\n• Use the application for unlawful purposes\n• Interfere with other users\' experience\n\nWe reserve the right to suspend or permanently ban users who violate these Terms.'),
                      _buildTermsSection('5. User Content',
                          'Users may upload photos within the application.\n\nYou retain ownership of the content you upload. However, by uploading content, you grant GrocerEase a limited, non-exclusive right to store and display the content solely for operating the application.\n\nWe reserve the right to remove any content that violates these Terms or is considered inappropriate.'),
                      _buildTermsSection('6. Privacy and Data Collection',
                          'GrocerEase collects limited personal information, including:\n\n• Name\n• Email address\n\nWe do not collect:\n\n• Payment information\n• Phone numbers\n• Location data\n\nWe do not sell or share your personal information with third parties.\n\nGrocerEase uses Supabase services for backend functionality and analytics.\n\nBy using the application, you consent to the collection and use of information as described in our Privacy Policy.'),
                      _buildTermsSection('7. Health-Related Information Disclaimer',
                          'GrocerEase may provide meal planning suggestions, nutrition-related information, or general health guidance.\n\nThis information is provided for informational purposes only and does not constitute professional medical, dietary, or healthcare advice.\n\nUsers should consult qualified healthcare professionals before making significant dietary or health decisions.'),
                      _buildTermsSection('8. Intellectual Property',
                          'All application content, branding, logos, features, and software related to GrocerEase are owned by GrocerEase unless otherwise stated.\n\nYou may not:\n\n• Copy\n• Modify\n• Reverse engineer\n• Redistribute\n• Commercially exploit\n\nany part of the application without written permission.'),
                      _buildTermsSection('9. Availability of Service',
                          'We strive to keep GrocerEase available and functioning properly at all times. However, we do not guarantee uninterrupted or error-free operation.\n\nThe application is provided on an "as is" and "as available" basis.'),
                      _buildTermsSection('10. Limitation of Responsibility',
                          'While we aim to provide accurate and reliable services, GrocerEase is not responsible for:\n\n• Data loss\n• Inaccurate grocery or budget calculations\n• User-generated content\n• Service interruptions\n• Technical errors\n\nUsers are responsible for verifying important information independently.'),
                      _buildTermsSection('11. Account Suspension and Termination',
                          'We reserve the right to suspend, restrict, or terminate accounts that:\n\n• Violate these Terms\n• Harm other users\n• Abuse the platform\n• Engage in suspicious or illegal activities\n\nTermination may occur without prior notice.'),
                      _buildTermsSection('12. Changes to These Terms',
                          'We may update or modify these Terms at any time.\n\nUpdated Terms will become effective once posted within the application. Continued use of GrocerEase after updates constitutes acceptance of the revised Terms.'),
                      _buildTermsSection('13. Governing Law',
                          'These Terms shall be governed by and interpreted in accordance with the laws of Malaysia.\n\nAny disputes arising from the use of GrocerEase shall be subject to the jurisdiction of the courts of Malaysia.'),
                      _buildTermsSection('14. Contact Information',
                          'For questions or support regarding these Terms, please contact:\n\nEmail: grocerease@gmail.com'),
                      _buildTermsSection('15. Acceptance of Terms',
                          'By creating an account or using GrocerEase, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B9E56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF023047),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF5E6472),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
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
                              () => _isConfirmObscure = !_isConfirmObscure),
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
                                onTap: _showTermsDialog,
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