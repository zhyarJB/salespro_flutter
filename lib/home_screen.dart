import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'visit_activity_screen.dart';
import 'orders_screen.dart';

class PlaceMarker {
  final int id;
  final LatLng position;
  final String name;
  final String type;
  final String? address;
  final String? contactPerson;
  final String? phone;
  final String? email;
  PlaceMarker({required this.id, required this.position, required this.name, required this.type, this.address, this.contactPerson, this.phone, this.email});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final List<String> categories;
  late final List<String> categoryDisplayNames;
  int selectedCategory = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _visitStarted = false;
  static const String _elapsedKey = 'visit_elapsed';
  static const String _visitStartedKey = 'visit_started';

  static const LatLng erbilLatLng = LatLng(36.1911, 44.0092);

  List<PlaceMarker> _markers = [];
  bool _isLoading = true;
  String? _salesRepName;
  LatLng? _currentPosition;
  late final MapController _mapController = MapController();
  PlaceMarker? _selectedMarker;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categories = ['all', 'pharmacy', 'doctor', 'drugstore', 'clinic'];
    categoryDisplayNames = ['All', 'Pharmacy', 'Doctor', 'Drugstore', 'Clinic'];
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _restoreVisitState();
    _fetchProfile();
    _fetchLocations();
    _getCurrentLocation();
  }

  Future<void> _restoreVisitState() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_elapsedKey) ?? 0;
    final started = prefs.getBool(_visitStartedKey) ?? false;
    setState(() {
      _elapsed = Duration(seconds: seconds);
      _visitStarted = started;
    });
    if (_visitStarted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsed = _elapsed + const Duration(seconds: 1);
        });
        _saveVisitState();
      });
    }
  }

  Future<void> _saveVisitState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_elapsedKey, _elapsed.inSeconds);
    await prefs.setBool(_visitStartedKey, _visitStarted);
  }

  Future<void> _fetchProfile() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) return;
      final baseUrl = await AuthService.getBaseUrl();
      final url = Uri.parse('$baseUrl/profile');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _salesRepName = data['data']['user']['name'] ?? 'Sales Rep';
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _fetchLocations() async {
    setState(() { _isLoading = true; });
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        setState(() { _isLoading = false; });
        return;
      }
      final baseUrl = await AuthService.getBaseUrl();
      final url = Uri.parse('$baseUrl/locations');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final locations = data['data']['locations'] as List<dynamic>;
        setState(() {
          _markers = locations
              .where((loc) => loc['latitude'] != null && loc['longitude'] != null)
              .map((loc) => PlaceMarker(
                    id: loc['id'],
                    position: LatLng(
                      (loc['latitude'] as num).toDouble(),
                      (loc['longitude'] as num).toDouble(),
                    ),
                    name: loc['name'] ?? '',
                    type: loc['type'] ?? '',
                    address: loc['address'] as String?,
                    contactPerson: loc['contact_person'] as String?,
                    phone: loc['phone'] as String?,
                    email: loc['email'] as String?,
                  ))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied. Please allow location access.')),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission permanently denied. Please enable it in settings.')),
        );
      }
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _startVisit() {
    setState(() {
      _visitStarted = true;
      if (_elapsed == Duration.zero) {
        _elapsed = Duration.zero;
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });
      _saveVisitState();
    });
    _saveVisitState();
  }

  void _stopVisit() {
    _timer?.cancel();
    setState(() {
      _visitStarted = false;
    });
    _saveVisitState();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  Future<void> _showAddMarkerDialog(LatLng latlng) async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String type = categories[0];
    String contactPerson = '';
    String phone = '';
    String email = '';
    String address = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Place'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Place Name'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: categories.asMap().entries.map((entry) => DropdownMenuItem(
                      value: entry.value,
                      child: Text(categoryDisplayNames[entry.key]),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) type = value;
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contact Person'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter contact person' : null,
                    onChanged: (value) => contactPerson = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter phone' : null,
                    onChanged: (value) => phone = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => email = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                    onChanged: (value) => address = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _saveLocationToBackend(name, type, latlng, contactPerson, phone, email, address);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocationToBackend(String name, String type, LatLng latlng, String contactPerson, String phone, String email, String address) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return;
    }
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/locations');
    final body = {
      'name': name,
      'type': type,
      'latitude': latlng.latitude,
      'longitude': latlng.longitude,
      'address': address,
      'contact_person': contactPerson,
      'phone': phone,
    };
    if (email.isNotEmpty) {
      body['email'] = email;
    }
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final newLocation = responseData['data']['location'] ?? responseData['data'];
      setState(() {
        _markers.add(PlaceMarker(
          id: newLocation['id'],
          position: latlng,
          name: name,
          type: type,
          address: address,
          contactPerson: contactPerson,
          phone: phone,
          email: email,
        ));
      });
      await _fetchLocations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PinPoint: ${response.body}')),
      );
    }
  }

  Icon _getMarkerIcon(String type) {
    switch (type) {
      case 'pharmacy':
        return const Icon(Icons.location_on, color: Colors.purple, size: 36);
      case 'doctor':
        return const Icon(Icons.location_on, color: Colors.blue, size: 36);
      case 'drugstore':
        return const Icon(Icons.location_on, color: Colors.orange, size: 36);
      case 'clinic':
        return const Icon(Icons.location_on, color: Colors.red, size: 36);
      default:
        return const Icon(Icons.location_on, color: Colors.green, size: 36);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for place',
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.brown,
                      child: Text(
                        (_salesRepName != null && _salesRepName!.isNotEmpty)
                          ? _salesRepName![0].toUpperCase()
                          : '',
                        style: const TextStyle(fontSize: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _salesRepName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                title: const Text('My Orders'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: const Text('Calendar'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.green),
                title: const Text('Report'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.add_location_alt, color: Colors.orange),
                title: const Text('Suggest Place'),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.teal),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Language'),
                    Text('English', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final authService = AuthService();
                  final token = await authService.getToken();
                  if (token != null) {
                    final baseUrl = await AuthService.getBaseUrl();
                    final url = Uri.parse('$baseUrl/logout');
                    await http.post(
                      url,
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                      },
                    );
                  }
                  await authService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '@SalesPro',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_currentPosition == null)
            FutureBuilder(
              future: Future.delayed(const Duration(seconds: 5)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _currentPosition == null) {
                  // return Container(
                  //   color: Colors.red[100],
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(8),
                  //   child: const Text(
                  //     'Unable to get your location. Please check permissions and location services.',
                  //     style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // );
                }
                return const SizedBox.shrink();
              },
            ),
          // Category filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(categories.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(categoryDisplayNames[index]),
                      selected: selectedCategory == index,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = index;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          // Real OpenStreetMap with marker adding
          Expanded(
            child: Stack(
              children: [
                Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: erbilLatLng,
                    initialZoom: 13.0,
                    onLongPress: (tapPosition, latlng) {
                      _showAddMarkerDialog(latlng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.salespro_flutter',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.my_location, color: Colors.blue, size: 36),
                          ),
                        ..._markers
                          .where((marker) {
                            final selected = categories[selectedCategory];
                            final matchesCategory = selected == 'all' || marker.type == selected;
                            final matchesSearch = searchQuery.isEmpty ||
                              marker.name.toLowerCase().contains(searchQuery) ||
                              marker.type.toLowerCase().contains(searchQuery);
                            return matchesCategory && matchesSearch;
                          })
                          .map((marker) => Marker(
                            point: marker.position,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                    _showLocationCard(marker);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getMarkerIcon(marker.type),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 80,
                                        maxHeight: 20,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          marker.name,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                      ],
                    ),
                  ],
                ),
              ),
                ),
                // Location Card Overlay
                if (_selectedMarker != null)
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: GestureDetector(
                        onTap: _hideLocationCard,
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: GestureDetector(
                                onTap: () {}, // Prevent tap from propagating to background
                                child: Container(
                              margin: const EdgeInsets.all(20.0),
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _getMarkerIcon(_selectedMarker!.type),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedMarker!.name,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: _hideLocationCard,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _infoRow('Type', _selectedMarker!.type),
                              _infoRow('Address', _selectedMarker!.address ?? ''),
                              _infoRow('Contact Person', _selectedMarker!.contactPerson ?? ''),
                              _infoRow('Phone', _selectedMarker!.phone ?? ''),
                              if ((_selectedMarker!.email ?? '').isNotEmpty)
                                _infoRow('Email', _selectedMarker!.email ?? ''),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _hideLocationCard();
                                        _showEditLocationDialog(_selectedMarker!);
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _hideLocationCard();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => VisitActivityScreen(
                                              placeId: _selectedMarker!.id,
                                              pharmacyName: _selectedMarker!.name,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Start'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
    )
    )
    ),
                  ),
    ],
            ),
          ),
          // Bottom action section with proper spacing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Working hours display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, size: 20, color: Color(0xFF4B3AFF)),
                        const SizedBox(width: 8),
                        Text(
                          'Working Hours: ${_formatDuration(_elapsed)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Start/Stop Visit button and Location button side by side
                  Row(
                    children: [
                      // Start/Stop Visit button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B3AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          onPressed: _visitStarted ? _stopVisit : _startVisit,
                          child: Text(
                            _visitStarted ? 'Stop Visit' : 'Start Visit',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Location button
                      FloatingActionButton(
                        onPressed: _getCurrentLocationAndCenter,
                        backgroundColor: const Color(0xFF4B3AFF),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        mini: false,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  void _showLocationCard(PlaceMarker marker) {
    setState(() {
      _selectedMarker = marker;
    });
    _animationController.forward();
  }

  void _hideLocationCard() {
    _animationController.reverse().then((_) {
      setState(() {
        _selectedMarker = null;
      });
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showEditLocationDialog(PlaceMarker marker) async {
    final _formKey = GlobalKey<FormState>();
    String name = marker.name;
    String type = marker.type;
    String contactPerson = marker.contactPerson ?? '';
    String phone = marker.phone ?? '';
    String email = marker.email ?? '';
    String address = marker.address ?? '';
    // Normalize type to match the categories list exactly
    if (!categories.contains(type)) {
      final match = categories.firstWhere(
        (cat) => cat == type,
        orElse: () => categories[0],
      );
      type = match;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Place'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Place Name'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: categories.asMap().entries.map((entry) => DropdownMenuItem(
                      value: entry.value,
                      child: Text(categoryDisplayNames[entry.key]),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) type = value;
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: contactPerson,
                    decoration: const InputDecoration(labelText: 'Contact Person'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter contact person' : null,
                    onChanged: (value) => contactPerson = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter phone' : null,
                    onChanged: (value) => phone = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Email (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => email = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                    onChanged: (value) => address = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _updateLocation(marker, name, type, contactPerson, phone, email, address);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLocation(PlaceMarker marker, String name, String type, String contactPerson, String phone, String email, String address) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return;
    }
    // Find location ID from backend data to update
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/locations');
    final getResponse = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final locations = data['data']['locations'] as List<dynamic>;
      final match = locations.firstWhere(
        (loc) =>
          (loc['name'] ?? '') == marker.name &&
          (loc['latitude'] as num).toDouble() == marker.position.latitude &&
          (loc['longitude'] as num).toDouble() == marker.position.longitude,
        orElse: () => null,
      );
      if (match != null) {
        final id = match['id'];
        final baseUrl = await AuthService.getBaseUrl();
        final updateUrl = Uri.parse('$baseUrl/locations/$id');
        final body = {
          'name': name,
          'type': type,
          'latitude': marker.position.latitude,
          'longitude': marker.position.longitude,
          'address': address,
          'contact_person': contactPerson,
          'phone': phone,
        };
        if (email.isNotEmpty) {
          body['email'] = email;
        }
        final putResponse = await http.put(
          updateUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
        if (putResponse.statusCode == 200) {
          await _fetchLocations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update location: ${putResponse.body}')),
          );
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentPosition!, 16.0);
      });
    }
  }

  void _getCurrentLocationAndCenter() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16.0);
    }
  }
}
