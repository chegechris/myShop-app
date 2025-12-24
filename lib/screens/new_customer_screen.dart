import 'package:flutter/material.dart';
import '../db/db_provider.dart';

class NewCustomerScreen extends StatefulWidget {
  final Map<String, dynamic>? customer; // If null, we are adding new. If set, we are editing.

  const NewCustomerScreen({super.key, this.customer});

  @override
  _NewCustomerScreenState createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill the fields
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!['name'];
      _phoneCtrl.text = widget.customer!['phone'] ?? '';
      _idCtrl.text = widget.customer!['id_no'] ?? '';
      _storeCtrl.text = widget.customer!['store'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _storeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'id_no': _idCtrl.text.trim(),
        'store': _storeCtrl.text.trim(),
        'createdAt': widget.customer?['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.customer == null) {
        // INSERT NEW
        await DbProvider.insert('customer', data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer Added')));
      } else {
        // UPDATE EXISTING
        await DbProvider.update('customer', data, 'id = ?', [widget.customer!['id']]);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer Updated')));
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    if (widget.customer == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Customer?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbProvider.delete('customer', 'id = ?', [widget.customer!['id']]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer Deleted')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'New Customer'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _delete,
              tooltip: 'Delete Customer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            _buildTextField(_nameCtrl, 'Full Name', Icons.person, validator: (v) => v!.isEmpty ? 'Name is required' : null),
            SizedBox(height: 16),
            _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone, inputType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Phone is required' : null),
            SizedBox(height: 16),
            _buildTextField(_idCtrl, 'ID Number', Icons.badge, inputType: TextInputType.number),
            SizedBox(height: 16),
            _buildTextField(_storeCtrl, 'Store Name', Icons.store),
            SizedBox(height: 32),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save, 
              child: Text(isEditing ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: inputType,
      validator: validator,
      textCapitalization: TextCapitalization.words,
    );
  }
}