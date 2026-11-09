import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;
  Map<String, String> _paymentStatuses = {};
  Timer? _statusRefreshTimer;


  @override
  void initState() {
    super.initState();
    _future = ApiService.listOrders();
    _loadPaymentStatuses();
    // Flutter Web remains mounted when VNPay opens a new browser tab.
    // Periodically read the backend instead of requiring a full page reload.
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && ApiService.currentToken != null) _loadPaymentStatuses();
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _future = ApiService.listOrders());
    await _loadPaymentStatuses();
    try { await _future; } catch (_) { /* FutureBuilder displays the error. */ }
  }

  Future<void> _loadPaymentStatuses() async {
    if (ApiService.currentToken == null) return;
    try {
      final statuses = await ApiService.getShipmentPaymentStatuses();
      if (mounted) setState(() => _paymentStatuses = statuses);
    } catch (_) {
      // Keep order listing usable while status requests fail.
    }
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
                      'COD: ${order['codAmount'] ?? 0} đ\n'
                      'Thanh toán: ${order['feePayer'] != 'shop_prepaid' ? 'Theo hình thức khác' : _paymentStatuses[shipmentId] == 'paid' ? 'Đã thanh toán' : _paymentStatuses[shipmentId] == 'pending' ? 'Đang chờ xác nhận' : _paymentStatuses[shipmentId] == 'failed' ? 'Thanh toán thất bại' : 'Chưa thanh toán'}',
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
                            ).then((_) { if (mounted) _reload(); });
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
