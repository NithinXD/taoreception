import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/database_service.dart';
import 'PreviousBookingsPage.dart.dart';
import 'Bookings_screen.dart';
import 'configuration_page.dart';
class MessagePage extends StatefulWidget {
  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _guestsController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = "";
  String _reservationType = 'WALKIN'; // Default reservation type
  String _defaultEmail = ""; // To hold the default email from the database
  int _selectedIndex = 1; // For bottom navigation bar
String? employeePhone;
  String? employeePin;
  String? shopId;
  String name = "";
  String Pin = "";
  String shop = "";
  @override
  void initState() {
    super.initState();
    _loadDefaultEmail();
  }

 Future<void> _loadDefaultEmail() async {
  try {
    final storedCredentials = await DatabaseHelper.instance.fetchCredentials();
    if (storedCredentials.isNotEmpty) {
      final email = storedCredentials.first['email'];
      final name = storedCredentials.first['username'];
      final Pin = storedCredentials.first['password'];
      final shop = storedCredentials.first['app_id'];

      if (email != null && email.isNotEmpty) {
        setState(() {
          _defaultEmail = email;
          print(_defaultEmail);
          employeePhone = name ?? '';
          employeePin = Pin ?? '';
          shopId = shop ?? '';
        });
      }
    }
  } catch (error) {
    debugPrint('Error loading default email: $error');
  }
}

void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to Booking Page (Current Page)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookingsPage()),
      );
    } else if (index == 1) {
      // Navigate to Reception Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MessagePage()),
      );
    } else if (index == 2) {
      // Navigate to Configuration Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfigurationPage()),
      );
    }
  }


Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      if (employeePhone != null && employeePin != null && shopId != null) {
        final queryParams = {
          'tag': 'getcontactbookings',
          'employee_phone': employeePhone!,
          'employee_pin': employeePin!,
          'shop_id': shopId!,
          'contact_mobile': _phoneController.text,
        };

        final uri = Uri.https(
          'www.takeawayordering.com',
          '/appserver/appserver.php',
          queryParams,
        );
        print("Request URL: $uri");

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == 1 && data['contactbookings'] != null) {
            await _createNewBooking(employeePhone!, employeePin!, shopId!);
          } else {
            await _createNewBooking(employeePhone!, employeePin!, shopId!);
          }
        } else {
          _showErrorMessage("An error occurred. Status code: ${response.statusCode}");
        }
      } else {
        _showErrorMessage("Missing employee details or shop ID.");
      }
    } catch (error) {
      _showErrorMessage("Failed to connect to the server. Error: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

void _resetForm() {
  _phoneController.clear();
  _emailController.clear();
  _nameController.clear();
  _guestsController.clear();
  setState(() {
    _reservationType = 'WALKIN'; // Reset to default reservation type
    _statusMessage = "";         // Clear the status message
  });
}

Future<void> _createNewBooking(String employeePhone, String employeePin, String shopId) async {
  final DateTime now = DateTime.now();
  final String currentDate =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  final String currentTime =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final reservationEmail = _emailController.text.trim().isNotEmpty
      ? _emailController.text.trim()
      : _defaultEmail;

  final queryParams = {
    'tag': 'createbooking',
    'employee_phone': employeePhone,
    'employee_pin': employeePin,
    'shop_id': shopId,
    'reservation_name': _nameController.text,
    'reservation_phone': _phoneController.text,
    'reservation_number': _guestsController.text,
    'reservation_date': currentDate,
    'reservation_time': currentTime,
    'reservation_email': reservationEmail,
    'voucher_code': 'FREEMEAL', // Default voucher code for new bookings
    'reservation_type': _reservationType, // Add reservation type to the request
  };

  final uri = Uri.https(
    'www.takeawayordering.com',
    '/appserver/appserver.php',
    queryParams,
  );
  print("Create Booking URL: $uri");

  try {
    // Show a dialog to indicate that a new booking is being created
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Creating Booking"),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "We are creating a new booking for you. Please wait...",
                ),
              ),
            ],
          ),
        );
      },
    );

    final response = await http.get(uri);

    // Close the loading dialog after receiving the response
    Navigator.of(context, rootNavigator: true).pop();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == 1) {
        final bookingId = data['booking_id']; // Extract booking_id from response
        setState(() {
          _statusMessage = "Booking created successfully!";
        });

        // Wait for user confirmation in the dialog
        await showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissal by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Booking Created"),
              content: Text(
                  "Your booking has been created successfully!\n\nBooking ID: $bookingId"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );

        // Navigate to the PreviousBookingsPage after dialog confirmation
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PreviousBookingsPage(
      employeePhone: employeePhone,
      employeePin: employeePin,
      shopId: shopId,
      contactMobile: _phoneController.text,
    ),
  ),
).then((_) {
  // Reset the form fields after returning from the navigation
  _resetForm();
});

      } else {
        _showErrorMessage(data['error'] ?? "Failed to create booking.");
      }
    } else {
      _showErrorMessage("An error occurred. Status code: ${response.statusCode}");
    }
  } catch (error) {
    setState(() {
      _statusMessage = "Failed to create booking. Error: $error";
    });
  }
}

void _showErrorMessage(String message) {
  setState(() {
    _statusMessage = message;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevents overlap when the keyboard appears
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
                    'Reception',
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

          // Form Content
          Positioned.fill(
            top: 150, // Ensure the content starts below the header
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone Number Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Number of Guests Field
                      TextFormField(
                        controller: _guestsController,
                        decoration: InputDecoration(
                          labelText: 'Number of Guests*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Number of guests is required';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Enter a valid number of guests';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),

                      // Reservation Type Buttons
                      const Text(
                        'Reservation Type:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _reservationType = 'WALKIN';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _reservationType == 'WALKIN'
                                  ? Colors.green
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'WALKIN',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _reservationType = 'BOOKING';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _reservationType == 'BOOKING'
                                  ? Colors.green
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'BOOKING',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Message
                      if (_statusMessage.isNotEmpty)
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('successful')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Reception',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuration',
        ),
      ],
    ),
  );
}
}