import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'core/services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final String pharmacyName;
  final int? visitId; // Visit ID for backend integration
  final int? locationId; // Location ID for creating visit if needed
  const ReportScreen({
    Key? key,
    required this.pharmacyName,
    this.visitId,
    this.locationId,
  }) : super(key: key);

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

    // If no visitId, we need to create a visit first or show error
    if (widget.visitId == null) {
      setState(() {
        _message = 'No visit associated. Please start a visit first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final apiService = ApiService();
      
      // Submit report to backend
      final body = {
        'visit_outcome': 'successful', // Default, can be made selectable
        'summary': text,
        'follow_up_required': false,
      };

      final response = await apiService.post(
        '/visits/${widget.visitId}/reports',
        body: body,
      );

      final data = apiService.parseResponse(response);

      if (data['success'] == true) {
        setState(() {
          _isLoading = false;
          _message = 'Report sent to your Sales Manager!';
          _controller.clear();
        });
      } else {
        setState(() {
          _isLoading = false;
          _message = data['message'] ?? 'Failed to send report.';
        });
      }
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