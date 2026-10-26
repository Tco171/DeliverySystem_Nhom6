import 'package:flutter/material.dart';
import '../models/operations_models.dart';
import '../services/operations_api_service.dart';
import '../assignment/assign_staff_dialog.dart';
import '../../ui/express_theme.dart';

/// Yêu cầu 2: Chi tiết đơn hàng (ShipmentDetailScreen)
/// Gọi API: GET /api/v1/operations/shipments/{shipmentId}
/// Giao diện cuộn dọc (Scrollable) chia làm 3 phần rõ ràng:
/// 1. Shipment information
/// 2. Events (Timeline tiến độ)
/// 3. Assignment History
/// Tích hợp Yêu cầu 4:
/// - Reassign mở modal, thành công tự động fetch lại toàn bộ màn hình
/// - Cancel Assignment bằng nút bấm, gọi PATCH /assignments/{id}/cancel, tuyệt đối không cho nhập tay trạng thái
class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentDetailScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  bool _loading = true;
  String? _error;
  OperationShipmentDetail? _detail;

  static const Map<String, String> statusNames = {
    'pending_pickup': 'Chờ lấy hàng',
    'pickup_failed': 'Lấy hàng thất bại',
    'picked_up': 'Đã lấy hàng',
    'in_transit': 'Đang vận chuyển',
    'at_hub': 'Đã đến kho',
    'out_for_delivery': 'Đang giao hàng',
    'delivery_failed': 'Giao hàng thất bại',
    'delivered': 'Giao thành công',
    'returning': 'Đang hoàn hàng',
    'returned': 'Đã giao hoàn',
    'return_confirmed': 'Shop đã nhận hàng hoàn',
  };

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // ===================================================================
  // Gọi API GET /api/v1/operations/shipments/{shipmentId}
  // ===================================================================
  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await OperationsApiService.getShipmentDetail(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ===================================================================
  // Yêu cầu 4: Hủy phân công qua nút bấm
  // Gọi PATCH /api/v1/operations/assignments/{id}/cancel
  // Tuyệt đối không cho phép nhập tay trạng thái hủy!
  // ===================================================================
  Future<void> _handleCancelAssignment(int assignmentId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy phân công',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn hủy phân công #$assignmentId không?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhập lý do hủy (*):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: forest),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Lý do hủy phân công...',
                hintStyle: const TextStyle(fontSize: 12, color: muted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ĐÓNG', style: TextStyle(color: muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hủy phân công.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('XÁC NHẬN HỦY', fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await OperationsApiService.cancelAssignment(
        assignmentId: assignmentId,
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy phân công thành công!'),
          backgroundColor: Color(0xFF123F31),
        ),
      );

      // Refresh toàn bộ màn hình Shipment Detail và Assignment History
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    }
  }

  // ===================================================================
  // Yêu cầu 4: Reassign
  // Mở modal, sau khi gọi API thành công -> refresh lại toàn bộ
  // ===================================================================
  Future<void> _handleReassign() async {
    final success = await ReassignStaffDialog.show(context, widget.shipmentId);
    if (success == true) {
      // Bắt buộc gọi lại hàm fetch để refresh toàn bộ màn hình Shipment Detail và Assignment History
      await _loadDetail();
    }
  }

  // Phân công lần đầu nếu chưa phân công
  Future<void> _handleAssign() async {
    final success = await AssignStaffDialog.show(context, widget.shipmentId);
    if (success == true) {
      await _loadDetail();
    }
  }

  String _formatMoney(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} đ';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'return_confirmed':
        return Colors.green.shade700;
      case 'pending_pickup':
        return Colors.amber.shade800;
      case 'pickup_failed':
      case 'delivery_failed':
      case 'cancelled':
        return Colors.red.shade700;
      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
      case 'accepted':
        return const Color(0xFF123F31);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        title: Text('Vận đơn ${widget.shipmentId}'),
        backgroundColor: forest,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _loadDetail,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: forest));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white),
                onPressed: _loadDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return const Center(child: Text('Không tìm thấy dữ liệu vận đơn.'));
    }

    final shipment = detail.shipment;
    final events = detail.events;
    final assignments = detail.assignmentHistory;
    final hasActiveAssignment = assignments.any((a) => a.isActive);

    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================
            // 1. SHIPMENT INFORMATION
            // =========================================================
            _buildSectionHeader(
              title: '1. Shipment Information',
              subtitle: 'Thông tin chi tiết kiện hàng và cước phí',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE4EAE5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shipment.id,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forest),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(shipment.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            statusNames[shipment.status] ?? shipment.status,
                            style: TextStyle(
                              color: _getStatusColor(shipment.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Người gửi:', '${shipment.senderName} (${shipment.senderPhone})'),
                    _buildInfoRow('Địa chỉ lấy:', shipment.pickupAddress),
                    const SizedBox(height: 8),
                    _buildInfoRow('Người nhận:', '${shipment.recipientName} (${shipment.recipientPhone})'),
                    _buildInfoRow('Địa chỉ giao:', shipment.deliveryAddress),
                    const SizedBox(height: 8),
                    _buildInfoRow('Hàng hóa:', '${shipment.goods} • ${shipment.weightKg} kg'),
                    if (shipment.lengthCm != null)
                      _buildInfoRow('Kích thước:', '${shipment.lengthCm}x${shipment.widthCm}x${shipment.heightCm} cm'),
                    const Divider(height: 24),
                    _buildInfoRow('Tiền thu hộ COD:', _formatMoney(shipment.codAmount), isHighlight: true),
                    _buildInfoRow('Cước vận chuyển:', '${_formatMoney(shipment.fee)} (${shipment.feePayer})'),
                    if (shipment.service != null) _buildInfoRow('Dịch vụ:', shipment.service!),
                    if (shipment.vehicleType != null) _buildInfoRow('Phương tiện:', shipment.vehicleType!),
                    _buildInfoRow('Ngày tạo đơn:', _formatDate(shipment.createdAt)),
                    if (shipment.notes != null && shipment.notes!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', shipment.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // =========================================================
            // 2. EVENTS (TIMELINE TIẾN ĐỘ)
            // =========================================================
            _buildSectionHeader(
              title: '2. Events',
              subtitle: 'Timeline tiến độ & hành trình vận chuyển',
              icon: Icons.timeline,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE4EAE5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: events.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Chưa có sự kiện nào được ghi nhận.',
                            style: TextStyle(color: muted, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final event = events[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(event.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (index < events.length - 1)
                                    Container(
                                      width: 2,
                                      height: 36,
                                      color: const Color(0xFFE4EAE5),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          statusNames[event.status] ?? event.status,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _getStatusColor(event.status),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(event.at),
                                          style: const TextStyle(color: muted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    if (event.note.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        event.note,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF24483B)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // =========================================================
            // 3. ASSIGNMENT HISTORY
            // =========================================================
            _buildSectionHeader(
              title: '3. Assignment History',
              subtitle: 'Lịch sử phân công nhân viên điều phối',
              icon: Icons.manage_accounts_outlined,
              action: hasActiveAssignment
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: orange,
                        side: const BorderSide(color: orange),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.sync_alt, size: 16),
                      label: const Text('Đổi NV (Reassign)', style: TextStyle(fontSize: 12)),
                      onPressed: _handleReassign,
                    )
                  : (shipment.status == 'pending_pickup' || shipment.status == 'pickup_failed')
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Phân công NV', style: TextStyle(fontSize: 12)),
                          onPressed: _handleAssign,
                        )
                      : null,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE4EAE5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: assignments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Chưa có lượt phân công nào.',
                            style: TextStyle(color: muted, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assignments.length,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (_, index) {
                          final item = assignments[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '#${item.id}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: muted, fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.staffName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: forest),
                                      ),
                                      if (item.employeeCode.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF6A6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.employeeCode,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: forest),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: item.isActive ? Colors.green.shade300 : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      item.isActive ? 'ĐANG HOẠT ĐỘNG' : 'HẾT HIỆU LỰC',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildSubInfoRow('Người phân công:', item.assignedByName),
                              _buildSubInfoRow('Thời gian:', _formatDate(item.assignedAt)),
                              _buildSubInfoRow('Trạng thái phân công:', item.status),
                              if (item.acceptedAt != null)
                                _buildSubInfoRow('Thời gian nhận việc:', _formatDate(item.acceptedAt)),
                              if (item.endedAt != null)
                                _buildSubInfoRow('Thời gian kết thúc:', _formatDate(item.endedAt)),
                              if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty)
                                _buildSubInfoRow('Lý do hủy/từ chối:', item.rejectionReason!, isAlert: true),

                              // Nút thao tác trực tiếp nếu phân công đang Active
                              if (item.isActive) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: orange,
                                        side: const BorderSide(color: orange),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.sync_alt, size: 14),
                                      label: const Text('Đổi NV', style: TextStyle(fontSize: 11)),
                                      onPressed: _handleReassign,
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 14),
                                      label: const Text('Hủy phân công', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _handleCancelAssignment(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: forest, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forest),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? forest : const Color(0xFF1A2C22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubInfoRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 11, color: muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAlert ? Colors.red.shade700 : const Color(0xFF24483B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

