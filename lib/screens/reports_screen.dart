import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_provider.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, _ReportData> _weeklyData = {};
  Map<String, _ReportData> _monthlyData = {};
  Map<String, _ReportData> _yearlyData = {};
  List<Map<String, dynamic>> _itemSalesData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbProvider.query('txn', orderBy: 'timestamp DESC');
    
    final weekly = <String, _ReportData>{};
    final monthly = <String, _ReportData>{};
    final yearly = <String, _ReportData>{};

    for (var item in data) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
      final amount = (item['totalAmount'] as num).toInt();
      final type = item['type'].toString().toLowerCase();
      
      // LOGIC UPDATE:
      // Income = 'sale' (from inventory)
      // Expense = 'restock' (from restock page)
      // Ignore 'incoming' and 'outgoing' manual logs for business reports
      
      bool isRelevant = false;
      bool isIncome = false;

      if (type == 'sale') {
        isRelevant = true;
        isIncome = true;
      } else if (type == 'restock') {
        isRelevant = true;
        isIncome = false;
      }

      if (!isRelevant) continue;

      final monday = date.subtract(Duration(days: date.weekday - 1));
      final sunday = monday.add(Duration(days: 6));
      final weekKey = '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
      final monthKey = DateFormat('MMM yyyy').format(date);
      final yearKey = date.year.toString();

      _addToMap(weekly, weekKey, amount, isIncome);
      _addToMap(monthly, monthKey, amount, isIncome);
      _addToMap(yearly, yearKey, amount, isIncome);
    }

    // Items Report (Unchanged)
    final itemSql = '''
      SELECT 
        i.name, i.category, 
        COUNT(t.id) as qty, 
        SUM(t.totalAmount) as revenue,
        i.originalPrice
      FROM txn t
      LEFT JOIN inventory i ON t.itemId = i.id
      WHERE t.type = 'sale'
      GROUP BY i.id
      ORDER BY qty DESC
    ''';
    
    final rawItemData = await DbProvider.queryRaw(itemSql);
    final List<Map<String, dynamic>> processedItems = rawItemData.map((row) {
      final qty = (row['qty'] as num).toInt();
      final revenue = (row['revenue'] as num).toDouble();
      final cost = (row['originalPrice'] as num?)?.toDouble() ?? 0.0;
      final profit = revenue - (cost * qty);
      return {
        'name': row['name'] ?? 'Deleted Item',
        'category': row['category'] ?? 'General',
        'qty': qty,
        'revenue': revenue,
        'profit': profit,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _weeklyData = weekly;
        _monthlyData = monthly;
        _yearlyData = yearly;
        _itemSalesData = processedItems;
        _isLoading = false;
      });
    }
  }

  void _addToMap(Map<String, _ReportData> map, String key, int amount, bool isIncome) {
    if (!map.containsKey(key)) map[key] = _ReportData(label: key);
    if (isIncome) map[key]!.income += amount;
    else map[key]!.expense += amount;
    map[key]!.count++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Reports'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [Tab(text: 'Weekly'), Tab(text: 'Monthly'), Tab(text: 'Yearly'), Tab(text: 'Items Sold')],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportList(_weeklyData),
                _buildReportList(_monthlyData),
                _buildReportList(_yearlyData),
                _buildItemsReportList(),
              ],
            ),
    );
  }

  Widget _buildReportList(Map<String, _ReportData> data) {
    if (data.isEmpty) return _buildEmptyState();
    final keys = data.keys.toList(); 
    return ListView.builder(
      itemCount: keys.length,
      padding: EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final item = data[keys[i]]!;
        final net = item.income - item.expense;
        return Card(
          elevation: 3,
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Divider(),
                Row(
                  children: [
                    Expanded(child: _buildStat('Sales (Income)', item.income.toDouble(), Colors.green)),
                    Expanded(child: _buildStat('Restock (Exp)', item.expense.toDouble(), Colors.red)),
                    Expanded(child: _buildStat('Net Profit', net.toDouble(), net >= 0 ? Colors.blue : Colors.deepOrange)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsReportList() {
    if (_itemSalesData.isEmpty) return _buildEmptyState();
    return ListView.builder(
      itemCount: _itemSalesData.length,
      padding: EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final item = _itemSalesData[i];
        final profit = item['profit'] as double;
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['category']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item['qty']} Sold', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Profit: KSH ${_format(profit)}', style: TextStyle(fontSize: 11, color: profit >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(child: Text("No relevant data", style: TextStyle(color: Colors.grey)));

  Widget _buildStat(String label, double value, Color color) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
      Text('KSH ${_format(value)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
    ]);
  }

  String _format(double val) => val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
}

class _ReportData {
  String label;
  int income = 0;
  int expense = 0;
  int count = 0;
  _ReportData({required this.label});
}