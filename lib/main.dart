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
      title: 'Discord User Monitor',
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
      bottomNavigationBar: BottomNavigationBar(
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
      ),
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
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchUserData();
    });
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

  String _fixImageUrl(String url) {
    if (url.contains('raw.githubusercontent.com')) {
      return 'https://cdn.discordapp.com/app-assets/782685898163617802/mp:external/Joitre7BBxO-F2IaS7R300AaAcixAvPu3WD1YchRgdc/https/raw.githubusercontent.com/LeonardSSH/vscord/main/assets/icons/vscode.png.png';
    }
    return url;
  }

  Widget _buildActivity(dynamic activity) {
    final assets = activity['assets'] as Map<String, dynamic>?;
    final mainImage = assets?['large_image']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (mainImage != null)
            Image.network(_fixImageUrl(mainImage), width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['name']?.toString() ?? 'Aktivitás',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activity['details'] != null)
                  Text(
                    activity['details'].toString(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchUserData,
            child: const Text('Újratöltés'),
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
        (user?['activities'] as List?)
            ?.where((a) => a['type'] != 'custom')
            .toList() ??
        [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(status),
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundImage: NetworkImage(
                  user?['avatar']?.toString() ?? '',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?['display_name']?.toString() ?? 'Ismeretlen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@${user?['name']?.toString() ?? 'unknown'}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            ...activities.map(_buildActivity),
          ],
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  final List<String> imageUrls = const [
    'https://picsum.photos/200/300',
    'https://picsum.photos/250/300',
    'https://picsum.photos/300/300',
    'https://picsum.photos/350/300',
    'https://picsum.photos/400/300',
    'https://picsum.photos/450/300',
  ];

  const GalleryPage({super.key});

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
        itemBuilder:
            (context, index) => GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              FullScreenImage(imageUrl: imageUrls[index]),
                    ),
                  ),
              child: Hero(
                tag: imageUrls[index],
                child: Image.network(imageUrls[index], fit: BoxFit.cover),
              ),
            ),
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
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
