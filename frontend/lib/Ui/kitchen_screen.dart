import 'package:flutter/material.dart';

class KitchenDashboardScreen extends StatelessWidget {
  const KitchenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final dummyOrders = [
      {
        "table": "Table 1",
        "items": {"Paneer Butter Masala": 2, "Cold Coffee": 1},
      },
      {
        "table": "Table 3",
        "items": {"Chicken Biryani": 1, "Ice Cream": 2},
      },
      {
        "table": "Table 2",
        "items": {"Veg Fried Rice": 3},
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kitchen Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: dummyOrders.length,
          itemBuilder: (context, index) {
            final order = dummyOrders[index];
            final table = order['table'] as String;
            final items = order['items'] as Map<String, int>;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                title: Text(
                  table,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                children: items.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text("Qty: ${entry.value}"),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
