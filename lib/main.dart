import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/database_service.dart';
import 'screens/message_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Form',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _appIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch credentials from the database
    final storedCredentials = await DatabaseHelper.instance.fetchCredentials();

    if (storedCredentials.isNotEmpty) {
      final credentials = storedCredentials.first;
      final username = credentials['username'];
      final password = credentials['password'];
      final appId = credentials['app_id'];

      final url =
          'https://www.takeawayordering.com/appserver/appserver.php?tag=shoplogin&employee_phone=$username&employee_pin=$password&shop_id=$appId';

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['success'] == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MessagePage(),
              ),
            );
          } else {
            debugPrint('Stored credentials are invalid.');
          }
        } else {
          debugPrint('Failed to connect to the server.');
        }
      } catch (e) {
        debugPrint('Auto-login error: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _login() async {
  setState(() {
    _isLoading = true;
  });

  final url =
      'https://www.takeawayordering.com/appserver/appserver.php?tag=shoplogin&employee_phone=${_usernameController.text}&employee_pin=${_passwordController.text}&shop_id=${_appIdController.text}';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == 1) {
        // Extract email from the response
        final shopDetails = data['employeedetails']?.values?.first;
        final shopEmail = shopDetails != null ? shopDetails['email'] : null;

        final credentials = {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'mobile_number': _mobileNumberController.text,
          'email': shopEmail, // Save the email fetched from the response
          'app_id': _appIdController.text,
        };

        // Save the credentials in the database
        await DatabaseHelper.instance.clearCredentials();
        await DatabaseHelper.instance.saveCredentials(credentials);

        // Navigate to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(),
          ),
        );
      } else {
        _showErrorDialog('Invalid credentials. Please try again.');
      }
    } else {
      _showErrorDialog('Failed to connect to the server.');
    }
  } catch (e) {
    _showErrorDialog('An error occurred: $e');
  }

  setState(() {
    _isLoading = false;
  });
}


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent text fields overlapping with header
      body: Stack(
        children: [
          // Custom Header
          Column(
            children: [
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF075E54), Color(0xFF25D366)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'retentio',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(color: Colors.white),
              ),
            ],
          ),

          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WhatsAppTextField(
                      label: 'Username',
                      icon: Icons.person,
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 15),
                    WhatsAppTextField(
                      label: 'Password',
                      icon: Icons.lock,
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    WhatsAppTextField(
                      label: 'App ID',
                      icon: Icons.store,
                      controller: _appIdController,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(
                                 
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;

  const WhatsAppTextField({
    Key? key,
    required this.label,
    required this.icon,
    required this.controller,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF075E54)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFECECEC)),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF075E54)),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
