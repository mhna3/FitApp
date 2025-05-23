import 'package:fit_app/signup.dart';
import 'package:flutter/material.dart';
import 'package:fit_app/apiController.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:
      Scaffold( 
        body:
      Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF06402B)),
                  ),
                  SizedBox(height: 20),
                  Padding(padding: EdgeInsets.only(bottom: 20),
                  child: 
                  _buildTextField(
                    label: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains("@")) {
                        return "Enter a valid email";
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
                      onPressed: () {
                        // Handle forgot password
                        print("Forgot password pressed");
                      },
                      child: Text("Forgot Password?", style: TextStyle(color:Color(0xFF06402B), )),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Color(0xFF06402B),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => NutritionixApp()));
                        print("Login successful");
                      }
                    },
                    child: Text("Login",style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpWidget()));
                    },
                    child: Text("Don't have an account? Sign up",style: TextStyle(color: Color(0xFF06402B), fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
     ),
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
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF06402B)),
        prefixIcon: Icon(icon, color: Color(0xFF06402B),),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF06402B), width: 2 ),
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
          return 'Please enter $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Color(0xFF06402B),),
        labelStyle: TextStyle(color: Color(0xFF06402B)),
        
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Color(0xFF06402B)),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF06402B), width: 2 ),
      ),
      ),
    );
  }
}
