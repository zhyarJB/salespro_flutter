import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    categories = ['Pharmacy', 'Doctor', 'Drugstore', 'Other'];
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _markers.add(PlaceMarker(position: latlng, name: name, type: type));
                  });
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

  Icon _getMarkerIcon(String type) {
    switch (type) {
      case 'Pharmacy':
        return const Icon(Icons.location_on, color: Colors.purple, size: 36);
      case 'Doctor':
        return const Icon(Icons.location_on, color: Colors.blue, size: 36);
      case 'Drugstore':
        return const Icon(Icons.location_on, color: Colors.orange, size: 36);
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
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
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
                          children: [
                            _getMarkerIcon(marker.type),
                            Container(
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
                              child: Text(
                                marker.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
