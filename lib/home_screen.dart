import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceMarker {
  final LatLng position;
  final String name;
  final String type;
  PlaceMarker({required this.position, required this.name, required this.type});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<String> categories;
  int selectedCategory = 0;

  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _visitStarted = false;

  static const LatLng erbilLatLng = LatLng(36.1911, 44.0092);

  List<PlaceMarker> _markers = [];
  bool _isLoading = true;
  String? _salesRepName;

  @override
  void initState() {
    super.initState();
    categories = ['Pharmacy', 'Doctor', 'Drugstore', 'Other'];
    _fetchProfile();
    _fetchLocations();
  }

  Future<void> _fetchProfile() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) return;
      final url = Uri.parse('http://10.0.2.2:8000/api/v1/profile');
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
        print('No auth token found for fetching locations.');
        return;
      }
      final url = Uri.parse('http://10.0.2.2:8000/api/v1/locations');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print('GET /locations status: ${response.statusCode}');
      print('API response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final locations = data['data']['locations'] as List<dynamic>;
        setState(() {
          _markers = locations
              .where((loc) => loc['latitude'] != null && loc['longitude'] != null)
              .map((loc) => PlaceMarker(
                    position: LatLng(
                      (loc['latitude'] as num).toDouble(),
                      (loc['longitude'] as num).toDouble(),
                    ),
                    name: loc['name'] ?? '',
                    type: loc['type'] ?? '',
                  ))
              .toList();
          _isLoading = false;
        });
        print('Markers after fetch: $_markers');
      } else {
        setState(() { _isLoading = false; });
        print('Failed to fetch locations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      print('Error fetching locations: $e');
    }
  }

  void _startVisit() {
    setState(() {
      _visitStarted = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });
    });
  }

  void _stopVisit() {
    _timer?.cancel();
    setState(() {
      _visitStarted = false;
      _elapsed = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  Future<void> _showAddMarkerDialog(LatLng latlng) async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String type = categories[0];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Place'),
          content: Form(
            key: _formKey,
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
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) type = value;
                  },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ],
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
                  // Save to backend
                  await _saveLocationToBackend(name, type, latlng);
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

  Future<void> _saveLocationToBackend(String name, String type, LatLng latlng) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      print('No auth token found.');
      return;
    }
    final url = Uri.parse('http://10.0.2.2:8000/api/v1/locations');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'type': type.toLowerCase(),
        'latitude': latlng.latitude,
        'longitude': latlng.longitude,
        'address': 'Unknown',
      }),
    );
    print('POST /locations status: ${response.statusCode}');
    print('POST /locations response: ${response.body}');
    if (response.statusCode == 201) {
      setState(() {
        _markers.add(PlaceMarker(position: latlng, name: name, type: type));
      });
      print('PinPoint added and saved to backend: $name, $type, $latlng');
      print('Markers after add: $_markers');
      await _fetchLocations();
    } else {
      print('Failed to save PinPoint: ${response.body}');
      // Optionally show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PinPoint: ${response.body}')),
      );
    }
  }

  Icon _getMarkerIcon(String type) {
    switch (type.toLowerCase()) {
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for place',
                  ),
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
                onTap: () {},
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
                    final url = Uri.parse('http://10.0.2.2:8000/api/v1/logout');
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
          // Category filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(categories.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(categories[index]),
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
          // Real OpenStreetMap with marker adding
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
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
                      markers: _markers.map((marker) => Marker(
                        point: marker.position,
                        width: 40,
                        height: 40,
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
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Start/Stop Visit button
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 32.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B3AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _visitStarted ? _stopVisit : _startVisit,
                child: Text(
                  _visitStarted ? 'Stop Visit' : 'Start Visit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
          // Working hours count up
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Working Hours: ${_formatDuration(_elapsed)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
