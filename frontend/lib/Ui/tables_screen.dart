import 'package:flutter/material.dart';

class TableDashboardScreen extends StatefulWidget {
  const TableDashboardScreen({super.key});

  @override
  State<TableDashboardScreen> createState() => _TableDashboardScreenState();
}

class _TableDashboardScreenState extends State<TableDashboardScreen> {
  String selectedTable = 'Table 1';

  final List<String> tables = [
    'Table 1',
    'Table 2',
    'Table 3',
    'Table 4',
    'Table 5',
  ];

  final List<MenuItem> menuItems = [
    MenuItem(name: 'Paneer Butter Masala', price: 180),
    MenuItem(name: 'Chicken Biryani', price: 220),
    MenuItem(name: 'Veg Fried Rice', price: 150),
    MenuItem(name: 'Masala Dosa', price: 100),
    MenuItem(name: 'Cold Coffee', price: 80),
    MenuItem(name: 'Ice Cream', price: 70),
  ];

  final Map<MenuItem, int> order = {};

  void addToOrder(MenuItem item) {
    setState(() {
      order[item] = (order[item] ?? 0) + 1;
    });
  }

  void removeFromOrder(MenuItem item) {
    setState(() {
      if (order[item] != null) {
        order[item] = order[item]! - 1;
        if (order[item]! <= 0) {
          order.remove(item);
        }
      }
    });
  }

  int getTotalPrice() {
    return order.entries
        .map((entry) => entry.key.price * entry.value)
        .fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMenuSection()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOrderSection()),
                ],
              )
            : Column(
                children: [
                  Flexible(child: _buildMenuSection()),
                  const SizedBox(height: 20),
                  Flexible(child: _buildOrderSection()),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableSelector(),
        const SizedBox(height: 12),
        const Text('Menu Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('₹${item.price}'),
                  trailing: ElevatedButton(
                    onPressed: () => addToOrder(item),
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: order.isEmpty
              ? const Center(child: Text('No items added.'))
              : ListView(
                  children: order.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key.name),
                      subtitle: Text('₹${entry.key.price} x ${entry.value}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => removeFromOrder(entry.key),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => addToOrder(entry.key),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 10),
        Text('Total: ₹${getTotalPrice()}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            if (order.isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order placed for $selectedTable')),
            );
            setState(() => order.clear());
          },
          icon: const Icon(Icons.check),
          label: const Text('Place Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(40),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelector() {
    return Row(
      children: [
        const Text('Select Table:', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selectedTable,
          items: tables.map((table) {
            return DropdownMenuItem(value: table, child: Text(table));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedTable = value);
          },
        ),
      ],
    );
  }
}

class MenuItem {
  final String name;
  final int price;

  MenuItem({required this.name, required this.price});

  @override
  bool operator ==(Object other) => other is MenuItem && name == other.name;
  @override
  int get hashCode => name.hashCode;
}
