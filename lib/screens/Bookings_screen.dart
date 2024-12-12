import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'message_Page.dart'; 
import 'configuration_page.dart';
import '../services/database_service.dart'; 

class BookingsPage extends StatefulWidget {
  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List<dynamic> _bookings = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  int _selectedIndex = 0;
  String? employeePhone;
  String? employeePin;
  String? shopId;

  @override
  void initState() {
    super.initState();
    _initializeCredentials(); // Fetch credentials once
  }

  String _getFormattedDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

Future<void> _initializeCredentials() async {
  try {
    // Fetch credentials from the database
    final storedCredentials = await DatabaseHelper.instance.fetchCredentials();

    if (storedCredentials.isEmpty) {
      // If no credentials found, set defaults
      setState(() {
        employeePhone = 'spicebag';
        employeePin = 'sp1ceb@g';
        shopId = '37';
      });
      debugPrint("No credentials found in DB. Using defaults.");
    } else {
      // Assign fetched credentials
      setState(() {
        employeePhone = storedCredentials.first['username'];
        employeePin = storedCredentials.first['password'];
        shopId = storedCredentials.first['app_id'];
      });
      debugPrint("Fetched credentials from DB: $storedCredentials");
    }

    // Fetch bookings after initializing credentials
    if (employeePhone != null && employeePin != null && shopId != null) {
      await _fetchBookings(date: _getFormattedDate(_selectedDate));
    } else {
      debugPrint("Credentials are null. Skipping bookings fetch.");
    }
  } catch (error) {
    debugPrint("Error fetching credentials: $error");
  } finally {
    setState(() {
      _isLoading = false; // Stop the loading spinner
    });
  }
}


  Future<void> _fetchBookings({required String date}) async {
  if (employeePhone == null || employeePin == null || shopId == null) {
    debugPrint("Skipping API call. Credentials are null.");
    return;
  }

  setState(() {
    _isLoading = true;
  });

  final queryParams = {
    'tag': 'getbookingsbydate',
    'employee_phone': employeePhone,
    'employee_pin': employeePin,
    'shop_id': shopId,
    'booking_date': date,
  };

  final uri = Uri.https(
      'www.takeawayordering.com', '/appserver/appserver.php', queryParams);

  try {
    print(uri); // Log the URI to confirm correctness
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == 1) {
        setState(() {
          _bookings = data['bookingdetails'].values.toList();
        });
      } else {
        setState(() {
          _bookings = [];
        });
      }
    }
  } catch (error) {
    debugPrint('Error fetching bookings: $error');
  } finally {
    setState(() {
      _isLoading = false;
    });
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


Future<void> _fetchFutureBookings() async {
    final currentDate = DateTime.now();
    final queryParams = {
      'tag': 'getbookings',
      'employee_phone': employeePhone,
      'employee_pin': employeePin,
      'shop_id': shopId,
      'booking_date': _getFormattedDate(currentDate),
    };

    final uri = Uri.https(
        'www.takeawayordering.com', '/appserver/appserver.php', queryParams);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == 1) {
          setState(() {
            _bookings = data['bookingdetails'].values.toList();
          });
        } else {
          setState(() {
            _bookings = [];
          });
        }
      }
    } catch (error) {
      debugPrint('Error fetching future bookings: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
Future<void> _sendNotification(String bookingId, String type) async {
    final queryParams = {
      'tag': type == 'email' ? 'sendemailbooking' : 'sendsmsbooking',
      'employee_phone': employeePhone,
      'employee_pin': employeePin,
      'shop_id': shopId,
      'booking_id': bookingId,
    };

    final uri = Uri.https(
        'www.takeawayordering.com', '/appserver/appserver.php', queryParams);

    try {
      print(uri);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (data['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(type == 'email'
                  ? 'Email sent successfully'
                  : 'SMS sent successfully')),
        );
      }
    } catch (error) {
      debugPrint('Error sending $type: $error');
    }
  }


// Update booking status
  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final queryParams = {
      'tag': 'updatebookingstatus',
      'employee_phone': employeePhone,
      'employee_pin': employeePin,
      'shop_id': shopId,
      'booking_id': bookingId,
      'booking_status': status,
    };

    final uri = Uri.https(
        'www.takeawayordering.com', '/appserver/appserver.php', queryParams);

    try {
      print(uri);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (data['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
        _fetchBookings(date: _getFormattedDate(_selectedDate));
      }
    } catch (error) {
      debugPrint('Error updating booking status: $error');
    }
  }

  void _editBooking(dynamic booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookingPage(booking: booking),
      ),
    ).then((_) => _fetchBookings(date: _getFormattedDate(_selectedDate)));
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Gradient Header
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF075E54), Color(0xFF25D366)], // Green gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'Bookings',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now(); // Reset to today's date
              });
              _fetchBookings(date: _getFormattedDate(_selectedDate)); // Fetch today's bookings
            },
            child: const Text('Today\'s Bookings'),
          ),
          ElevatedButton(
            onPressed: _fetchFutureBookings,
            child: const Text('Future Bookings'),
          ),
        ],
      ),
      const SizedBox(height: 10), // Space between rows

      // The clickable container with the calendar icon and selected date
      GestureDetector(
        onTap: () async {
          // Show DatePicker and fetch bookings for the selected date
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000), // Earliest selectable date
            lastDate: DateTime(2100), // Latest selectable date
          );

          if (pickedDate != null && pickedDate != _selectedDate) {
            setState(() {
              _selectedDate = pickedDate;
            });

            // Fetch bookings for the selected date
            _fetchBookings(date: _getFormattedDate(pickedDate));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Box background color
            borderRadius: BorderRadius.circular(12), // Rounded corners
            border: Border.all(
              color: Colors.grey, // Border color
              width: 1, // Border width
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
              ),
              const SizedBox(width: 10), // Add some spacing
              Text(
                'Selected: ${_getFormattedDate(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),


        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
                  ? const Center(child: Text('No bookings found'))
                  : ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking['reservation_name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(booking['reservation_phone'] ?? ''),
                                        const SizedBox(height: 4),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              booking['reservation_email'] ?? '',
                                              style: const TextStyle(
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if ((booking['voucher_code'] ?? '')
                                            .isNotEmpty)
                                          Text(
                                            '${booking['voucher_code']}',
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(booking['reservation_date'] ?? ''),
                                        const SizedBox(height: 4),
                                        Text(booking['reservation_time'] ?? ''),
                                        const SizedBox(height: 4),
                                        Text(booking['reservation_number'] ?? ''),
                                        const SizedBox(height: 4),
                                        Text(booking['reservation_status'] ?? ''),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _sendNotification(
                                          booking['id'].toString(),
                                          'sms',
                                        );
                                      },
                                      child: const Text('SMS'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _sendNotification(
                                          booking['id'].toString(),
                                          'email',
                                        );
                                      },
                                      child: const Text('Email'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _updateBookingStatus(
                                          booking['id'].toString(),
                                          'NOSHOW',
                                        );
                                      },
                                      child: const Text('Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _editBooking(booking);
                                      },
                                      child: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
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


class EditBookingPage extends StatefulWidget {
  final dynamic booking;

  EditBookingPage({required this.booking});

  @override
  _EditBookingPageState createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _personsController;
  late TextEditingController _voucherController;
  late DateTime _selectedDate;
  late String _selectedTime;

  String? employeePhone;
  String? employeePin;
  String? shopId;

  @override
  void initState() {
    super.initState();
    _initializeCredentials(); // Fetch credentials once

    _nameController =
        TextEditingController(text: widget.booking['reservation_name']);
    _phoneController =
        TextEditingController(text: widget.booking['reservation_phone']);
    _emailController =
        TextEditingController(text: widget.booking['reservation_email']);
    _personsController =
        TextEditingController(text: widget.booking['reservation_number']);
    _voucherController = TextEditingController(
        text: widget.booking['voucher_code'] ?? '');
    _selectedDate = DateTime.parse(widget.booking['reservation_date']);
    _selectedTime = widget.booking['reservation_time'];
  }

  Future<void> _initializeCredentials() async {
    try {
      final storedCredentials =
          await DatabaseHelper.instance.fetchCredentials();

      if (storedCredentials.isEmpty) {
        debugPrint("No credentials found in DB.");
        return;
      }

      setState(() {
        employeePhone = storedCredentials.first['username'];
        employeePin = storedCredentials.first['password'];
        shopId = storedCredentials.first['app_id'];
      });

      debugPrint("Fetched credentials from DB: $storedCredentials");
    } catch (error) {
      debugPrint('Error initializing credentials: $error');
    }
  }
String _getFormattedDate(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

  Future<void> _updateBooking() async {
    final queryParams = {
      'tag': 'editbooking',
      'employee_phone': employeePhone,
      'employee_pin': employeePin,
      'shop_id': shopId,
      'booking_id': widget.booking['id'].toString(),
      'reservation_name': _nameController.text,
      'reservation_phone': _phoneController.text,
      'reservation_email': _emailController.text,
      'reservation_number': _personsController.text,
      'reservation_date': _selectedDate.toIso8601String().split('T')[0],
      'reservation_time': _selectedTime,
      'voucher_code': _voucherController.text,
    };

    final uri = Uri.https(
        'www.takeawayordering.com', '/appserver/appserver.php', queryParams);

    try {
      print(uri);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (data['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking')),
        );
      }
    } catch (error) {
      debugPrint('Error updating booking: $error');
    }
  }

  List<String> _generateTimeSlots() {
    List<String> timeSlots = [];
    for (int hour = 11; hour <= 22; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final hourString = hour.toString().padLeft(2, '0');
        final minuteString = minute.toString().padLeft(2, '0');
        timeSlots.add('$hourString:$minuteString');
      }
    }
    return timeSlots;
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Edit Booking'),
      backgroundColor: Colors.green,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
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
            TextField(
              controller: _personsController,
              decoration: InputDecoration(
                labelText: 'Number of Persons',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _voucherController,
              decoration: InputDecoration(
                labelText: 'Voucher Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
          Text(
  'Select Booking Date',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey, width: 1),
    borderRadius: BorderRadius.circular(8.0),
  ),
  padding: EdgeInsets.all(8.0),
  child: CalendarDatePicker(
    initialDate: _selectedDate,
    firstDate: DateTime(2000), // Earliest selectable date
    lastDate: DateTime(2100), // Latest selectable date
    onDateChanged: (DateTime newDate) {
      setState(() {
        _selectedDate = newDate;
      });
    },
    currentDate: DateTime.now(),
    selectableDayPredicate: (DateTime day) {
      // Optionally restrict dates (e.g., disable weekends)
      return true; // Enable all days
    },
  ),
),

            const SizedBox(height: 20),
            Text(
  'Select Booking Time: ${_selectedTime.isEmpty ? "Not Selected" : _selectedTime}',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

            GridView.builder(
              shrinkWrap: true, // Ensures GridView doesn’t take infinite space
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _generateTimeSlots().length,
              itemBuilder: (context, index) {
                final time = _generateTimeSlots()[index];
                final isCurrentBookingTime =
                    time == _selectedTime; // Check if this is the booked time

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentBookingTime
                        ? Colors.blue // Highlight the current booking time
                        : (_selectedTime == time
                            ? Colors.green // Highlight selected time
                            : Colors.orange), // Default unselected time color
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedTime = time; // Update selected time
                    });
                  },
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isCurrentBookingTime
                          ? Colors.white
                          : Colors.black, // Adjust text color
                      fontWeight: isCurrentBookingTime
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateBooking,
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

}
