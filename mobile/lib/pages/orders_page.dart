import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.listOrders();
  }

  Future<void> _reload() async {
    setState(() => _future = ApiService.listOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: const Color(0xFF123F31),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(snapshot.error.toString())),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Chưa có đơn hàng.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                final shipmentId = order['id']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(shipmentId),
                    subtitle: Text(
                      '${order['recipientName'] ?? ''}\n'
                      '${order['deliveryAddress'] ?? ''}\n'
                      'COD: ${order['codAmount'] ?? 0} đ',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: shipmentId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailPage(
                                  shipmentId: shipmentId,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
