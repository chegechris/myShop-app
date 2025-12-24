import 'package:flutter/material.dart';
import '../db/db_provider.dart';
import 'accounting_history_screen.dart'; // Import History Screen

class AccountingScreen extends StatefulWidget {
  @override
  _AccountingScreenState createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final _cashCtrl = TextEditingController();
  final _mpesa1Ctrl = TextEditingController();
  final _mpesa2Ctrl = TextEditingController();
  final _coopCtrl = TextEditingController();
  final _equityCtrl = TextEditingController();
  final _kcbCtrl = TextEditingController();
  final _airtelCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Map<String, dynamic>? _lastEntry;
  int _inventorySalesSinceLast = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await DbProvider.query('accounting', orderBy: 'timestamp DESC', limit: 1);
    final last = entries.isNotEmpty ? entries.first : null;

    int lastTime = last != null ? (last['timestamp'] as int) : 0;
    
    final sales = await DbProvider.queryRaw('''
      SELECT SUM(totalAmount) as total 
      FROM txn 
      WHERE type = 'sale' AND timestamp > ?
    ''', [lastTime]);
    
    int newSales = (sales.first['total'] as int?) ?? 0;

    setState(() {
      _lastEntry = last;
      _inventorySalesSinceLast = newSales;
      _isLoading = false;
    });
  }

  // Helper to parse expressions like "5000 + 200"
  int getVal(TextEditingController c) {
    if (c.text.isEmpty) return 0;
    
    // Remove commas
    String text = c.text.replaceAll(',', '');
    
    // Split by '+' to handle addition
    List<String> parts = text.split('+');
    
    int sum = 0;
    for (String part in parts) {
      sum += int.tryParse(part.trim()) ?? 0;
    }
    return sum;
  }

  Future<void> _saveEntry() async {
    // Calculate total using the new getVal that supports addition
    int currentSum = getVal(_cashCtrl) + getVal(_mpesa1Ctrl) + getVal(_mpesa2Ctrl) + 
                     getVal(_coopCtrl) + getVal(_equityCtrl) + getVal(_kcbCtrl) + 
                     getVal(_airtelCtrl) + getVal(_otherCtrl);

    int lastSum = 0;
    if (_lastEntry != null) {
      lastSum = (_lastEntry!['cashTotal'] as int? ?? 0) + 
                (_lastEntry!['mpesa1'] as int? ?? 0) + 
                (_lastEntry!['mpesa2'] as int? ?? 0) + 
                (_lastEntry!['coop'] as int? ?? 0) + 
                (_lastEntry!['equity'] as int? ?? 0) + 
                (_lastEntry!['kcb'] as int? ?? 0) + 
                (_lastEntry!['airtel'] as int? ?? 0) + 
                (_lastEntry!['otherMpesa'] as int? ?? 0);
    }

    int expected = lastSum + _inventorySalesSinceLast;
    int disparity = currentSum - expected;

    await DbProvider.insert('accounting', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'cashTotal': getVal(_cashCtrl),
      'mpesa1': getVal(_mpesa1Ctrl),
      'mpesa2': getVal(_mpesa2Ctrl),
      'coop': getVal(_coopCtrl),
      'equity': getVal(_equityCtrl),
      'kcb': getVal(_kcbCtrl),
      'airtel': getVal(_airtelCtrl),
      'otherMpesa': getVal(_otherCtrl),
      'salesDisparity': disparity,
      'specialScenarios': _notesCtrl.text,
    });

    if (mounted) {
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: Text('Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Previous Total: KSH $lastSum'),
              Text('New Sales Added: + KSH $_inventorySalesSinceLast'),
              Divider(),
              Text('Expected Total: KSH $expected', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your Count: KSH $currentSum', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 10),
              Text(
                'Disparity: KSH ${disparity > 0 ? "+$disparity" : disparity}', 
                style: TextStyle(
                  color: disparity == 0 ? Colors.green : Colors.red, 
                  fontWeight: FontWeight.bold, fontSize: 18
                )
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () { 
              Navigator.pop(ctx); 
              _loadData();
              _cashCtrl.clear();
              _mpesa1Ctrl.clear();
              _mpesa2Ctrl.clear();
              _coopCtrl.clear();
              _equityCtrl.clear();
              _kcbCtrl.clear();
              _airtelCtrl.clear();
              _otherCtrl.clear();
              _notesCtrl.clear();
            }, child: Text('OK'))
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accounting'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountingHistoryScreen())),
          )
        ],
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountingHistoryScreen())),
                icon: Icon(Icons.history),
                label: Text("View Past Records"),
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              ),
            ),
            _buildInput("Cash Total", _cashCtrl),
            _buildInput("Mpesa Line 1", _mpesa1Ctrl),
            _buildInput("Mpesa Line 2", _mpesa2Ctrl),
            _buildInput("CO-OP Account", _coopCtrl),
            _buildInput("Equity Account", _equityCtrl),
            _buildInput("KCB Account", _kcbCtrl),
            _buildInput("Airtel Money", _airtelCtrl),
            _buildInput("Other Mpesa Line", _otherCtrl),
            SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: "Special Scenarios (e.g. Lent money)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white
              ),
              onPressed: _saveEntry,
              child: Text("CALCULATE & SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone, // Phone usually has +, but button is backup
        decoration: InputDecoration(
          labelText: label,
          hintText: "e.g. 5000 + 1050",
          border: OutlineInputBorder(),
          prefixText: 'KSH ',
          // NEW: Plus button inside the field
          suffixIcon: IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add amount',
            onPressed: () {
              final text = ctrl.text;
              ctrl.text = text + "+";
              // Move cursor to the end
              ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
            },
          ),
        ),
      ),
    );
  }
}