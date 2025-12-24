import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../customer_import.dart';

class ImportScreen extends StatefulWidget {
  @override
  _ImportScreenState createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  List<String> _logs = [];

  Future<void> _pickAndImport() async {
    setState(() {
      _isImporting = true;
      _logs = [];
    });

    try {
      // Pick the file from phone storage
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Pass it to the cleaner/importer
        final errors = await importCustomersFromCsvFile(file);

        setState(() {
          _isImporting = false;
          if (errors.isEmpty) {
            _logs = ['Success! Customers imported successfully.'];
          } else {
            _logs = errors;
          }
        });
      } else {
        setState(() => _isImporting = false);
      }
    } catch (e) {
      setState(() {
        _logs = ['Error selecting file: $e'];
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Customers')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.upload_file, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Select "customer_details_full.csv" from your phone storage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isImporting ? null : _pickAndImport,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
              ),
              child: Text(_isImporting ? 'Importing...' : 'SELECT CSV FILE'),
            ),
            SizedBox(height: 20),
            Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) => Text(
                    _logs[i],
                    style: TextStyle(color: _logs[i].contains('Success') ? Colors.green : Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}