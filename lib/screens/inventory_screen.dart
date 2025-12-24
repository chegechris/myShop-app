import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../db/db_provider.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await DbProvider.query('inventory', orderBy: 'id DESC');
    
    final Set<String> cats = {'All'};
    for (var item in data) {
      if (item['category'] != null && item['category'].toString().isNotEmpty) {
        cats.add(item['category']);
      } else {
        cats.add('General');
      }
    }

    setState(() {
      _allItems = data;
      _categories = cats.toList()..sort();
      _categories.remove('All');
      _categories.insert(0, 'All');
      
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategory == 'All') {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          final cat = item['category'] ?? 'General';
          return cat == _selectedCategory;
        }).toList();
      }
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilter();
    });
  }

  Future<void> _addItem() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(photo.path).copy('${directory.path}/$fileName');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _ItemFormDialog(
        initialImagePath: savedImage.path,
        availableCategories: _categories.where((c) => c != 'All').toList(),
        onSave: (name, category, selling, original, stock, finalPath) async {
          await DbProvider.insert('inventory', {
            'name': name,
            'category': category,
            'sellingPrice': selling,
            'originalPrice': original,
            'stock': stock,
            'imagePath': finalPath,
          });
          _refresh();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (ctx) => _ItemFormDialog(
        initialImagePath: item['imagePath'] ?? '',
        existingItem: item,
        availableCategories: _categories.where((c) => c != 'All').toList(),
        onDelete: () async {
          await DbProvider.delete('inventory', 'id = ?', [item['id']]);
          if (item['imagePath'] != null) {
            final file = File(item['imagePath']);
            if (await file.exists()) await file.delete();
          }
          _refresh();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted')));
        },
        onSave: (name, category, selling, original, stock, finalPath) async {
          await DbProvider.update(
            'inventory', 
            {
              'name': name,
              'category': category,
              'sellingPrice': selling,
              'originalPrice': original,
              'stock': stock,
              'imagePath': finalPath,
            }, 
            'id = ?', 
            [item['id']]
          );
          _refresh();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item updated')));
        },
      ),
    );
  }

  Future<void> _handleStockChange(Map<String, dynamic> item, int change) async {
    if (change > 0) {
      await _updateStockOnly(item['id'], item['stock'], change);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock replenished')));
      return;
    }

    if (change < 0) {
      if (item['stock'] <= 0) return; 

      final standardPrice = (item['sellingPrice'] as num).toInt(); 

      showDialog(
        context: context,
        builder: (ctx) => _SaleConfirmDialog(
          itemName: item['name'],
          standardPrice: standardPrice,
          onConfirm: (finalPrice, discount) async {
            Navigator.pop(ctx); 
            
            await _updateStockOnly(item['id'], item['stock'], -1);
            
            String details = 'Sale: ${item['name']}';
            if (discount > 0) details += ' (Disc: KSH $discount)';

            await DbProvider.insert('txn', {
              'type': 'sale',        
              'itemId': item['id'],  
              'totalAmount': finalPrice, 
              'details': details,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sold for KSH $finalPrice'))
            );
          },
        ),
      );
    }
  }

  Future<void> _updateStockOnly(int id, int currentStock, int change) async {
    int newStock = currentStock + change;
    if (newStock < 0) newStock = 0;
    await DbProvider.update('inventory', {'stock': newStock}, 'id = ?', [id]);
    _refresh();
  }

  void _showImageZoom(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (c, i) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.green.shade100,
                  onSelected: (bool selected) {
                    if (selected) _onCategorySelected(cat);
                  },
                );
              },
            ),
          ),
          
          Expanded(
            child: _filteredItems.isEmpty
              ? Center(child: Text('No items in "$_selectedCategory"', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70, 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildItemCard(item);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: Icon(Icons.camera_alt),
        tooltip: 'Add Item',
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: GestureDetector(
              // NEW: Long press to zoom
              onLongPress: () {
                if (item['imagePath'] != null) _showImageZoom(item['imagePath']);
              },
              onTap: () => _editItem(item),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item['imagePath'] != null
                      ? Image.file(
                          File(item['imagePath']), 
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: Icon(Icons.broken_image, color: Colors.grey)),
                        )
                      : Container(color: Colors.grey.shade300, child: Icon(Icons.image)),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _editItem(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(item['category'] ?? 'General', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('KSH ${item['sellingPrice']}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          Text('Stock: ${item['stock']}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => _handleStockChange(item, -1),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Icon(Icons.remove, color: Colors.red, size: 20),
                      ),
                    ),
                    InkWell(
                      onTap: () => _handleStockChange(item, 1),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Icon(Icons.add, color: Colors.green, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Rest of dialogs unchanged)
// Sale Confirmation with Discount
class _SaleConfirmDialog extends StatefulWidget {
  final String itemName;
  final int standardPrice;
  final Function(int finalPrice, int discount) onConfirm;

  const _SaleConfirmDialog({required this.itemName, required this.standardPrice, required this.onConfirm});

  @override
  __SaleConfirmDialogState createState() => __SaleConfirmDialogState();
}

class __SaleConfirmDialogState extends State<_SaleConfirmDialog> {
  final _discountCtrl = TextEditingController(text: '0');
  int _finalPrice = 0;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.standardPrice;
    _discountCtrl.addListener(_updateTotal);
  }

  void _updateTotal() {
    int discount = int.tryParse(_discountCtrl.text) ?? 0;
    setState(() {
      _finalPrice = widget.standardPrice - discount;
      if (_finalPrice < 0) _finalPrice = 0;
    });
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Sale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Selling 1x ${widget.itemName}', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Standard Price:'),
              Text('KSH ${widget.standardPrice}', style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _discountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Discount Amount (Optional)',
              prefixText: '- KSH ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          SizedBox(height: 16),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL TO PAY:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('KSH $_finalPrice', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_finalPrice, int.tryParse(_discountCtrl.text) ?? 0),
          child: Text('Confirm Sale'),
        ),
      ],
    );
  }
}

// Add/Edit Item Form
class _ItemFormDialog extends StatefulWidget {
  final String initialImagePath;
  final Map<String, dynamic>? existingItem;
  final List<String> availableCategories;
  final Function(String, String, double, double, int, String) onSave;
  final VoidCallback? onDelete;

  const _ItemFormDialog({
    required this.initialImagePath, 
    required this.onSave, 
    required this.availableCategories,
    this.existingItem,
    this.onDelete,
  });

  @override
  __ItemFormDialogState createState() => __ItemFormDialogState();
}

class __ItemFormDialogState extends State<_ItemFormDialog> {
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  late String _currentImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;

    if (widget.existingItem != null) {
      _nameCtrl.text = widget.existingItem!['name'];
      _catCtrl.text = widget.existingItem!['category'] ?? 'General';
      _sellCtrl.text = widget.existingItem!['sellingPrice'].toString();
      _buyCtrl.text = widget.existingItem!['originalPrice'].toString();
      _stockCtrl.text = widget.existingItem!['stock'].toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _sellCtrl.dispose();
    _buyCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _retakePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_edit.jpg';
      final savedImage = await File(photo.path).copy('${directory.path}/$fileName');
      setState(() => _currentImagePath = savedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Item' : 'New Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _retakePhoto,
              child: Container(
                height: 100, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_currentImagePath), fit: BoxFit.cover, errorBuilder: (c,e,s)=>Icon(Icons.broken_image)),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
            SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue val) {
                if (val.text == '') return const Iterable<String>.empty();
                return widget.availableCategories.where((opt) => opt.toLowerCase().contains(val.text.toLowerCase()));
              },
              onSelected: (String selection) => _catCtrl.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                if (controller.text.isEmpty && _catCtrl.text.isNotEmpty) controller.text = _catCtrl.text;
                controller.addListener(() => _catCtrl.text = controller.text);
                
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(labelText: 'Category (e.g. Cables)', border: OutlineInputBorder()),
                );
              },
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _sellCtrl, decoration: InputDecoration(labelText: 'Selling', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                SizedBox(width: 8),
                Expanded(child: TextField(controller: _buyCtrl, decoration: InputDecoration(labelText: 'Buying', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: 8),
            TextField(controller: _stockCtrl, decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        if (isEditing) TextButton(onPressed: () {
           showDialog(context: context, builder: (c) => AlertDialog(
             title: Text('Delete Item?'),
             actions: [
               TextButton(onPressed: ()=>Navigator.pop(c), child: Text('Cancel')),
               TextButton(onPressed: (){ Navigator.pop(c); widget.onDelete?.call(); }, child: Text('Delete', style: TextStyle(color: Colors.red))),
             ]
           ));
        }, child: Text('Delete', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty) return;
            widget.onSave(
              _nameCtrl.text,
              _catCtrl.text.isEmpty ? 'General' : _catCtrl.text,
              double.tryParse(_sellCtrl.text) ?? 0,
              double.tryParse(_buyCtrl.text) ?? 0,
              int.tryParse(_stockCtrl.text) ?? 0,
              _currentImagePath,
            );
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}