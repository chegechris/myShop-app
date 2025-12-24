import 'package:flutter/material.dart';
import 'dart:io'; 
import '../services/backup_service.dart';
import '../db/db_provider.dart'; // Import DB to query stats

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  int customerCount = 0;
  int txnCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final customers = await DbProvider.query('customer');
    final txns = await DbProvider.query('txn');
    if (mounted) {
      setState(() {
        customerCount = customers.length;
        txnCount = txns.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data & Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Current Data'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Customers', '$customerCount'),
                  _buildStatItem('Transactions', '$txnCount'),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          _buildSectionHeader('Backup & Restore'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50, 
                    child: Icon(Icons.share, color: Colors.blue)
                  ),
                  title: Text('Export Data'),
                  subtitle: Text('Send data to another phone'),
                  onTap: () => BackupService.exportDatabase(context),
                ),
                Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50, 
                    child: Icon(Icons.download, color: Colors.orange)
                  ),
                  title: Text('Import Data'),
                  subtitle: Text('Load data from a backup file'),
                  onTap: () async {
                    // No need to handle result here, BackupService handles the exit
                    await BackupService.importDatabase(context);
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          _buildSectionHeader('About'),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App Version'),
              subtitle: Text('1.0.0 (Offline Mode)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey[700]
        ),
      ),
    );
  }
}