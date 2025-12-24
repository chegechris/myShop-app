import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../db/db_provider.dart';
import 'new_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  final String? initialQuery;
  
  const CustomersScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchQuery = widget.initialQuery!;
    }
    _refreshCustomers();
  }

  Future<void> _refreshCustomers() async {
    setState(() => _isLoading = true);
    // Get raw data from DB
    final rawData = await DbProvider.query('customer');
    
    // CRITICAL FIX: Create a modifiable copy of the list before sorting
    final data = List<Map<String, dynamic>>.from(rawData);
    
    // Sort logic: A-Z
    data.sort((a, b) {
      String nameA = (a['name'] != null && a['name'].toString().isNotEmpty) ? a['name'] : (a['store'] ?? '');
      String nameB = (b['name'] != null && b['name'].toString().isNotEmpty) ? b['name'] : (b['store'] ?? '');
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    setState(() {
      _customers = data;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEdit(Map<String, dynamic> customer) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => NewCustomerScreen(customer: customer))
    );
    _refreshCustomers();
  }

  void _copyToClipboard(String? phone, String? idNo) {
    String text = '';
    if (phone != null && phone.isNotEmpty) text += 'Phone: $phone ';
    if (idNo != null && idNo.isNotEmpty) text += 'ID: $idNo';
    
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: $text')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final store = (c['store'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query) || store.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Customers (${filtered.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController(text: _searchQuery),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, phone or store',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(child: Text('No customers found', style: TextStyle(color: Colors.grey)))
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        
                        // Logic: Use Store if Name is missing
                        String displayName = item['name'];
                        String secondaryInfo = item['phone'] ?? '';
                        if (displayName.isEmpty || displayName == 'Unknown') {
                          displayName = item['store'] ?? 'No Name';
                          secondaryInfo = 'Store Account';
                        }

                        return GestureDetector(
                          onDoubleTap: () => _copyToClipboard(item['phone'], item['id_no']),
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                              ),
                              title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(secondaryInfo),
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16),
                                  width: double.infinity,
                                  color: Colors.grey.shade50,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item['id_no'] != null && item['id_no'].toString().isNotEmpty)
                                        _buildDetailRow(Icons.badge, 'ID Number', item['id_no']),
                                      
                                      if (item['store'] != null && item['store'].toString().isNotEmpty)
                                        _buildDetailRow(Icons.store, 'Store', item['store']),
                                      
                                      if (item['agent'] != null && item['agent'].toString().isNotEmpty)
                                        _buildDetailRow(Icons.person, 'Agent', item['agent']),
                                        
                                      if (item['bank_account'] != null && item['bank_account'].toString().isNotEmpty)
                                        _buildDetailRow(Icons.account_balance, 'Bank', item['bank_account']),

                                      if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                        _buildDetailRow(Icons.note, 'Notes', item['notes']),
                                      
                                      Divider(),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          icon: Icon(Icons.edit, size: 18),
                                          label: Text("Edit / Delete"),
                                          onPressed: () => _navigateToEdit(item),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.person_add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => NewCustomerScreen()));
          _refreshCustomers();
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}