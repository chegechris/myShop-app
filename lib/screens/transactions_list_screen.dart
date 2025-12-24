import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_provider.dart';

class TransactionsListScreen extends StatefulWidget {
  @override
  _TransactionsListScreenState createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTxns();
  }

  Future<void> _loadTxns() async {
    final sql = '''
      SELECT txn.*, inventory.name as itemName 
      FROM txn 
      LEFT JOIN inventory ON txn.itemId = inventory.id 
      ORDER BY timestamp DESC
    ''';
    
    final data = await DbProvider.queryRaw(sql);
    
    setState(() {
      _txns = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteTxn(int id) async {
    await DbProvider.delete('txn', 'id = ?', [id]);
    _loadTxns();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _txns.isEmpty
              ? Center(child: Text('No transactions recorded yet'))
              : ListView.builder(
              itemCount: _txns.length,
              itemBuilder: (context, index) {
                final item = _txns[index];
                final date = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                final rawType = item['type'].toString();
                
                // 1. Determine Title (Item Name or Type)
                String title;
                if (rawType == 'sale' && item['itemName'] != null) {
                  title = 'Sold: ${item['itemName']}';
                } else {
                  title = rawType.toUpperCase(); // INCOMING / OUTGOING
                }

                // 2. Get Details (New Feature)
                String details = item['details'] ?? '';

                // 3. Determine Color (Green for Money In, Red for Money Out)
                // "Incoming" or "Sale" or old "cash_in" = Green
                final isIncome = rawType == 'Incoming' || rawType == 'sale' || rawType.contains('cash_in');

                return Dismissible(
                  key: Key(item['id'].toString()),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 20), child: Icon(Icons.delete, color: Colors.white)),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("Confirm Delete"),
                        content: Text("Delete this record permanently?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("CANCEL")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("DELETE", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteTxn(item['id']),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                      // UPDATED SUBTITLE: Shows Details + Date
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (details.isNotEmpty) 
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                              child: Text(
                                details, 
                                style: TextStyle(color: Colors.black87, fontStyle: FontStyle.italic)
                              ),
                            ),
                          Text(DateFormat('MMM d, h:mm a').format(date), style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Text(
                        'KSH ${item['totalAmount']}',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}