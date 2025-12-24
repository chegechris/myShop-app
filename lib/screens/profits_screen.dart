import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_provider.dart';

class ProfitsScreen extends StatefulWidget {
  @override
  _ProfitsScreenState createState() => _ProfitsScreenState();
}

class _ProfitsScreenState extends State<ProfitsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sales = [];
  double _totalRevenue = 0;
  double _totalProfit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // We join txn with inventory to get the buying price (originalPrice)
    // t.totalAmount = Selling Price (after discount)
    // i.originalPrice = Buying Cost
    final sql = '''
      SELECT t.id, t.totalAmount, t.timestamp, t.details,
             i.name as itemName, i.originalPrice
      FROM txn t
      LEFT JOIN inventory i ON t.itemId = i.id
      WHERE t.type = 'sale'
      ORDER BY t.timestamp DESC
    ''';

    final data = await DbProvider.queryRaw(sql);

    double rev = 0;
    double prof = 0;

    for (var row in data) {
      double sell = (row['totalAmount'] as num).toDouble();
      // If item was deleted, cost defaults to 0 to avoid crash, but profit = sell price
      double cost = (row['originalPrice'] as num?)?.toDouble() ?? 0.0;
      
      rev += sell;
      prof += (sell - cost);
    }

    if (mounted) {
      setState(() {
        _sales = data;
        _totalRevenue = rev;
        _totalProfit = prof;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profits Analysis')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SUMMARY CARD
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Total Revenue', 
                          'KSH ${_format(_totalRevenue)}', 
                          Colors.blue
                        )
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildSummaryItem(
                          'Net Profit', 
                          'KSH ${_format(_totalProfit)}', 
                          _totalProfit >= 0 ? Colors.green : Colors.red
                        )
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),

                // TRANSACTION LIST
                Expanded(
                  child: _sales.isEmpty 
                  ? Center(child: Text("No sales records found", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                    itemCount: _sales.length,
                    separatorBuilder: (c, i) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _sales[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                      final sell = (item['totalAmount'] as num).toDouble();
                      final cost = (item['originalPrice'] as num?)?.toDouble() ?? 0.0;
                      final profit = sell - cost;
                      final name = item['itemName'] ?? 'Deleted Item';
                      final details = item['details'] ?? '';

                      return ListTile(
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM d, h:mm a').format(date), style: TextStyle(fontSize: 12, color: Colors.grey)),
                            // Show details if they contain discount info
                            if (details.isNotEmpty && details != 'Sale: $name') 
                              Text(details, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Profit: KSH ${_format(profit)}', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: profit >= 0 ? Colors.green : Colors.red,
                                fontSize: 15
                              )
                            ),
                            Text('Sold: KSH ${_format(sell)}', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
      ],
    );
  }

  String _format(double val) {
    if (val % 1 == 0) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }
}