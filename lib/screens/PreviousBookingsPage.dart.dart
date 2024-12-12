import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PreviousBookingsPage extends StatefulWidget {
  final String employeePhone;
  final String employeePin;
  final String shopId;
  final String contactMobile;

  const PreviousBookingsPage({
    required this.employeePhone,
    required this.employeePin,
    required this.shopId,
    required this.contactMobile,
    Key? key,
  }) : super(key: key);

  @override
  State<PreviousBookingsPage> createState() => _PreviousBookingsPageState();
}

class _PreviousBookingsPageState extends State<PreviousBookingsPage> {
  List<Map<String, dynamic>> bookings = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchPreviousBookings();
  }

  Future<void> _fetchPreviousBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final queryParams = {
      'tag': 'getcontactbookings',
      'employee_phone': widget.employeePhone,
      'employee_pin': widget.employeePin,
      'shop_id': widget.shopId,
      'contact_mobile': widget.contactMobile,
    };

    final uri = Uri.https(
      'www.takeawayordering.com',
      '/appserver/appserver.php',
      queryParams,
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 1) {
          setState(() {
            bookings = (data['contactbookings'] as Map<String, dynamic>)
                .values
                .map((e) => e as Map<String, dynamic>)
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "No bookings found.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch data. Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Go back to the previous page
                      },
                    ),
                    const Spacer(),
                    const Text(
                      'Visit History',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: Container(color: Colors.white),
              ),
            ],
          ),

          // Content
          Positioned.fill(
            top: 150, // Ensure content starts below the header
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 10, // Spacing between elements
                                    runSpacing: 8, // Spacing between rows
                                    children: [
                                      Text(
                                        "Name: ${booking['reservation_name']}",
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Phone: ${booking['reservation_phone']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Date: ${booking['reservation_date']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Time: ${booking['reservation_time']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Guests: ${booking['reservation_number']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Email: ${booking['reservation_email']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Status: ${booking['reservation_status']}",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
