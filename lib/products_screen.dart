import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/auth_service.dart';

class ProductsScreen extends StatefulWidget {
  final int placeId;
  final String placeName;
  const ProductsScreen({Key? key, required this.placeId, required this.placeName}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication required';
        });
        return;
      }

      final url = Uri.parse('http://10.0.2.2:8000/api/v1/products');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['data']['products'] as List<dynamic>;
        
        setState(() {
          _products = products.map((product) => Map<String, dynamic>.from(product)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load products: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _addOrder(int productId, String productName) async {
    int quantity = 1;
    final quantityController = TextEditingController(text: '1');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order $productName'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final q = int.tryParse(quantityController.text);
              if (q != null && q > 0) {
                Navigator.pop(context, q);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == null) return;
    quantity = result;
    // Send order to backend
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication required.')));
        return;
      }
      final url = Uri.parse('http://10.0.2.2:8000/api/v1/orders');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'place_id': widget.placeId,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order added!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add order: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getAvailabilityColor(String availability) {
    switch (availability) {
      case 'available':
        return '🟢 Available';
      case 'limited':
        return '🟡 Limited';
      case 'out_of_stock':
        return '🔴 Out of Stock';
      default:
        return '⚪ Unknown';
    }
  }

  Color _getAvailabilityColorCode(String availability) {
    switch (availability) {
      case 'available':
        return Colors.green;
      case 'limited':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Products at ${widget.placeName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: product['image_url'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              product['image_url'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.medical_services, size: 40, color: Colors.grey),
                                            ),
                                          )
                                        : const Icon(Icons.medical_services, size: 40, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? 'Unknown Product',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (product['description'] != null)
                                          Text(
                                            product['description'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (product['price'] != null)
                                              Text(
                                                '\$${double.tryParse(product['price'].toString())?.toStringAsFixed(2) ?? product['price']}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getAvailabilityColorCode(product['availability'] ?? 'unknown').withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getAvailabilityColorCode(product['availability'] ?? 'unknown'),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getAvailabilityColor(product['availability'] ?? 'unknown'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getAvailabilityColorCode(product['availability'] ?? 'unknown'),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (product['sku'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: ${product['sku']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.add_shopping_cart),
                                            label: const Text('Add to Orders'),
                                            onPressed: () => _addOrder(product['id'], product['name'] ?? ''),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 