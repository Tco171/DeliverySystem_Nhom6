import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const StaffOrderDetailPage({super.key, required this.order});
  @override
  State<StaffOrderDetailPage> createState() => _StaffOrderDetailPageState();
}

class _StaffOrderDetailPageState extends State<StaffOrderDetailPage> {
  static const _green = Color(0xFF123F31);
  bool _busy = false;
  String? _error;
  static const _actions = <String, List<List<String>>>{
    'assigned': [['accept', 'Nhận đơn'], ['reject', 'Từ chối']],
    'accepted': [['start-pickup', 'Bắt đầu lấy hàng']],
    'picking_up': [['pickup-success', 'Lấy hàng thành công'], ['pickup-failed', 'Lấy hàng thất bại']],
    'picked_up': [['start-delivery', 'Bắt đầu giao hàng']],
    'delivering': [['delivery-success', 'Giao thành công'], ['delivery-failed', 'Giao thất bại']],
    'returning': [['return-complete', 'Hoàn hàng thành công']],
  };
  static const _labels = <String, String>{
    'assigned': 'Đã phân công', 'accepted': 'Đã nhận đơn',
    'picking_up': 'Đang lấy hàng', 'picked_up': 'Đã lấy hàng',
    'delivering': 'Đang giao hàng', 'delivered': 'Đã giao hàng',
    'returning': 'Đang hoàn hàng',
  };

  String _field(String name) => (widget.order[name] ?? '').toString();

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(context: context, builder: (dialogContext) =>
        StatefulBuilder(builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Nhập lý do'),
          content: TextField(
            controller: controller, maxLength: 300, maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối hoặc thất bại (ít nhất 3 ký tự)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => refresh(() {}),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: controller.text.trim().length < 3
                  ? null : () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Xác nhận'),
            ),
          ],
        )),
      );
    } finally {
      // Let the dialog's closing animation finish before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      controller.dispose();
    }
  }

  Future<void> _act(String action) async {
    if (_busy) return;
    String? reason;
    if (['reject', 'pickup-failed', 'delivery-failed'].contains(action)) {
      reason = await _askReason();
      if (reason == null) return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final rawId = widget.order['assignmentId'];
      final id = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
      if (id == null) throw Exception('Thiếu mã phân công của đơn hàng.');
      await ApiService.staffAction(id, action, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật đơn hàng thành công')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _field('assignmentStatus').isNotEmpty
        ? _field('assignmentStatus') : _field('shipmentStatus');
    final available = _actions[status] ?? const <List<String>>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn'),
        backgroundColor: _green, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SelectableText(_field('shipmentId'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Chip(label: Text(_labels[status] ?? status)),
        const SizedBox(height: 12),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Điểm lấy', style: Theme.of(context).textTheme.titleMedium),
            Text(_field('pickupAddress')),
            Text('${_field('senderName')} • ${_field('senderPhone')}'),
            const Divider(height: 28),
            Text('Điểm giao', style: Theme.of(context).textTheme.titleMedium),
            Text(_field('deliveryAddress')),
            Text('${_field('recipientName')} • ${_field('recipientPhone')}'),
            const Divider(height: 28),
            Text('COD: ${widget.order['codAmount'] ?? 0} đ'),
            if (_field('notes').isNotEmpty) Text('Ghi chú: ${_field('notes')}'),
          ]),
        )),
        if (_error != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
        if (_busy) const Padding(
          padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()),
        ),
        ...available.map((action) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(height: 54, child: FilledButton(
            onPressed: _busy ? null : () => _act(action[0]),
            style: FilledButton.styleFrom(
              backgroundColor: action[0].contains('failed') || action[0] == 'reject'
                  ? Colors.red.shade700 : _green,
            ),
            child: Text(action[1]),
          )),
        )),
        if (available.isEmpty) const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text('Không có thao tác dành cho trạng thái hiện tại.'),
        ),
      ]),
    );
  }
}
