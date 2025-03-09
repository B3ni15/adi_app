import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord User Status',
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
  final List<Widget> _pages = [const HomePage(), const GalleryPage()];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Főoldal'),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Képtár',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[600],
      backgroundColor: const Color(0x4D1A1B22),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      onTap: _onItemTapped,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://adi.huntools-bot.xyz/user/801162422580019220'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'HTTP kérés sikertelen: ${response.statusCode}';
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Hálózati hiba: ${e.message}';
      });
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Időtúllépés a szerver válaszára';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Váratlan hiba: ${e.toString()}';
      });
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

  Widget _buildActivityBox(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity['assets'] != null)
            Row(
              children: [
                if (activity['assets']['large_image'] != null)
                  Image.network(
                    activity['assets']['large_image'],
                    width: 40,
                    height: 40,
                  ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['name'] ?? 'Ismeretlen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activity['details'] != null)
                      Text(
                        activity['details'],
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                  ],
                ),
              ],
            ),
          if (activity['state'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                activity['state'],
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchUserData,
            child: const Text('Újrapróbálás'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    final user = _userData?['user'];
    final status = user?['status'] ?? 'offline';
    final activities = user?['activities'] ?? [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(status),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(user?['avatar'] ?? ''),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?['display_name'] ?? 'Ismeretlen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '@${user?['name'] ?? 'ismeretlen'}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            ...activities.map<Widget>(
              (activity) => _buildActivityBox(activity),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  final List<String> imageUrls = const [
    'https://picsum.photos/200/300',
    'https://picsum.photos/250/300',
    'https://picsum.photos/300/300',
    'https://picsum.photos/350/300',
    'https://picsum.photos/400/300',
    'https://picsum.photos/450/300',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FullScreenImage(imageUrl: imageUrls[index]),
                ),
              );
            },
            child: Hero(
              tag: imageUrls[index],
              child: Image.network(imageUrls[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B22),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: imageUrl,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
