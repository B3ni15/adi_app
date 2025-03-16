import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _refreshTimer;
  String? _previousStatus;
  String userid = '1006581830880874618'; // Default user ID
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _userIdController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchData(),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('https://adi.huntools-bot.xyz/user/$userid'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        final user = newData['user'];
        final currentStatus = user?['status']?.toString() ?? 'offline';

        setState(() {
          _userData = newData;
          _isLoading = false;
          _errorMessage = '';
        });

        if (_previousStatus != null &&
            currentStatus == 'online' &&
            _previousStatus != 'online') {
          NotificationService.showNotification();
        }
        _previousStatus = currentStatus;
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Hiba: ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() => _errorMessage = 'Időtúllépés');
    } catch (e) {
      setState(() => _errorMessage = 'Hiba: ${e.toString()}');
    }
  }

  void _updateUserId(String newUserId) {
    setState(() {
      userid = newUserId;
      _isLoading = true; // Show loading indicator while fetching new data
      _errorMessage = ''; // Clear any previous error messages
    });
    _fetchData(); // Fetch data for the new user ID
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'dnd':
        return Colors.red;
      case 'idle':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Újratöltés'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(Map<String, dynamic>? activity) {
    if (activity == null) return const SizedBox.shrink();

    final name = activity['name']?.toString();
    final state = activity['state']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gamepad, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null && name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (state != null && state.isNotEmpty)
                  Text(
                    state,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _userIdController,
                style: const TextStyle(color: Colors.white), // Text color
                decoration: InputDecoration(
                  hintText: 'Enter User ID',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                  ), // Hint text color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[700]!,
                    ), // Border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[700]!,
                    ), // Enabled border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.blue,
                    ), // Focused border color
                  ),
                  filled: true,
                  fillColor: Colors.grey[900], // Background color
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                    ), // Icon color
                    onPressed: () {
                      _updateUserId(_userIdController.text);
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _updateUserId(value);
                },
              ),
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              _buildError()
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(
                        _userData?['user']?['status'] ?? 'offline',
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(
                        _userData?['user']?['avatar'] ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    _userData?['user']?['display_name'] ??
                        'Ismeretlen felhasználó',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '@${_userData?['user']?['name'] ?? 'unknown'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  _buildActivity(_userData?['user']?['activities']?[0]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
