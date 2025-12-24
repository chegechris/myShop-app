import 'package:flutter/material.dart';

class CashCountScreen extends StatefulWidget {
  @override
  _CashCountScreenState createState() => _CashCountScreenState();
}

class _CashCountScreenState extends State<CashCountScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final denominations = ['1000','500','200','100','50','40','20','10','5','1'];
  int total = 0;

  @override
  void initState() {
    super.initState();
    for (final d in denominations) {
      _controllers[d] = TextEditingController(text: '');
      _controllers[d]!.addListener(_recompute);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recompute() {
    int t = 0;
    for (final d in denominations) {
      final qty = int.tryParse(_controllers[d]!.text) ?? 0;
      t += qty * int.parse(d);
    }
    setState(() => total = t);
  }

  void _clear() {
    for (final d in denominations) _controllers[d]!.clear();
    setState(() => total = 0);
  }

  void _adjust(String denom, int amount) {
    int current = int.tryParse(_controllers[denom]!.text) ?? 0;
    int newVal = current + amount;
    if (newVal < 0) newVal = 0;
    _controllers[denom]!.text = newVal.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cash Counter'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _clear)],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Cash:', style: TextStyle(fontSize: 20)),
                Text('KSH $total', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: denominations.map((denom) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      SizedBox(width: 60, child: Text('KSH $denom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      
                      IconButton(onPressed: () => _adjust(denom, -1), icon: Icon(Icons.remove_circle_outline, color: Colors.red)),
                      
                      Expanded(
                        child: TextField(
                          controller: _controllers[denom],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '0',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      
                      IconButton(onPressed: () => _adjust(denom, 1), icon: Icon(Icons.add_circle_outline, color: Colors.green)),
                      
                      // FIXED: Used Container instead of SizedBox for alignment
                      Container(
                        width: 80, 
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(int.tryParse(_controllers[denom]!.text) ?? 0) * int.parse(denom)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}