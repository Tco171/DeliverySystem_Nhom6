import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/staff_api_service.dart';
import 'home_page.dart';

class StaffAssignmentsPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const StaffAssignmentsPage({super.key, this.user});

  @override
  State<StaffAssignmentsPage> createState() => _StaffAssignmentsPageState();
}

class _StaffAssignmentsPageState extends State<StaffAssignmentsPage> {
  List<StaffAssignment> _assignments = [];
  bool _loading = true;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Tải / refresh danh sách
  Future<void> _load() async {
    try {
      final list = await StaffApiService.getStaffAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = list;
        _error = '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _loading = false;
      });
    }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _onAction(StaffAssignment a, StaffAction action) async {
    var reason = '';

    // Reject / Pickup failed / Delivery failed -> hỏi lý do trước
    if (action.needsReason) {
      final input = await showDialog<String>(
        context: context,
        builder: (_) => _ReasonDialog(
          title: '${action.label} - ${a.shipmentId}',
        ),
      );
      if (input == null) return; // người dùng bấm Hủy
      reason = input;
    }

    setState(() => _busy = true);
    try {
      final result = await StaffApiService.perform(
        action,
        a.assignmentId,
        reason: reason,
      );
      if (!mounted) return;
      _toast(result['message']?.toString() ?? 'Thành công.');
      await _load(); // thành công -> refresh danh sách
    } catch (e) {
      if (!mounted) return;
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc giao nhận'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _assignments.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Chưa có đơn được phân công.')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _assignments.length,
              itemBuilder: (_, i) => _card(_assignments[i]),
            ),
    );
  }

  Widget _card(StaffAssignment a) {
    final actions = StaffApiService.availableActions(a);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.shipmentId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${assignmentStatusLabel[a.assignmentStatus] ?? a.assignmentStatus}'
              ' • ${shipmentStatusLabel[a.shipmentStatus] ?? a.shipmentStatus}',
            ),
            const Divider(height: 20),
            Text('Lấy: ${a.senderName} (${a.senderPhone})'),
            Text(a.pickupAddress),
            const SizedBox(height: 8),
            Text('Giao: ${a.recipientName} (${a.recipientPhone})'),
            Text(a.deliveryAddress),
            const SizedBox(height: 8),
            Text('Hàng: ${a.goods} • ${a.weightKg} kg • ${a.service}'),
            if (a.codAmount > 0) Text('Thu COD: ${a.codAmount} đ'),
            if (a.notes.isNotEmpty) Text('Ghi chú: ${a.notes}'),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in actions)
                    FilledButton(
                      onPressed: _busy ? null : () => _onAction(a, action),
                      child: Text(action.label),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hộp thoại nhập lý do (tự quản lý controller để tránh lỗi dispose).
class _ReasonDialog extends StatefulWidget {
  final String title;

  const _ReasonDialog({required this.title});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.length < 3 || value.length > 300) {
      setState(() => _error = 'Lý do phải từ 3 đến 300 ký tự.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 300,
        decoration: InputDecoration(
          hintText: 'Nhập lý do (3-300 ký tự)',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}