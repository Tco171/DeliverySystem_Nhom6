import 'package:flutter/material.dart';
import '../models/operations_models.dart';
import '../services/operations_api_service.dart';
import '../assignment/assign_staff_dialog.dart';
import 'shipment_detail_screen.dart';
import '../../ui/express_theme.dart';

/// Yêu cầu 1: Quản lý danh sách đơn hàng Operations (ShipmentListScreen)
/// - Gọi API: GET /api/v1/operations/shipments
///   Hỗ trợ tham số: status, search, customerId, staffId, sort, page, pageSize
/// - Hiển thị dạng thẻ (Card/ListTile) gồm:
///   Shipment ID, Customer, Pickup, Delivery, Staff, COD, Fee, Status, Created At, và Action (Chi tiết / Phân công)
/// - Tích hợp luồng lấy danh sách chờ phân công qua GET /api/v1/operations/shipments/new
///   Logic bắt buộc ở Frontend: Lọc bỏ các đơn thanh toán VNPay có paymentStatus khác 'PAID',
///   chỉ hiển thị các đơn VNPay đã thanh toán hoặc các đơn không dùng VNPay.
class ShipmentListScreen extends StatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends State<ShipmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter params
  String? _status;
  String _search = '';
  int? _customerId;
  int? _staffId;
  String _sort = 'newest';
  int _page = 1;
  final int _pageSize = 15;

  // Data states
  bool _loading = true;
  String? _error;
  List<OperationShipment> _shipments = [];
  int _totalItems = 0;
  int _totalPages = 1;

  // New shipments tab
  bool _loadingNew = false;
  String? _errorNew;
  List<OperationShipment> _newShipments = [];

  final TextEditingController _searchController = TextEditingController();

  static const Map<String, String> statusMap = {
    '': 'Tất cả trạng thái',
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _fetchShipments();
        } else {
          _fetchNewShipments();
        }
      }
    });

    _fetchShipments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===================================================================
  // 1. Fetch GET /api/v1/operations/shipments
  // ===================================================================
  Future<void> _fetchShipments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await OperationsApiService.getShipments(
        status: _status,
        search: _search,
        customerId: _customerId,
        staffId: _staffId,
        sort: _sort,
        page: _page,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _shipments = res['items'] as List<OperationShipment>;
        _totalItems = res['totalItems'] is int ? res['totalItems'] as int : 0;
        _totalPages = res['totalPages'] is int ? res['totalPages'] as int : 1;
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
  // 1b. Fetch GET /api/v1/operations/shipments/new
  // Logic bắt buộc ở Frontend đã tích hợp trong OperationsApiService:
  // Lọc bỏ đơn VNPay paymentStatus khác 'PAID'
  // ===================================================================
  Future<void> _fetchNewShipments() async {
    setState(() {
      _loadingNew = true;
      _errorNew = null;
    });

    try {
      final list = await OperationsApiService.getNewShipments();
      if (!mounted) return;
      setState(() {
        _newShipments = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorNew = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingNew = false);
      }
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

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
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
        return Colors.red.shade700;
      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
        return forest;
      default:
        return Colors.blueGrey;
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String tempStatus = _status ?? '';
        String tempSort = _sort;
        final customerController = TextEditingController(text: _customerId?.toString() ?? '');
        final staffController = TextEditingController(text: _staffId?.toString() ?? '');

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc đơn hàng Operations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forest),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Trạng thái:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: statusMap.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => tempStatus = val ?? '');
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mã khách hàng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: customerController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Customer ID',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mã nhân viên:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: staffController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Staff ID',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Sắp xếp theo thời gian:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: tempSort,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Mới nhất', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      setModalState(() => tempSort = val ?? 'newest');
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _status = null;
                              _customerId = null;
                              _staffId = null;
                              _sort = 'newest';
                              _page = 1;
                            });
                            Navigator.pop(ctx);
                            _fetchShipments();
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              _status = tempStatus.isEmpty ? null : tempStatus;
                              _customerId = int.tryParse(customerController.text.trim());
                              _staffId = int.tryParse(staffController.text.trim());
                              _sort = tempSort;
                              _page = 1;
                            });
                            Navigator.pop(ctx);
                            _fetchShipments();
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng Operations'),
        backgroundColor: forest,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: lime,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              text: 'Tất cả đơn hàng (${_totalItems > 0 ? _totalItems : _shipments.length})',
            ),
            Tab(
              text: 'Chờ phân công (${_newShipments.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllShipmentsTab(),
          _buildNewShipmentsTab(),
        ],
      ),
    );
  }

  // ===================================================================
  // TAB 1: TẤT CẢ ĐƠN HÀNG (GET /api/v1/operations/shipments)
  // ===================================================================
  Widget _buildAllShipmentsTab() {
    return Column(
      children: [
        // Thanh tìm kiếm & lọc
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã đơn, khách hàng, địa chỉ...',
                    hintStyle: const TextStyle(fontSize: 12, color: muted),
                    prefixIcon: const Icon(Icons.search, size: 20, color: forest),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                                _page = 1;
                              });
                              _fetchShipments();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _search = val.trim();
                      _page = 1;
                    });
                    _fetchShipments();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F4EE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.filter_list, color: forest),
                tooltip: 'Bộ lọc',
                onPressed: _showFilterModal,
              ),
            ],
          ),
        ),

        // Danh sách đơn hàng
        Expanded(
          child: _loading
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
                              onPressed: _fetchShipments,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _shipments.isEmpty
                      ? const Center(
                          child: Text('Không có đơn hàng nào phù hợp.', style: TextStyle(color: muted)),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchShipments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _shipments.length,
                            itemBuilder: (_, index) {
                              return _buildShipmentCard(_shipments[index]);
                            },
                          ),
                        ),
        ),

        // Pagination bar
        if (!_loading && _totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE4EAE5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trang $_page / $_totalPages (Tổng $_totalItems đơn)',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1
                          ? () {
                              setState(() => _page--);
                              _fetchShipments();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < _totalPages
                          ? () {
                              setState(() => _page++);
                              _fetchShipments();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ===================================================================
  // TAB 2: ĐƠN MỚI CHỜ PHÂN CÔNG (GET /api/v1/operations/shipments/new)
  // ===================================================================
  Widget _buildNewShipmentsTab() {
    if (_loadingNew) {
      return const Center(child: CircularProgressIndicator(color: forest));
    }

    if (_errorNew != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorNew!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white),
                onPressed: _fetchNewShipments,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF4F7E8),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đơn thanh toán trước qua VNPay đã được kiểm tra hợp lệ (PAID) trước khi hiển thị phân công.',
                  style: TextStyle(fontSize: 11, color: forest, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _newShipments.isEmpty
              ? const Center(
                  child: Text('Không có đơn hàng mới nào chờ phân công.', style: TextStyle(color: muted)),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNewShipments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _newShipments.length,
                    itemBuilder: (_, index) {
                      return _buildShipmentCard(_newShipments[index], isNewFlow: true);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ===================================================================
  // Thẻ đơn hàng (Card / ListTile) hiển thị đầy đủ thông tin:
  // Shipment ID, Customer, Pickup, Delivery, Staff, COD, Fee, Status, Created At, Action
  // ===================================================================
  Widget _buildShipmentCard(OperationShipment item, {bool isNewFlow = false}) {
    final assignedStaff = item.activeAssignment?.staffName;
    final staffCode = item.activeAssignment?.employeeCode;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4EAE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Shipment ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code, size: 16, color: forest),
                    const SizedBox(width: 6),
                    Text(
                      item.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: forest),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusMap[item.status] ?? item.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Customer (Khách hàng)
            _buildRow(
              icon: Icons.person_outline,
              label: 'Customer:',
              value: '${item.senderName} (${item.senderPhone})',
            ),
            // Pickup (Điểm lấy hàng)
            _buildRow(
              icon: Icons.upload_outlined,
              label: 'Pickup:',
              value: item.pickupAddress,
            ),
            // Delivery (Điểm giao hàng)
            _buildRow(
              icon: Icons.download_outlined,
              label: 'Delivery:',
              value: '${item.recipientName} - ${item.deliveryAddress}',
            ),
            // Staff (Nhân viên phân công)
            _buildRow(
              icon: Icons.delivery_dining_outlined,
              label: 'Staff:',
              value: assignedStaff != null
                  ? '$assignedStaff ${staffCode != null && staffCode.isNotEmpty ? '($staffCode)' : ''}'
                  : 'Chưa phân công',
              valueColor: assignedStaff != null ? forest : muted,
              isBold: assignedStaff != null,
            ),

            const SizedBox(height: 6),
            // Financials: COD & Fee
            Row(
              children: [
                Expanded(
                  child: _buildRow(
                    icon: Icons.monetization_on_outlined,
                    label: 'COD:',
                    value: _formatMoney(item.codAmount),
                    valueColor: forest,
                    isBold: true,
                  ),
                ),
                Expanded(
                  child: _buildRow(
                    icon: Icons.receipt_outlined,
                    label: 'Fee:',
                    value: _formatMoney(item.fee),
                  ),
                ),
              ],
            ),

            // Created At
            _buildRow(
              icon: Icons.access_time,
              label: 'Created At:',
              value: _formatDate(item.createdAt),
            ),

            const SizedBox(height: 10),
            // Actions: [Chi tiết] & [Phân công]
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Nút [Chi tiết]
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: forest,
                    side: const BorderSide(color: Color(0xFFC3D4CA)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipmentDetailScreen(shipmentId: item.id),
                      ),
                    ).then((_) {
                      if (_tabController.index == 0) {
                        _fetchShipments();
                      } else {
                        _fetchNewShipments();
                      }
                    });
                  },
                  child: const Text('Chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),

                // Nút [Phân công]
                if (item.activeAssignment == null &&
                    (item.status == 'pending_pickup' || item.status == 'pickup_failed')) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final assigned = await AssignStaffDialog.show(context, item.id);
                      if (assigned == true) {
                        if (_tabController.index == 0) {
                          _fetchShipments();
                        } else {
                          _fetchNewShipments();
                        }
                      }
                    },
                    child: const Text('Phân công', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          SizedBox(
            width: 75,
            child: Text(label, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF24483B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

