import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  _ConfigurationPageState createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _unsubscribeUrlController = TextEditingController();
  bool _isSaving = false;
  String? _currentConfigLink;

  @override
  void initState() {
    super.initState();
    _fetchCurrentConfig();
  }

  Future<void> _fetchCurrentConfig() async {
    try {
      final String loginApiUrl =
          'https://www.takeawayordering.com/appserver/appserver.php?tag=shoplogin&employee_phone=spicebag&employee_pin=sp1ceb@g&shop_id=37';

      final response = await http.get(Uri.parse(loginApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['success'] == 1 &&
            responseBody['employeedetails'] != null) {
          final shopDetails = responseBody['employeedetails']['99'];
          setState(() {
            _currentConfigLink = shopDetails['shop_unsubscribe_url'];
          });
        } else {
          throw 'Failed to fetch current configuration. Server response: $responseBody';
        }
      } else {
        throw 'Failed to fetch current configuration. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _showErrorDialog('An error occurred while fetching the current configuration: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    final senderName = _senderNameController.text.trim();
    final unsubscribeUrl = _unsubscribeUrlController.text.trim();

    if (senderName.isEmpty || unsubscribeUrl.isEmpty) {
      _showErrorDialog('Both fields are required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String apiUrl =
          'https://www.takeawayordering.com/appserver/appserver.php?tag=updateconfiguration&employee_phone=spicebag&employee_pin=sp1ceb@g&shop_id=37&shop_name_url=$senderName&unsubscribe_url=$unsubscribeUrl';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['success'] == 1 && responseBody['configurations'] == true) {
          _showInfoDialog('Configuration saved successfully!');
          _fetchCurrentConfig(); // Refresh the current config after saving
        } else {
          throw 'Failed to save configuration. Server response: $responseBody';
        }
      } else {
        throw 'Failed to save configuration. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _showErrorDialog('An error occurred while saving configuration: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info'),
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
      appBar: AppBar(
        title: const Text('Welcome'),
        centerTitle: true,
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Application!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are glad to have you here. Explore our app to discover amazing features that will help you manage your bookings efficiently.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to bookings page or any other feature
                Navigator.pushNamed(context, '/bookings'); // Update the route as needed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 15), // Button dimensions
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Explore Now',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
