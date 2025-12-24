import 'package:flutter/material.dart';
import '../db/db_provider.dart';

class RestockScreen extends StatefulWidget {
  @override
  _RestockScreenState createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final _amountCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  Future<void> _save() async {
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    await DbProvider.insert('txn', {
      'type': 'restock', // Special type for reports
      'totalAmount': amount,
      'details': 'Restock: ${_detailsCtrl.text}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restock Recorded')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restock Supplies')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Spent',
                prefixText: 'KSH ',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _detailsCtrl,
              decoration: InputDecoration(
                labelText: 'Details (e.g. Cables, Airtime)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _save,
              child: Text('SAVE EXPENSE'),
            )
          ],
        ),
      ),
    );
  }
}