import 'package:flutter/material.dart';
import '../db/db_provider.dart';
import 'new_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'cash_count_screen.dart';
import 'inventory_screen.dart';
import 'import_screen.dart';
import 'settings_screen.dart';
import 'profits_screen.dart';
import 'reports_screen.dart';
import 'customers_screen.dart';
import 'accounting_screen.dart'; // NEW
import 'restock_screen.dart'; // NEW

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int todaysItemsSold = 0;
  int todaysSalesTotal = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _refresh() => _loadSummary();

  Future<void> _loadSummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    
    // Fetch only SALES transactions for today
    final rows = await DbProvider.query(
      'txn', 
      where: 'timestamp >= ? AND type = ?', 
      whereArgs: [startOfDay, 'sale']
    );
    
    int count = rows.length; // Count of sale transactions (approx items sold if 1 txn = 1 item)
    int total = 0;
    
    for (final r in rows) {
      total += (r['totalAmount'] as int? ?? 0);
    }
    
    if (mounted) {
      setState(() {
        todaysItemsSold = count;
        todaysSalesTotal = total;
      });
    }
  }

  void _searchCustomer(String query) {
    if (query.isEmpty) return;
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => CustomersScreen(initialQuery: query))
    ).then((_) => _searchCtrl.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('myShop', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Shop Admin"),
              accountEmail: Text("Manager Mode"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, size: 40, color: Colors.green),
              ),
              decoration: BoxDecoration(color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Customers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/customers').then((_) => _refresh());
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Data & Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BAR
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Customer by Name...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => _searchCustomer(_searchCtrl.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _searchCustomer,
            ),
            SizedBox(height: 20),

            Text('Today\'s Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildStatCard('Items Sold', '$todaysItemsSold', Colors.blue, Icons.shopping_bag)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Total Sales', 'KSH $todaysSalesTotal', Colors.green, Icons.attach_money)),
              ],
            ),
            
            SizedBox(height: 32),
            Text('Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(
                  'Inventory', Icons.inventory_2, Colors.teal, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen())).then((_) => _refresh())
                ),
                _buildActionCard(
                  'Accounting', Icons.account_balance_wallet, Colors.indigo, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountingScreen()))
                ),
                _buildActionCard(
                  'Restock', Icons.local_shipping, Colors.orange, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestockScreen())).then((_) => _refresh())
                ),
                _buildActionCard(
                  'New Transaction', Icons.add_circle, Colors.green, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewTransactionScreen()))
                ),
                _buildActionCard(
                  'Profits', Icons.trending_up, Colors.purple, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfitsScreen()))
                ),
                _buildActionCard(
                  'Reports', Icons.bar_chart, Colors.brown, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()))
                ),
                _buildActionCard(
                  'Cash Count', Icons.calculate, Colors.blue, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => CashCountScreen()))
                ),
                _buildActionCard(
                  'History', Icons.history, Colors.blueGrey, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsListScreen()))
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, MaterialColor color, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 150, 
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            Spacer(),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800)),
            Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}