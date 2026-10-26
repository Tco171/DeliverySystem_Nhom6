import 'package:flutter/material.dart';
import '../models/operations_models.dart';
import '../services/operations_api_service.dart';
import '../../ui/express_theme.dart';

/// Yêu cầu 5: Đối soát COD (Settlement Logic)
/// - Tích hợp logic vào màn hình Settlement trên app, không thiết kế lại UI từ đầu
/// - Gọi 3 API:
///   1. GET /api/v1/settlements
///   2. POST /api/v1/settlements (tạo đối soát)
///   3. POST /api/v1/settlements/{id}/complete (hoàn tất)
/// - Rule lọc đơn hợp lệ: status == 'delivered' và CodCollected > 0
/// - Áp dụng switch/case tính phí COD Settlement tự động:
///   - shop_prepaid: Không trừ phí
///   - deduct_cod: Trừ shippingFee trực tiếp khỏi COD
///   - recipient: Khách trả phí nên không trừ vào COD
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;

  List<OperationShipment> _eligibleShipments = [];
  List<SettlementItem> _settlements = [];

  num _adjustment = 0;
  final TextEditingController _adjustmentController = TextEditingController(text: '0');
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _adjustmentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ===================================================================
  // 1. GET /api/v1/settlements & Lọc đơn hợp lệ
  // Rule: status == 'delivered' và CodCollected > 0
  // ===================================================================
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await OperationsApiService.getSettlements();
      final allEligible = res['eligibleShipments'] as List<OperationShipment>;
      final settlements = res['settlements'] as List<SettlementItem>;

      // Rule lọc đơn hợp lệ: status == 'delivered' và CodCollected > 0
      final validEligible = allEligible.where((s) {
        return s.status == 'delivered' && s.codCollected > 0;
      }).toList();

      if (!mounted) return;
      setState(() {
        _eligibleShipments = validEligible;
        _settlements = settlements;
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
  // Switch/Case tính phí COD Settlement tự động
  // ===================================================================
  num _calculateDeduction(String feePayer, num shippingFee) {
    switch (feePayer) {
      case 'shop_prepaid':
        // shop_prepaid: Không trừ phí
        return 0;

      case 'deduct_cod':
        // deduct_cod: Trừ shippingFee trực tiếp khỏi COD
        return shippingFee;

      case 'recipient':
        // recipient: Khách trả phí nên không trừ vào COD
        return 0;

      default:
        return 0;
    }
  }

  num get _totalCod =>
      _eligibleShipments.fold(0, (sum, item) => sum + item.codCollected);

  num get _totalDeduction => _eligibleShipments.fold(
      0, (sum, item) => sum + _calculateDeduction(item.feePayer, item.fee));

  num get _previewNet => _totalCod - _totalDeduction + _adjustment;

  // ===================================================================
  // 2. POST /api/v1/settlements (Tạo đối soát mới)
  // ===================================================================
  Future<void> _createSettlementBatch() async {
    if (_eligibleShipments.isEmpty || _busy) return;

    if (_adjustment != 0 && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập lý do khi có khoản điều chỉnh.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final shipmentIds = _eligibleShipments.map((e) => e.id).toList();
      await OperationsApiService.createSettlement(
        shipmentIds: shipmentIds,
        adjustment: _adjustment,
        adjustmentReason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lập kỳ đối soát thành công!'),
          backgroundColor: Color(0xFF123F31),
        ),
      );

      _adjustment = 0;
      _adjustmentController.text = '0';
      _reasonController.clear();

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // ===================================================================
  // 3. POST /api/v1/settlements/{id}/complete (Hoàn tất đối soát)
  // ===================================================================
  Future<void> _showCompleteSettlementDialog(SettlementItem item) async {
    final refController = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Hoàn tất kỳ đối soát\n${item.id}',
              style: const TextStyle(color: forest, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Số tiền trả shop: ${_formatMoney(item.netAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: forest)),
                  const SizedBox(height: 12),
                  if (item.netAmount > 0) ...[
                    const Text('Mã tham chiếu thanh toán (*):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã giao dịch chuyển khoản ngân hàng...',
                        hintStyle: const TextStyle(fontSize: 11, color: muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: confirmed,
                        activeColor: forest,
                        onChanged: (val) {
                          setDialogState(() => confirmed = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Xác nhận khoản thanh toán đã được chuyển cho shop.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('HỦY', style: TextStyle(color: muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white),
                onPressed: (!confirmed || (item.netAmount > 0 && refController.text.trim().isEmpty))
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        setState(() => _busy = true);
                        try {
                          await OperationsApiService.completeSettlement(
                            settlementId: item.id,
                            paymentReference: refController.text.trim(),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã ghi nhận hoàn tất kỳ đối soát!'),
                              backgroundColor: Color(0xFF123F31),
                            ),
                          );
                          await _loadData();
                        } catch (e) {
                          if (!mounted) return;
                          showError(context, e);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('XÁC NHẬN HOÀN TẤT', fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettlementDetail(SettlementItem settlement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kỳ: ${settlement.id}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forest),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  _buildDetailRow('Tổng COD:', _formatMoney(settlement.totalCod)),
                  _buildDetailRow('Phí khấu trừ:', _formatMoney(settlement.shippingDeduction)),
                  _buildDetailRow('Điều chỉnh:', _formatMoney(settlement.adjustment)),
                  if (settlement.adjustmentReason != null && settlement.adjustmentReason!.isNotEmpty)
                    _buildDetailRow('Lý do điều chỉnh:', settlement.adjustmentReason!),
                  _buildDetailRow('Trả shop (Net):', _formatMoney(settlement.netAmount), isBold: true),
                  _buildDetailRow('Trạng thái:', settlement.status == 'completed' ? 'Đã hoàn tất' : 'Chờ hoàn tất'),
                  if (settlement.completedAt != null)
                    _buildDetailRow('Hoàn tất lúc:', _formatDate(settlement.completedAt!)),
                  if (settlement.paymentReference != null && settlement.paymentReference!.isNotEmpty)
                    _buildDetailRow('Mã tham chiếu:', settlement.paymentReference!),
                  const SizedBox(height: 16),
                  const Text('Danh sách vận đơn đối soát:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: forest)),
                  const SizedBox(height: 8),
                  ...settlement.lines.map((line) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 6),
                        color: const Color(0xFFF7F8F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE4EAE5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(line.shipmentId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('COD: ${_formatMoney(line.codCollected)} | Trừ: ${_formatMoney(line.shippingDeduction)}',
                                  style: const TextStyle(fontSize: 11, color: muted)),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
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

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        title: const Text('Đối soát COD'),
        backgroundColor: forest,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loading || _busy ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: forest))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white),
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Đơn đủ điều kiện đối soát
                        _buildEligibleSection(),
                        const SizedBox(height: 20),

                        // Form Tạo đợt đối soát
                        if (_eligibleShipments.isNotEmpty) ...[
                          _buildCreateSettlementCard(),
                          const SizedBox(height: 20),
                        ],

                        // Lịch sử đối soát
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEligibleSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4EAE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đơn hàng COD đủ điều kiện',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: forest),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: forest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_eligibleShipments.length} đơn',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: forest),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Điều kiện hợp lệ: Trạng thái delivered và COD đã thu > 0.',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const Divider(height: 20),

            if (_eligibleShipments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'Không có đơn COD nào đủ điều kiện đối soát lúc này.',
                    style: TextStyle(color: muted, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _eligibleShipments.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (_, index) {
                  final s = _eligibleShipments[index];
                  final deduction = _calculateDeduction(s.feePayer, s.fee);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: forest)),
                          Text('Người nhận: ${s.recipientName}', style: const TextStyle(fontSize: 11, color: muted)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('COD: ${_formatMoney(s.codCollected)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: forest)),
                          Text(
                            'Khấu trừ (${s.feePayer}): ${_formatMoney(deduction)}',
                            style: TextStyle(fontSize: 10, color: deduction > 0 ? Colors.red.shade700 : muted),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSettlementCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4EAE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lập kỳ đối soát mới',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: forest),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Tổng COD:', _formatMoney(_totalCod)),
            _buildDetailRow('Khấu trừ cước (deduct_cod):', _formatMoney(_totalDeduction)),
            const Divider(height: 16),

            // Khoản điều chỉnh
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Điều chỉnh (đ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _adjustmentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _adjustment = num.tryParse(val.trim()) ?? 0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lý do điều chỉnh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          hintText: 'Lý do cộng/trừ...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tiền dự kiến trả shop
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dự kiến trả shop:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: forest)),
                  Text(
                    _formatMoney(_previewNet),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: forest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _busy ? null : _createSettlementBatch,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('LẬP KỲ ĐỐI SOÁT CHO CÁC ĐƠN TRÊN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử đối soát',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forest),
        ),
        const SizedBox(height: 10),
        if (_settlements.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE4EAE5)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Chưa có kỳ đối soát nào.', style: TextStyle(color: muted, fontSize: 13)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _settlements.length,
            itemBuilder: (_, index) {
              final item = _settlements[index];
              final isCompleted = item.status == 'completed';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE4EAE5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: forest)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isCompleted ? Colors.green.shade300 : Colors.amber.shade300),
                            ),
                            child: Text(
                              isCompleted ? 'ĐÃ HOÀN TẤT' : 'CHỜ HOÀN TẤT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildDetailRow('Ngày lập:', _formatDate(item.createdAt)),
                      _buildDetailRow('Số lượng đơn:', '${item.lines.length} đơn'),
                      _buildDetailRow('Trả shop:', _formatMoney(item.netAmount), isBold: true),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: forest,
                              side: const BorderSide(color: Color(0xFFC3D4CA)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            onPressed: () => _showSettlementDetail(item),
                            child: const Text('Chi tiết', style: TextStyle(fontSize: 11)),
                          ),
                          if (!isCompleted) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: forest,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              onPressed: _busy ? null : () => _showCompleteSettlementDialog(item),
                              child: const Text('Hoàn tất đối soát', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? forest : const Color(0xFF1A2C22),
            ),
          ),
        ],
      ),
    );
  }
}

