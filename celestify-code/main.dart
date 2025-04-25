//------------------------ BASIC IDEA FOR CELESTIFY APP -----------------------

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'image_processor.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'astronomy_api.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'sky_explorer.dart';
import 'package:flutter/services.dart';
import 'aladin_sky_explorer.dart';
import 'moon_phase_screen.dart';
import 'settings_screen.dart';

void main() => runApp(CelestifyApp());

class CelestifyApp extends StatelessWidget {
  const CelestifyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celestify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      home: MainScreen(initialIndex: 0),
      routes: {
        '/home': (context) => HomeScreen(),
        '/tonights-best': (context) => TonightsBestScreen(),
        '/sky-explorer': (context) => SkyExplorerScreen(),
        '/moon-phase': (context) => MoonPhaseScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();

    // Navigate to main screen after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 0)),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: 80,
                color: Colors.amber,
              ),
              SizedBox(height: 20),
              Text(
                'Welcome To Celestify!✨',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    SkyExplorerScreen(),
    MoonPhaseScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_round),
            label: 'Moon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Simple profile screen placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              print("Settings icon tapped");
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 100,
              color: Colors.amber,
            ),
            SizedBox(height: 20),
            Text(
              'User Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Personal astronomy settings and preferences',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.star),
              label: Text('My Favorites'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _locationPermissionGranted = false;
  bool _isLoading = true;
  Map<String, dynamic> _stargazingConditions = {};
  final AstronomyAPI _astronomyAPI = AstronomyAPI();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchAstronomyData();
  }

  Future<void> _fetchAstronomyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conditions = await _astronomyAPI.getAllStargazingConditions();
      setState(() {
        _stargazingConditions = conditions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching astronomy data: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not fetch astronomy data. Please check your connection.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchAstronomyData,
          ),
        ),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location access granted. You can now see local stargazing conditions')),
      );
      _fetchAstronomyData();
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
              'Location permission is needed to show stargazing conditions for your area. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Celestify'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined),
            tooltip: 'Search real-time data',
            onPressed: () {
              _astronomyAPI.searchAstronomyConditions();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Show settings dialog
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha((0.2 * 255).toInt()),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 50, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'Celestify Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: Text('Event Tracker'),
              leading: Icon(Icons.event),
              onTap: () {
                Navigator.pushNamed(context, '/event-tracker');
              },
            ),
            ListTile(
              title: Text("Tonight's Best"),
              subtitle:
                  Text("Find the best stargazing opportunities for tonight"),
              leading: Icon(Icons.stars),
              onTap: () {
                Navigator.pushNamed(context, '/tonights-best');
              },
            ),
            ListTile(
              title: Text('Light Pollution Map'),
              leading: Icon(Icons.map),
              onTap: () {
                Navigator.pushNamed(context, '/light-pollution');
              },
            ),
            ListTile(
              title: Text('Camera Settings Guide'),
              leading: Icon(Icons.camera_alt),
              onTap: () {
                Navigator.pushNamed(context, '/settings-guide');
              },
            ),
            ListTile(
              title: Text('Image Stacker'),
              subtitle:
                  Text('Stack images to reduce noise and enhance details'),
              leading: Icon(Icons.auto_awesome),
              onTap: () {
                Navigator.pushNamed(context, '/image-stacker');
              },
            ),
            Divider(),
            ListTile(
              title: Text('Share App'),
              leading: Icon(Icons.share),
              onTap: () {
                // TODO: Implement app sharing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
            ListTile(
              title: Text('About'),
              leading: Icon(Icons.info_outline),
              onTap: () {
                // TODO: Show about dialog
                showAboutDialog(
                  context: context,
                  applicationName: 'Celestify',
                  applicationVersion: '1.0.0',
                  applicationIcon:
                      Icon(Icons.star_border, size: 50, color: Colors.amber),
                  children: [
                    Text(
                        'Your personal astronomy companion for capturing and exploring the cosmos.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAstronomyData,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading astronomy data...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick Actions Card
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickActionButton(
                                    context,
                                    icon: Icons.camera_alt,
                                    label: 'Stack Images',
                                    onTap: () => Navigator.pushNamed(
                                        context, '/image-stacker'),
                                  ),
                                  _buildQuickActionButton(
                                    context,
                                    icon: Icons.map,
                                    label: 'View Map',
                                    onTap: () => Navigator.pushNamed(
                                        context, '/light-pollution'),
                                  ),
                                  _buildQuickActionButton(
                                    context,
                                    icon: Icons.search,
                                    label: 'Search',
                                    onTap: () {
                                      final bottomNavBar =
                                          context.findAncestorWidgetOfExactType<
                                              BottomNavigationBar>();
                                      if (bottomNavBar != null) {
                                        (context.findAncestorStateOfType<
                                                _MainScreenState>())
                                            ?._onItemTapped(1);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Stargazing Conditions Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Stargazing Conditions',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: () {
                                      // Refresh stargazing conditions
                                      _fetchAstronomyData();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Refreshing conditions...')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (!_locationPermissionGranted)
                                Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_off,
                                          color: Colors.orange),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Location access is needed for accurate conditions. Tap to enable.',
                                          style:
                                              TextStyle(color: Colors.orange),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _requestLocationPermission,
                                        child: Text('ENABLE'),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 16),
                              // Improved layout for conditions on Android
                              Container(
                                height: 140,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildConditionItem(
                                      icon: Icons.visibility,
                                      label: 'Visibility',
                                      value: _getVisibilityValue(),
                                      color: _getVisibilityColor(),
                                    ),
                                    _buildConditionItem(
                                      icon: Icons.cloud,
                                      label: 'Cloud Cover',
                                      value: _getCloudCoverValue(),
                                      color: _getCloudCoverColor(),
                                    ),
                                    _buildConditionItem(
                                      icon: Icons.brightness_3,
                                      label: 'Moon Phase',
                                      value: _getMoonPhaseValue(),
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tonight's Events Preview
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tonight's Events",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/event-tracker'),
                                    child: Text('View All'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildTonightsEvents(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Astronomy News Widget
                    AstronomyNewsWidget(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Improved layout for Android
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (label == 'Visibility' || label == 'Cloud Cover')
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InkWell(
                onTap: () async {
                  final url = label == 'Visibility'
                      ? Uri.parse('https://www.cleardarksky.com/')
                      : Uri.parse('https://www.accuweather.com/');
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    throw Exception('Could not launch URL');
                  }
                },
                child: Text(
                  'Check ${label == 'Visibility' ? 'Map' : 'Forecast'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTonightsEvents() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('events')) {
      return Center(
        child: Text('No events available for tonight'),
      );
    }

    final events = _stargazingConditions['events'] as List;
    if (events.isEmpty) {
      return Center(
        child: Text('No events available for tonight'),
      );
    }

    return Column(
      children: events.take(3).map<Widget>((event) {
        return _buildEventItem(
          time: event['time'] ?? '',
          event: event['event'] ?? '',
          description: event['description'] ?? '',
        );
      }).toList(),
    );
  }

  Widget _buildEventItem({
    required String time,
    required String event,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            child: Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to extract data from API response
  String _getVisibilityValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('visibility')) {
      return 'Unknown';
    }

    final visibility = _stargazingConditions['visibility'];
    return visibility['visibility'] ?? 'Unknown';
  }

  Color _getVisibilityColor() {
    final value = _getVisibilityValue();
    if (value == 'Good') return Colors.green;
    if (value == 'Average' || value == 'OK') return Colors.orange;
    if (value == 'Poor' || value == 'Bad') return Colors.red;
    return Colors.grey;
  }

  String _getCloudCoverValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('weather') ||
        !_stargazingConditions['weather'].containsKey('current')) {
      return 'Unknown';
    }

    final weather = _stargazingConditions['weather'];
    final clouds = weather['current']['clouds'] ?? 0;
    return '$clouds%';
  }

  Color _getCloudCoverColor() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('weather') ||
        !_stargazingConditions['weather'].containsKey('current')) {
      return Colors.grey;
    }

    final weather = _stargazingConditions['weather'];
    final clouds = weather['current']['clouds'] ?? 0;

    if (clouds < 20) return Colors.green;
    if (clouds < 50) return Colors.orange;
    return Colors.red;
  }

  String _getMoonPhaseValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('moonPhase')) {
      return 'Unknown';
    }

    final moonPhase = _stargazingConditions['moonPhase'];
    final illumination = moonPhase['illumination'] ?? 0.0;
    return '${(illumination * 100).toInt()}%';
  }

  // Add this method to the HomeScreen class
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(
                value: true, // Default to dark mode
                onChanged: (value) {
                  // In a real app, this would toggle dark mode
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Dark mode is always enabled for astronomy apps')),
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Location Services'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // In a real app, this would toggle location services
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Location services are required for accurate sky mapping')),
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // In a real app, this would toggle notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notification settings updated')),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class AstronomyNewsWidget extends StatefulWidget {
  const AstronomyNewsWidget({Key? key}) : super(key: key);

  @override
  _AstronomyNewsWidgetState createState() => _AstronomyNewsWidgetState();
}

class _AstronomyNewsWidgetState extends State<AstronomyNewsWidget> {
  final List<Map<String, dynamic>> _astronomyNews = [
    {
      'title':
          'James Webb Space Telescope Reveals New Details of Distant Galaxy',
      'date': 'Today',
      'description':
          'The James Webb Space Telescope has captured stunning new images of a galaxy 13 billion light-years away, providing new insights into early universe formation.',
      'icon': Icons.satellite_alt,
    },
    {
      'title': 'Meteor Shower Expected This Weekend',
      'date': 'Tomorrow',
      'description':
          'Astronomers predict a spectacular meteor shower will be visible in the northern hemisphere this weekend. Best viewing times are between 11 PM and 3 AM local time.',
      'icon': Icons.star,
    },
    {
      'title': 'Solar Eclipse Coming Next Month',
      'date': 'Next Month',
      'description':
          'A partial solar eclipse will be visible across parts of North America next month. Remember to use proper eye protection when viewing.',
      'icon': Icons.wb_sunny,
    },
    {
      'title': 'New Exoplanet Discovered in Habitable Zone',
      'date': 'This Week',
      'description':
          'Scientists have discovered a new Earth-sized exoplanet orbiting within the habitable zone of its star, making it a potential candidate for supporting life.',
      'icon': Icons.public,
    },
    {
      'title': 'Supernova Observed in Nearby Galaxy',
      'date': 'Yesterday',
      'description':
          'Astronomers have observed a supernova in a galaxy just 50 million light-years away, providing a rare opportunity to study these stellar explosions in detail.',
      'icon': Icons.flash_on,
    },
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch real astronomy news
    _fetchAstronomyNews();
  }

  // Method to fetch astronomy news from the web
  Future<void> _fetchAstronomyNews() async {
    // In a real app, you would make an API call here
    // For now, we'll simulate a delay and use our predefined news
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading astronomy news...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Astronomy News & Events',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.open_in_new),
                tooltip: 'Visit Sky & Telescope',
                onPressed: () => _launchSkyAndTelescopeUrl(),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Tap the button above to visit Sky & Telescope for the latest astronomy news',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 20),
          ...List.generate(
            _astronomyNews.length,
            (index) => Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _astronomyNews[index]['icon'],
                          color: Colors.amber,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _astronomyNews[index]['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        SizedBox(width: 4),
                        Text(
                          _astronomyNews[index]['date'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(_astronomyNews[index]['description']),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.open_in_new),
                        label: Text('Read More'),
                        onPressed: () {
                          _launchNewsUrl(_astronomyNews[index]['title']);
                        },
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

  Future<void> _launchSkyAndTelescopeUrl() async {
    final url = Uri.parse('https://skyandtelescope.org/astronomy-news/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch Sky & Telescope website')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  Future<void> _launchNewsUrl(String query) async {
    final url = Uri.parse(
        'https://www.google.com/search?q=astronomy+${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch web search')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }
}

// Placeholder for Event Tracker Screen
class EventTrackerScreen extends StatefulWidget {
  const EventTrackerScreen({Key? key}) : super(key: key);

  @override
  _EventTrackerScreenState createState() => _EventTrackerScreenState();
}

class _EventTrackerScreenState extends State<EventTrackerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _issPasses = [];
  final AstronomyAPI _astronomyAPI = AstronomyAPI();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch celestial events for the selected date
      final events = await _astronomyAPI.getTonightsEvents();
      final issPasses = await _astronomyAPI.getISSPasses();

      setState(() {
        _events = events;
        _issPasses = issPasses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not fetch celestial events. Please check your connection.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchEvents,
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 7)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined),
            tooltip: 'Search real-time events',
            onPressed: () {
              _astronomyAPI.searchAstronomyConditions();
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Select date',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading celestial events...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selected Date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the calendar icon to change date',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Celestial Events',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _events.isEmpty
                      ? Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No celestial events found for this date',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _events.map((event) {
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event['event'] ?? 'Unknown Event',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.amber.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event['time'] ?? 'Unknown Time',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      event['description'] ??
                                          'No description available',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    if (event.containsKey('additionalInfo') &&
                                        event['additionalInfo'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          event['additionalInfo'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 20),
                  Text(
                    'ISS Passes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _issPasses.isEmpty
                      ? Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No ISS passes found for this date',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _issPasses.map((pass) {
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ISS Pass',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon:
                                                  Icon(Icons.search, size: 16),
                                              tooltip: 'Search real ISS passes',
                                              onPressed: () {
                                                _astronomyAPI.searchISSPasses();
                                              },
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.access_time,
                                                size: 16, color: Colors.blue),
                                            SizedBox(width: 4),
                                            Text(
                                              '${pass['startTime']} - ${pass['endTime']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.timer,
                                            size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          'Duration: ${pass['duration']} minutes',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.height,
                                            size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          'Max Elevation: ${pass['maxElevation']}°',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'The International Space Station will be visible to the naked eye as a bright moving point of light across the night sky.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viewing Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          _buildTip(
                            'For best viewing, find a dark location away from city lights.',
                          ),
                          _buildTip(
                            'Allow your eyes at least 20 minutes to adjust to the darkness.',
                          ),
                          _buildTip(
                            'Use the Light Pollution Map to find dark sky locations near you.',
                          ),
                          _buildTip(
                            'Set a reminder 15 minutes before each event to prepare.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Light Pollution Map Screen
class LightPollutionScreen extends StatelessWidget {
  const LightPollutionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Pollution Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined),
            tooltip: 'Search real-time light pollution data',
            onPressed: () {
              _searchLightPollutionMap(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Understanding Light Pollution',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Light pollution is excessive or misdirected artificial light that affects the visibility of the night sky. Finding dark sky locations is essential for astrophotography and stargazing.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Light Pollution Map',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'View the light pollution map for your area. Tap the button below to open the interactive map.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 48, color: Colors.blue),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.open_in_browser),
                              label: Text('Open Light Pollution Map'),
                              onPressed: () => _launchUrl(
                                  'https://www.lightpollutionmap.info/#zoom=3.91&lat=46.1567&lon=14.2627&state=eyJiYXNlbWFwIjoiTGF5ZXJCaW5nUm9hZCIsIm92ZXJsYXkiOiJ3YV8yMDE1Iiwib3ZlcmxheWNvbG9yIjpmYWxzZSwib3ZlcmxheW9wYWNpdHkiOjYwLCJmZWF0dXJlc29wYWNpdHkiOjg1fQ=='),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bortle Scale',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'The Bortle scale is a nine-level numeric scale that measures the night sky\'s brightness of a particular location. It quantifies the astronomical observability of celestial objects and the interference caused by light pollution.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    _buildBortleScaleItem(
                      level: '1',
                      name: 'Excellent dark-sky site',
                      color: Colors.indigo.shade900,
                      description:
                          'The Milky Way casts shadows, airglow is visible, Jupiter and Venus affect night vision.',
                    ),
                    _buildBortleScaleItem(
                      level: '2',
                      name: 'Typical truly dark site',
                      color: Colors.indigo.shade700,
                      description:
                          'Airglow may be weakly visible, Milky Way highly structured to the unaided eye.',
                    ),
                    _buildBortleScaleItem(
                      level: '3',
                      name: 'Rural sky',
                      color: Colors.indigo.shade500,
                      description:
                          'Some light pollution evident at the horizon, clouds illuminated near horizon, Milky Way still appears complex.',
                    ),
                    _buildBortleScaleItem(
                      level: '4',
                      name: 'Rural/suburban transition',
                      color: Colors.indigo.shade300,
                      description:
                          'Light pollution domes visible in several directions, Milky Way still impressive but lacks detail.',
                    ),
                    _buildBortleScaleItem(
                      level: '5',
                      name: 'Suburban sky',
                      color: Colors.blue.shade300,
                      description:
                          'Light pollution visible in most directions, Milky Way washed out at zenith and invisible at horizon.',
                    ),
                    _buildBortleScaleItem(
                      level: '6',
                      name: 'Bright suburban sky',
                      color: Colors.green.shade300,
                      description:
                          'Light pollution makes the sky glow grayish white, Milky Way only visible at zenith.',
                    ),
                    _buildBortleScaleItem(
                      level: '7',
                      name: 'Suburban/urban transition',
                      color: Colors.yellow.shade300,
                      description:
                          'Entire sky has a grayish-white hue, strong light sources visible in all directions.',
                    ),
                    _buildBortleScaleItem(
                      level: '8',
                      name: 'City sky',
                      color: Colors.orange.shade300,
                      description:
                          'Sky glows whitish gray or orange, newspapers can be read without difficulty.',
                    ),
                    _buildBortleScaleItem(
                      level: '9',
                      name: 'Inner-city sky',
                      color: Colors.red.shade300,
                      description:
                          'Entire sky is brightly lit, even at zenith. Many stars forming constellations are invisible.',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finding Dark Sky Locations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Use these resources to find dark sky locations near you:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    _buildDarkSkyResource(
                      'Dark Site Finder',
                      'Interactive light pollution map to find dark sky locations worldwide.',
                      Icons.map,
                      () => _launchUrl(
                          'https://darksitefinder.com/maps/world.html'),
                    ),
                    _buildDarkSkyResource(
                      'International Dark Sky Places',
                      'Certified locations that preserve the night sky.',
                      Icons.star,
                      () => _launchUrl(
                          'https://www.darksky.org/our-work/conservation/idsp/'),
                    ),
                    _buildDarkSkyResource(
                      'Clear Dark Sky',
                      'Astronomy forecasts for locations in the US and Canada.',
                      Icons.wb_sunny,
                      () => _launchUrl('https://www.cleardarksky.com/'),
                    ),
                    _buildDarkSkyResource(
                      'Light Pollution Map',
                      'Detailed maps based on satellite data.',
                      Icons.public,
                      () => _launchUrl('https://www.lightpollutionmap.info/'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for Light Polluted Areas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTipItem(
                      'Use Light Pollution Filters',
                      'Specialized filters can help reduce the effects of light pollution for certain types of astrophotography.',
                    ),
                    _buildTipItem(
                      'Focus on Bright Objects',
                      'The Moon, planets, and bright star clusters are still visible from light-polluted areas.',
                    ),
                    _buildTipItem(
                      'Try Narrowband Imaging',
                      'Narrowband filters isolate specific wavelengths of light emitted by nebulae, cutting through light pollution.',
                    ),
                    _buildTipItem(
                      'Image Stacking',
                      'Use our Image Stacker feature to combine multiple exposures, which can help reduce noise from light pollution.',
                    ),
                    _buildTipItem(
                      'Plan Around the Moon',
                      'Schedule your astrophotography sessions during the new moon phase for darker skies.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBortleScaleItem({
    required String level,
    required String name,
    required Color color,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              level,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkSkyResource(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.amber, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  // Add a method to search for light pollution maps online
  void _searchLightPollutionMap(BuildContext context) async {
    try {
      // Get user's location
      final position = await Geolocator.getCurrentPosition();
      final url = Uri.parse(
          'https://www.lightpollutionmap.info/#zoom=8&lat=${position.latitude}&lon=${position.longitude}');

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error launching search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open light pollution map: $e')),
      );
    }
  }
}

// Camera Settings Guide Screen
class SettingsGuideScreen extends StatelessWidget {
  const SettingsGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Settings Guide')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Astrophotography Camera Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Capturing the night sky requires specific camera settings to get the best results. Use this guide to optimize your settings based on what you\'re trying to photograph.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildSettingsCard(
              title: 'General Night Sky',
              icon: Icons.nightlight_round,
              settings: [
                {'name': 'Aperture', 'value': 'f/2.8 or wider'},
                {'name': 'Shutter Speed', 'value': '15-30 seconds'},
                {'name': 'ISO', 'value': '1600-3200'},
                {'name': 'Focus', 'value': 'Manual, set to infinity'},
                {'name': 'White Balance', 'value': 'Auto or 3500-4500K'},
              ],
              tips:
                  'Use a tripod and remote shutter release to avoid camera shake. Turn off image stabilization when using a tripod.',
            ),
            _buildSettingsCard(
              title: 'Milky Way',
              icon: Icons.blur_on,
              settings: [
                {'name': 'Aperture', 'value': 'f/2.8 or wider'},
                {'name': 'Shutter Speed', 'value': '20-30 seconds'},
                {'name': 'ISO', 'value': '3200-6400'},
                {'name': 'Focus', 'value': 'Manual, set to infinity'},
                {'name': 'White Balance', 'value': '3900K'},
              ],
              tips:
                  'Use the 500 rule to avoid star trails: 500 ÷ (focal length × crop factor) = max exposure time in seconds.',
            ),
            _buildSettingsCard(
              title: 'Moon',
              icon: Icons.brightness_3,
              settings: [
                {'name': 'Aperture', 'value': 'f/8-f/11'},
                {'name': 'Shutter Speed', 'value': '1/100-1/250 sec'},
                {'name': 'ISO', 'value': '100-400'},
                {'name': 'Focus', 'value': 'Manual, set to infinity'},
                {'name': 'White Balance', 'value': 'Daylight (5500K)'},
              ],
              tips:
                  'The moon is very bright! Use settings similar to daylight photography. Consider using a telephoto lens (200mm+) for detailed shots.',
            ),
            _buildSettingsCard(
              title: 'Star Trails',
              icon: Icons.motion_photos_on,
              settings: [
                {'name': 'Aperture', 'value': 'f/2.8-f/4'},
                {'name': 'Shutter Speed', 'value': '30+ minutes (Bulb mode)'},
                {'name': 'ISO', 'value': '400-800'},
                {'name': 'Focus', 'value': 'Manual, set to infinity'},
                {'name': 'White Balance', 'value': 'Auto or 4000K'},
              ],
              tips:
                  'Use an intervalometer for exposures longer than 30 seconds. Alternatively, take multiple 30-second exposures and stack them using the Image Stacker feature.',
            ),
            _buildSettingsCard(
              title: 'Planets',
              icon: Icons.public,
              settings: [
                {'name': 'Aperture', 'value': 'f/5.6-f/8'},
                {'name': 'Shutter Speed', 'value': '1/60-1/125 sec'},
                {'name': 'ISO', 'value': '400-800'},
                {'name': 'Focus', 'value': 'Manual, set to infinity'},
                {'name': 'White Balance', 'value': 'Auto'},
              ],
              tips:
                  'Use a telescope or telephoto lens (300mm+). Consider using a Barlow lens to increase magnification.',
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equipment Recommendations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildEquipmentItem(
                      'Sturdy Tripod',
                      'Essential for long exposures to prevent camera shake.',
                    ),
                    _buildEquipmentItem(
                      'Remote Shutter Release/Intervalometer',
                      'Prevents camera shake when pressing the shutter button and allows for exposures longer than 30 seconds.',
                    ),
                    _buildEquipmentItem(
                      'Fast Lens',
                      'A lens with a wide aperture (f/2.8 or wider) will gather more light.',
                    ),
                    _buildEquipmentItem(
                      'Red Flashlight',
                      'Preserves your night vision while allowing you to see your equipment.',
                    ),
                    _buildEquipmentItem(
                      'Extra Batteries',
                      'Long exposures and cold temperatures drain batteries quickly.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Map<String, String>> settings,
    required String tips,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 20),
            ...settings.map((setting) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          setting['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(setting['value']!),
                      ),
                    ],
                  ),
                )),
            Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: $tips',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for Tonight's Best Screen
class TonightsBestScreen extends StatefulWidget {
  const TonightsBestScreen({Key? key}) : super(key: key);

  @override
  _TonightsBestScreenState createState() => _TonightsBestScreenState();
}

class _TonightsBestScreenState extends State<TonightsBestScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stargazingConditions = {};
  List<Map<String, dynamic>> _recommendedObjects = [];
  final AstronomyAPI _astronomyAPI = AstronomyAPI();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conditions = await _astronomyAPI.getAllStargazingConditions();

      // Generate recommendations based on conditions
      final recommendations = _generateRecommendations(conditions);

      setState(() {
        _stargazingConditions = conditions;
        _recommendedObjects = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not fetch astronomy data. Please check your connection.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchData,
          ),
        ),
      );
    }
  }

  // Generate object recommendations based on current conditions
  List<Map<String, dynamic>> _generateRecommendations(
      Map<String, dynamic> conditions) {
    // This would ideally use the API data to determine what's visible tonight
    // For now, we'll use a simplified algorithm based on moon phase and cloud cover

    List<Map<String, dynamic>> recommendations = [];

    // Get moon illumination (0-1)
    double moonIllumination = 0.0;
    if (conditions.containsKey('moonPhase')) {
      moonIllumination = conditions['moonPhase']['illumination'] ?? 0.0;
    }

    // Get cloud cover percentage (0-100)
    int cloudCover = 0;
    if (conditions.containsKey('weather') &&
        conditions['weather'].containsKey('current')) {
      cloudCover = conditions['weather']['current']['clouds'] ?? 0;
    }

    // Determine if conditions are good for deep sky objects
    bool goodForDeepSky = moonIllumination < 0.3 && cloudCover < 30;

    // Determine if conditions are good for planets/moon
    bool goodForBrightObjects = cloudCover < 50;

    // Add recommendations based on conditions
    if (goodForDeepSky) {
      recommendations.addAll([
        {
          'name': 'Andromeda Galaxy (M31)',
          'type': 'Galaxy',
          'magnitude': '3.4',
          'description':
              'The Andromeda Galaxy is the closest major galaxy to our Milky Way. Under dark skies, it appears as a fuzzy patch in the constellation Andromeda.',
          'bestViewing': 'Binoculars or telescope with low power',
          'rating': 5,
        },
        {
          'name': 'Orion Nebula (M42)',
          'type': 'Nebula',
          'magnitude': '4.0',
          'description':
              'The Orion Nebula is a diffuse nebula situated in the Milky Way, being south of Orion\'s Belt. It\'s one of the brightest nebulae and visible to the naked eye.',
          'bestViewing':
              'Visible to naked eye, better with binoculars or telescope',
          'rating': 5,
        },
        {
          'name': 'Pleiades (M45)',
          'type': 'Star Cluster',
          'magnitude': '1.6',
          'description':
              'The Pleiades, also known as the Seven Sisters, is an open star cluster containing middle-aged, hot B-type stars in the constellation Taurus.',
          'bestViewing': 'Visible to naked eye, spectacular in binoculars',
          'rating': 4,
        },
      ]);
    }

    if (goodForBrightObjects) {
      recommendations.addAll([
        {
          'name': 'Jupiter',
          'type': 'Planet',
          'magnitude': '-2.2',
          'description':
              'Jupiter is the largest planet in our solar system and one of the brightest objects in the night sky. With a small telescope, you can see its four largest moons and cloud bands.',
          'bestViewing': 'Visible to naked eye, telescope shows details',
          'rating': 5,
        },
        {
          'name': 'Saturn',
          'type': 'Planet',
          'magnitude': '0.6',
          'description':
              'Saturn is famous for its spectacular ring system. Even a small telescope will show the rings and its largest moon, Titan.',
          'bestViewing': 'Visible to naked eye, telescope needed for rings',
          'rating': 5,
        },
      ]);
    }

    // Always include the Moon if it's visible tonight
    if (moonIllumination > 0.1) {
      recommendations.add({
        'name': 'The Moon',
        'type': 'Satellite',
        'magnitude': '-12.7',
        'description':
            'Our nearest celestial neighbor offers spectacular views of craters, mountains, and maria (dark plains). The best time to observe is along the terminator (the line between light and dark).',
        'bestViewing':
            'Visible to naked eye, binoculars or telescope show details',
        'rating': 5,
      });
    }

    // If conditions are poor, focus on the brightest objects
    if (!goodForDeepSky && !goodForBrightObjects) {
      recommendations.add({
        'name': 'Sirius',
        'type': 'Star',
        'magnitude': '-1.46',
        'description':
            'Sirius is the brightest star in the night sky. It\'s a binary star system, but the companion is difficult to see due to the brightness of the main star.',
        'bestViewing': 'Visible to naked eye',
        'rating': 3,
      });
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tonight's Best"),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined),
            tooltip: 'Search real-time data',
            onPressed: () {
              _astronomyAPI.searchAstronomyConditions();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Finding the best objects to observe tonight...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tonight's Viewing Conditions",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.open_in_new),
                                tooltip: 'Find tonight\'s best objects online',
                                onPressed: () => _searchTonightsBestObjects(),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildConditionItem(
                                icon: Icons.visibility,
                                label: 'Visibility',
                                value: _getVisibilityValue(),
                                color: _getVisibilityColor(),
                              ),
                              _buildConditionItem(
                                icon: Icons.cloud,
                                label: 'Cloud Cover',
                                value: _getCloudCoverValue(),
                                color: _getCloudCoverColor(),
                              ),
                              _buildConditionItem(
                                icon: Icons.brightness_3,
                                label: 'Moon Phase',
                                value: _getMoonPhaseValue(),
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _getOverallRecommendation(),
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Recommended Objects',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _recommendedObjects.isEmpty
                      ? Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No recommended objects for tonight',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _recommendedObjects.map((object) {
                            return _buildObjectCard(object);
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildConditionItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Improved layout for Android
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (label == 'Visibility' || label == 'Cloud Cover')
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InkWell(
                onTap: () async {
                  final url = label == 'Visibility'
                      ? Uri.parse('https://www.cleardarksky.com/')
                      : Uri.parse('https://www.accuweather.com/');
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    throw Exception('Could not launch URL');
                  }
                },
                child: Text(
                  'Check ${label == 'Visibility' ? 'Map' : 'Forecast'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForObjectType(String type) {
    switch (type.toLowerCase()) {
      case 'planet':
        return Icons.public;
      case 'moon':
      case 'satellite':
        return Icons.brightness_3;
      case 'star':
        return Icons.star;
      case 'star cluster':
        return Icons.auto_awesome;
      case 'galaxy':
        return Icons.blur_circular;
      case 'nebula':
        return Icons.cloud;
      default:
        return Icons.nightlight_round;
    }
  }

  // Helper methods to extract data from API response
  String _getVisibilityValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('visibility')) {
      return 'Unknown';
    }

    final visibility = _stargazingConditions['visibility'];
    return visibility['visibility'] ?? 'Unknown';
  }

  Color _getVisibilityColor() {
    final value = _getVisibilityValue();
    if (value == 'Good') return Colors.green;
    if (value == 'Average' || value == 'OK') return Colors.orange;
    if (value == 'Poor' || value == 'Bad') return Colors.red;
    return Colors.grey;
  }

  String _getCloudCoverValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('weather') ||
        !_stargazingConditions['weather'].containsKey('current')) {
      return 'Unknown';
    }

    final weather = _stargazingConditions['weather'];
    final clouds = weather['current']['clouds'] ?? 0;
    return '$clouds%';
  }

  Color _getCloudCoverColor() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('weather') ||
        !_stargazingConditions['weather'].containsKey('current')) {
      return Colors.grey;
    }

    final weather = _stargazingConditions['weather'];
    final clouds = weather['current']['clouds'] ?? 0;

    if (clouds < 20) return Colors.green;
    if (clouds < 50) return Colors.orange;
    return Colors.red;
  }

  String _getMoonPhaseValue() {
    if (_stargazingConditions.isEmpty ||
        !_stargazingConditions.containsKey('moonPhase')) {
      return 'Unknown';
    }

    final moonPhase = _stargazingConditions['moonPhase'];
    final illumination = moonPhase['illumination'] ?? 0.0;
    return '${(illumination * 100).toInt()}%';
  }

  String _getOverallRecommendation() {
    // Get cloud cover percentage (0-100)
    int cloudCover = 0;
    if (_stargazingConditions.containsKey('weather') &&
        _stargazingConditions['weather'].containsKey('current')) {
      cloudCover = _stargazingConditions['weather']['current']['clouds'] ?? 0;
    }

    // Get moon illumination (0-1)
    double moonIllumination = 0.0;
    if (_stargazingConditions.containsKey('moonPhase')) {
      moonIllumination =
          _stargazingConditions['moonPhase']['illumination'] ?? 0.0;
    }

    if (cloudCover > 70) {
      return 'Poor conditions for stargazing tonight due to cloud cover. Consider indoor astronomy activities.';
    } else if (cloudCover > 30) {
      return 'Moderate cloud cover tonight. Focus on brighter objects like planets and the Moon.';
    } else if (moonIllumination > 0.7) {
      return 'Clear skies but bright moonlight. Great for lunar observation, but deep sky objects will be washed out.';
    } else if (moonIllumination < 0.3 && cloudCover < 20) {
      return 'Excellent conditions for deep sky objects tonight! Dark skies and minimal cloud cover.';
    } else {
      return 'Good stargazing conditions tonight. Both bright objects and some deep sky targets should be visible.';
    }
  }

  Widget _buildObjectCard(Map<String, dynamic> object) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 150,
            color: Colors.blueGrey[800],
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getIconForObjectType(object['type']),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    tooltip: 'Search for ${object['name']} online',
                    onPressed: () {
                      _searchObjectOnline(object['name']);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        object['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Mag: ${object['magnitude']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  object['type'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  object['description'],
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Best viewing: ${object['bestViewing']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (object['rating'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add a method to search for celestial objects online
  void _searchObjectOnline(String objectName) async {
    final url = Uri.parse(
        'https://www.google.com/search?q=how+to+observe+${Uri.encodeComponent(objectName)}+tonight+astronomy');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error launching search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open search: $e')),
      );
    }
  }

  // Add a method to search for tonight's best objects online
  void _searchTonightsBestObjects() async {
    final url = Uri.parse(
        'https://skyandtelescope.org/observing/celestial-objects-to-watch/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error launching search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open search: $e')),
      );
    }
  }
}

// Search Screen Implementation
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    // Simulate search results
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _searchResults = [
          {
            'name': 'Andromeda Galaxy',
            'type': 'Galaxy',
            'description':
                'The Andromeda Galaxy is a spiral galaxy approximately 2.5 million light-years from Earth.',
            'icon': Icons.blur_circular,
          },
          {
            'name': 'Jupiter',
            'type': 'Planet',
            'description':
                'Jupiter is the fifth planet from the Sun and the largest in the Solar System.',
            'icon': Icons.public,
          },
          {
            'name': 'Orion Nebula',
            'type': 'Nebula',
            'description':
                'The Orion Nebula is a diffuse nebula situated in the Milky Way.',
            'icon': Icons.cloud,
          },
          {
            'name': 'Pleiades',
            'type': 'Star Cluster',
            'description':
                'The Pleiades, also known as the Seven Sisters, is an open star cluster.',
            'icon': Icons.auto_awesome,
          },
          {
            'name': 'Sirius',
            'type': 'Star',
            'description': 'Sirius is the brightest star in the night sky.',
            'icon': Icons.star,
          },
        ]
            .where((item) =>
                item['name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                item['type']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                item['description']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Celestial Objects'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for stars, planets, galaxies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          if (_isSearching)
            Center(
              child: CircularProgressIndicator(),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No results found for "${_searchController.text}"',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading:
                          Icon(result['icon'], color: Colors.amber, size: 36),
                      title: Text(result['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result['type'],
                            style: TextStyle(color: Colors.blue),
                          ),
                          SizedBox(height: 4),
                          Text(result['description']),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        // Show detailed information
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(result['name']),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(result['icon'],
                                    color: Colors.amber, size: 50),
                                SizedBox(height: 16),
                                Text('Type: ${result['type']}'),
                                SizedBox(height: 8),
                                Text(result['description']),
                                SizedBox(height: 16),
                                Text(
                                  'This is a placeholder for detailed information about ${result['name']}.',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
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

// Image Stacker Screen Implementation
class ImageStackerScreen extends StatefulWidget {
  const ImageStackerScreen({Key? key}) : super(key: key);

  @override
  _ImageStackerScreenState createState() => _ImageStackerScreenState();
}

class _ImageStackerScreenState extends State<ImageStackerScreen> {
  final List<File> _selectedImages = [];
  bool _isProcessing = false;
  bool _isSaving = false;
  File? _resultImage;
  final ImagePicker _picker = ImagePicker();
  final ImageProcessor _imageProcessor = ImageProcessor();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages
              .addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
      _resultImage = null;
    });
  }

  Future<void> _processImages() async {
    if (_selectedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least 2 images to stack')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call the static method correctly
      final result = await ImageProcessor.stackImages(_selectedImages);

      setState(() {
        _resultImage = result;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images stacked successfully!')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stacking images: $e')),
      );
    }
  }

  Future<void> _saveResultImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // For Android platform
      if (Platform.isAndroid) {
        // Request storage permission for Android
        var status = await Permission.storage.request();
        if (status.isGranted) {
          // Create a copy of the image in the app's documents directory
          final bytes = await _resultImage!.readAsBytes();
          final directory = await getApplicationDocumentsDirectory();

          // Create a new file with a timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newPath = '${directory.path}/celestify_$timestamp.jpg';
          final newFile = File(newPath);

          // Write the bytes to the new file
          await newFile.writeAsBytes(bytes);

          // For Android, we can use the MediaStore API to add the image to the gallery
          // This is a simplified version - in a production app, you would use a plugin like image_gallery_saver
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to app documents folder'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Storage permission denied')),
          );
        }
      } else {
        // For other platforms, show a message that this feature is optimized for Android
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('This feature is currently optimized for Android devices'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use the Android-optimized layout
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxisCount =
        screenWidth < 400 ? 2 : 3; // Adjust grid columns based on screen width

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Stacker'),
        backgroundColor: Colors.black87,
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              tooltip: 'Clear all images',
              onPressed: _clearImages,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is Image Stacking?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Image stacking is a technique used in astrophotography to combine multiple exposures of the same subject, reducing noise and enhancing details that might not be visible in a single exposure. You can stack up to 100 images for best results.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Image selection buttons - optimized for Android
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.photo_library),
                      label: Text('Select Images'),
                      onPressed: _pickImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Photo'),
                      onPressed: _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Selected images display
              if (_selectedImages.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 64, color: Colors.grey[600]),
                        SizedBox(height: 16),
                        Text(
                          'No images selected',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Select multiple images to stack',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Images (${_selectedImages.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.delete_outline, size: 18),
                          label: Text('Clear All'),
                          onPressed: _clearImages,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[300],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

              SizedBox(height: 24),

              // Stack button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.auto_awesome),
                  label: Text(_isProcessing ? 'Processing...' : 'Stack Images'),
                  onPressed: _selectedImages.length < 2 || _isProcessing
                      ? null
                      : _processImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Result image
              if (_isProcessing)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: 16),
                      Text('Processing images...'),
                    ],
                  ),
                )
              else if (_resultImage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_resultImage!),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.save_alt),
                            label: Text(_isSaving ? 'Saving...' : 'Save Image'),
                            onPressed: _isSaving ? null : _saveResultImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.share),
                            label: Text('Share'),
                            onPressed: () {
                              // Share functionality would be implemented here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Share functionality coming soon')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
