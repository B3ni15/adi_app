import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications plugin
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin!.initialize(initializationSettings);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord Profil',
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF1A1B22)),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const ProfilePage()];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: const Color(0x4D1A1B22),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}

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

  void _showNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'adam_online_channel',
          'Ádám állapota',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin?.show(
      0,
      'Ádám online!',
      'Ádám most online állapotban van.',
      notificationDetails,
    );
  }

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
          .get(
            Uri.parse('https://adi.huntools-bot.xyz/user/1006581830880874618'),
          )
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

        // Check status change
        if (_previousStatus != null &&
            currentStatus == 'online' &&
            _previousStatus != 'online') {
          _showNotification();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return _buildError();

    final user = _userData?['user'];
    final status = user?['status']?.toString() ?? 'offline';
    final activities =
        (user?['activities'] as List?)?.cast<Map<String, dynamic>>();

    Map<String, dynamic>? selectedActivity;
    if (activities != null) {
      if (activities.length > 1) {
        selectedActivity = activities[1];
      } else if (activities.isNotEmpty) {
        selectedActivity = activities[0];
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(status),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(user?['avatar'] ?? ''),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              user?['display_name'] ?? 'Ismeretlen felhasználó',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '@${user?['name'] ?? 'unknown'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildActivity(selectedActivity),
          ],
        ),
      ),
    );
  }
}
