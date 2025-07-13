import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportScreen extends StatefulWidget {
  final String pharmacyName;
  // Optionally, you can add visitId here for real backend integration
  const ReportScreen({Key? key, required this.pharmacyName}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendReport() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _message = 'Please write a report.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _message = 'Authentication required.';
        });
        return;
      }
      // TODO: Replace with actual visitId and endpoint
      // For now, just simulate a successful send
      // final url = Uri.parse('http://10.0.2.2:8000/api/v1/visits/{visitId}/reports');
      // final response = await http.post(
      //   url,
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({'notes': text}),
      // );
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = false;
        _message = 'Report sent to your Sales Manager!';
        _controller.clear();
      });
      // if (response.statusCode == 201) {
      //   setState(() {
      //     _isLoading = false;
      //     _message = 'Report sent to your Sales Manager!';
      //     _controller.clear();
      //   });
      // } else {
      //   setState(() {
      //     _isLoading = false;
      //     _message = 'Failed to send report.';
      //   });
      // }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pharmacy: ${widget.pharmacyName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Write your report here...',
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: _message!.contains('sent') ? Colors.green : Colors.red),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 