import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_provider.dart';

class AccountingHistoryScreen extends StatefulWidget {
  @override
  _AccountingHistoryScreenState createState() => _AccountingHistoryScreenState();
}

class _AccountingHistoryScreenState extends State<AccountingHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DbProvider.query('accounting', orderBy: 'timestamp DESC');
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accounting History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Text("No records found"))
              : ListView.separated(
                  itemCount: _history.length,
                  padding: EdgeInsets.all(12),
                  separatorBuilder: (c, i) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                    final disparity = item['salesDisparity'] as int? ?? 0;
                    
                    // Calculate Total Counted
                    final total = (item['cashTotal'] as int? ?? 0) +
                        (item['mpesa1'] as int? ?? 0) +
                        (item['mpesa2'] as int? ?? 0) +
                        (item['coop'] as int? ?? 0) +
                        (item['equity'] as int? ?? 0) + // Include Equity
                        (item['kcb'] as int? ?? 0) +
                        (item['airtel'] as int? ?? 0) +
                        (item['otherMpesa'] as int? ?? 0);

                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          DateFormat('MMM d, yyyy  h:mm a').format(date),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text('Counted: KSH $total'),
                        trailing: Text(
                          disparity == 0 
                            ? 'Balanced' 
                            : (disparity > 0 ? '+${_format(disparity)}' : '${_format(disparity)}'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: disparity == 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            color: Colors.grey.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row('Cash', item['cashTotal']),
                                _row('Mpesa 1', item['mpesa1']),
                                _row('Mpesa 2', item['mpesa2']),
                                _row('Co-op', item['coop']),
                                _row('Equity', item['equity']),
                                _row('KCB', item['kcb']),
                                _row('Airtel', item['airtel']),
                                _row('Other Mpesa', item['otherMpesa']),
                                Divider(),
                                Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(item['specialScenarios'] ?? 'None'),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _row(String label, dynamic value) {
    int val = value as int? ?? 0;
    if (val == 0) return SizedBox.shrink(); // Hide 0 entries
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text('KSH ${_format(val)}', style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _format(int val) => val.toString();
}