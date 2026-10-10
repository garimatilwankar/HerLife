import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:herlife/core/config/app_config.dart';
import 'package:herlife/screens/tabs/ui.dart' show kWine;

/// Diagnostic modal dialog allowing developers/testers to inspect, test,
/// and update the API base URL on physical devices without recompiling.
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _testing = false;
  String? _testStatus;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testStatus = 'Please enter a server URL.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _testing = true;
      _testStatus = null;
    });

    try {
      var clean = url;
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final response = await dio.get('$clean/health');
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _testing = false;
          _testSuccess = true;
          _testStatus = 'Connected successfully! (Server: healthy)';
        });
      } else {
        setState(() {
          _testing = false;
          _testSuccess = false;
          _testStatus = 'Server responded with status: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = false;
        _testStatus = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _save() async {
    final newUrl = _controller.text.trim();
    await AppConfig.setBaseUrl(newUrl);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Server URL updated to: ${AppConfig.baseUrl}')),
    );
  }

  Future<void> _reset() async {
    await AppConfig.setBaseUrl('');
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Server URL reset to: ${AppConfig.baseUrl}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_outlined, color: kWine),
          SizedBox(width: 8),
          Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current source: ${AppConfig.baseUrlSource}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'e.g. http://192.168.31.170:8000',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            if (_testStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _testStatus!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testSuccess ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.network_check, size: 18),
                label: const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: const Text('Reset', style: TextStyle(color: Colors.black54)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kWine),
          onPressed: _save,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
