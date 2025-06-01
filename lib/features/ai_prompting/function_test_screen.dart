import 'package:flutter/material.dart';
import 'function_executor.dart';
import 'package:flutter/services.dart';
import 'AI_functions.dart';

/// A screen to test function execution directly without going through the AI chat flow
class FunctionTestScreen extends StatefulWidget {
  const FunctionTestScreen({Key? key}) : super(key: key);

  @override
  State<FunctionTestScreen> createState() => _FunctionTestScreenState();
}

class _FunctionTestScreenState extends State<FunctionTestScreen> {
  final TextEditingController _functionJsonController = TextEditingController();
  String _result = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Set a default function call for testing
    _functionJsonController.text = '''
{
  "name": "get_all_todo_items",
  "parameters": {
    "filter": "all"
  }
}
''';
  }

  Future<void> _executeFunction() async {
    final functionJson = _functionJsonController.text.trim();
    if (functionJson.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter valid function JSON';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _result = '';
    });

    try {
      debugPrint('TEST SCREEN: Executing function with JSON:\n$functionJson');

      final result = await FunctionExecutor.executeFunction(functionJson);

      setState(() {
        _result = result;
        _isLoading = false;
      });

      debugPrint(
        'TEST SCREEN: Function executed successfully with result length: ${result.length}',
      );
    } catch (e) {
      debugPrint('TEST SCREEN: Error executing function: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _directTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _result = '';
    });

    try {
      debugPrint('TEST SCREEN: Direct AIFunctions.get_all_todo_items test');

      final result = await AIFunctions.get_all_todo_items(filter: 'all');

      setState(() {
        _result = result;
        _isLoading = false;
      });

      debugPrint(
        'TEST SCREEN: Direct function call successful with result length: ${result.length}',
      );
    } catch (e, stack) {
      debugPrint('TEST SCREEN: Error in direct function call: $e\n$stack');
      setState(() {
        _errorMessage = 'Direct Test Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Function Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Function JSON:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _functionJsonController,
                maxLines: 8,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _executeFunction,
                  child: const Text('Execute Function'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _directTest,
                  child: const Text('Direct Function Test'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            Clipboard.setData(ClipboardData(text: _result));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Result copied to clipboard'),
                              ),
                            );
                          },
                  child: const Text('Copy Result'),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(child: Text(_result)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
