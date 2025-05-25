import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/signup.dart';
import 'package:fit_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
        // Navigation will be handled automatically by AuthWrapper
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during login: ${e.code} - ${e.message}");

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Login error: ${e.message ?? 'Please try again.'}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("General exception during login: $e");

      if (mounted) {
        // Check if user actually got logged in despite the error
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Color(0xFF06402B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in successful!'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
        // Navigation will be handled automatically by AuthWrapper
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}");

      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Google sign-in error: ${e.message ?? 'Please try again.'}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("General exception during Google sign-in: $e");

      if (mounted) {
        // Check if user actually got logged in despite the error
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google sign-in successful!'),
              backgroundColor: Color(0xFF06402B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google sign-in failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Error sending reset email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/brain.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with opacity
          Container(
            color: Colors.white.withOpacity(0.7),
          ),
          // Your existing content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100.withOpacity(0.6),
                  Colors.green.shade50.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06402B)),
                        ),
                        SizedBox(height: 20),

                        // Email/Password Section
                        Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: _buildTextField(
                            label: "Email",
                            icon: Icons.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildPasswordField(
                          label: "Password",
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          toggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text("Forgot Password?",
                                style: TextStyle(color: Color(0xFF06402B))),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Email Login Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Color(0xFF06402B),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Login",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),

                        SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("OR",
                                  style: TextStyle(color: Colors.grey[600])),
                            ),
                            Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Google Sign-In Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size(double.infinity, 50),
                            side: BorderSide(color: Color(0xFF06402B)),
                          ),
                          onPressed:
                          _isGoogleLoading ? null : _signInWithGoogle,
                          icon: _isGoogleLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : Image.asset(
                            'assets/google_icon.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.account_circle,
                                  color: Color(0xFF06402B));
                            },
                          ),
                          label: Text(
                            _isGoogleLoading
                                ? "Signing in..."
                                : "Continue with Google",
                            style: TextStyle(
                                color: Color(0xFF06402B), fontSize: 16),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Sign Up Link
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpWidget()));
                          },
                          child: Text("Don't have an account? Sign up",
                              style: TextStyle(
                                  color: Color(0xFF06402B), fontSize: 16)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF06402B)),
        prefixIcon: Icon(
          icon,
          color: Color(0xFF06402B),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Color(0xFF06402B)),
        labelStyle: TextStyle(color: Color(0xFF06402B)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF06402B)),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
        ),
      ),
    );
  }
}