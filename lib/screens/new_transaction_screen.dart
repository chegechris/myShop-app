import 'package:flutter/material.dart';
import '../db/db_provider.dart';

class NewTransactionScreen extends StatefulWidget {
  @override
  _NewTransactionScreenState createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String txnType = 'Incoming'; 
  final _formKey = GlobalKey<FormState>(); 

  // FIXED: Added dispose
  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(_amountController.text.replaceAll(',', '').trim()); // Handle commas if user types them

    await DbProvider.insert('txn', {
      'type': txnType,
      'totalAmount': amount,
      'details': _detailsController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction Saved!')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor = txnType == 'Incoming' ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Transaction'),
        backgroundColor: typeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form( 
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: txnType,
                      isExpanded: true,
                      icon: Icon(Icons.swap_vert, color: typeColor),
                      style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                      items: [
                        DropdownMenuItem(value: 'Incoming', child: Text('Incoming (Deposit/Sales)')),
                        DropdownMenuItem(value: 'Outgoing', child: Text('Outgoing (Withdraw/Expense)')),
                      ],
                      onChanged: (v) => setState(() => txnType = v!),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: typeColor),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KSH ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (int.tryParse(value.replaceAll(',', '')) == null) return 'Invalid number';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Details Input Box
              TextFormField(
                controller: _detailsController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Details (Optional)',
                  hintText: 'e.g. Sold Airtime',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),

              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 55),
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _save,
                child: Text('SAVE TRANSACTION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}