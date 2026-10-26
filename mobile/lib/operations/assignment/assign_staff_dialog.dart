import 'package:flutter/material.dart';
import '../models/operations_models.dart';
import '../services/operations_api_service.dart';
import '../../ui/express_theme.dart';

/// Yêu cầu 3: Phân công nhân viên (AssignStaffDialog)
/// AlertDialog phục vụ phân công:
/// - Hiển thị Shipment ID hiện tại
/// - Dropdown chọn nhân viên từ GET /api/v1/operations/staff/available
/// - 2 nút [HỦY], [XÁC NHẬN]
/// - Khi ấn XÁC NHẬN: gọi POST /api/v1/operations/shipments/{shipmentId}/assign
class AssignStaffDialog extends StatefulWidget {
  final String shipmentId;

  const AssignStaffDialog({
    super.key,
    required this.shipmentId,
  });

  static Future<bool?> show(BuildContext context, String shipmentId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignStaffDialog(shipmentId: shipmentId),
    );
  }

  @override
  State<AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<AssignStaffDialog> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<OperationStaff> _staffList = [];
  int? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staff = await OperationsApiService.getAvailableStaff();
      if (!mounted) return;
      setState(() {
        _staffList = staff;
        if (staff.isNotEmpty) {
          _selectedStaffId = staff.first.id;
        }
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

  Future<void> _confirmAssign() async {
    if (_selectedStaffId == null || _submitting) return;

    setState(() => _submitting = true);

    try {
      await OperationsApiService.assignShipment(
        shipmentId: widget.shipmentId,
        staffId: _selectedStaffId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phân công nhân viên thành công!'),
          backgroundColor: Color(0xFF123F31),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Phân công nhân viên',
        style: TextStyle(
          color: forest,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị Shipment ID hiện tại
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4EAE5)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Mã vận đơn: ',
                    style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      widget.shipmentId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: forest,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Chọn nhân viên phụ trách:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: forest),
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: forest),
                ),
              )
            else if (_error != null)
              Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchStaff,
                    child: const Text('Thử lại'),
                  ),
                ],
              )
            else if (_staffList.isEmpty)
              const Text(
                'Hiện không có nhân viên nào sẵn sàng.',
                style: TextStyle(color: muted, fontSize: 13, fontStyle: FontStyle.italic),
              )
            else
              // Dropdown chọn nhân viên từ GET /api/v1/operations/staff/available
              DropdownButtonFormField<int>(
                value: _selectedStaffId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _staffList.map((staff) {
                  return DropdownMenuItem<int>(
                    value: staff.id,
                    child: Text(
                      '${staff.fullName} (${staff.employeeCode.isNotEmpty ? staff.employeeCode : 'NV#${staff.id}'}) - KV: ${staff.area} (${staff.currentAssignments} việc)',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _submitting
                    ? null
                    : (val) {
                        setState(() => _selectedStaffId = val);
                      },
              ),
          ],
        ),
      ),
      actions: [
        // Nút [HỦY]
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'HỦY',
            style: TextStyle(color: muted, fontWeight: FontWeight.bold),
          ),
        ),
        // Nút [XÁC NHẬN]
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: forest,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: (_loading || _selectedStaffId == null || _submitting)
              ? null
              : _confirmAssign,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('XÁC NHẬN', fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Yêu cầu 4: Reassign Modal Dialog
class ReassignStaffDialog extends StatefulWidget {
  final String shipmentId;

  const ReassignStaffDialog({
    super.key,
    required this.shipmentId,
  });

  static Future<bool?> show(BuildContext context, String shipmentId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReassignStaffDialog(shipmentId: shipmentId),
    );
  }

  @override
  State<ReassignStaffDialog> createState() => _ReassignStaffDialogState();
}

class _ReassignStaffDialogState extends State<ReassignStaffDialog> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<OperationStaff> _staffList = [];
  int? _selectedStaffId;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staff = await OperationsApiService.getAvailableStaff();
      if (!mounted) return;
      setState(() {
        _staffList = staff;
        if (staff.isNotEmpty) {
          _selectedStaffId = staff.first.id;
        }
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

  Future<void> _confirmReassign() async {
    final reason = _reasonController.text.trim();
    if (_selectedStaffId == null || reason.isEmpty || _submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn nhân viên mới và nhập lý do chuyển phân công.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await OperationsApiService.reassignShipment(
        shipmentId: widget.shipmentId,
        staffId: _selectedStaffId!,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển phân công nhân viên thành công!'),
          backgroundColor: Color(0xFF123F31),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Chuyển phân công (Reassign)',
        style: TextStyle(
          color: forest,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4EAE5)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Mã vận đơn: ',
                      style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Text(
                        widget.shipmentId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: forest,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Chọn nhân viên nhận thay:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: forest),
              ),
              const SizedBox(height: 8),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: forest),
                  ),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _fetchStaff,
                      child: const Text('Thử lại'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedStaffId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _staffList.map((staff) {
                    return DropdownMenuItem<int>(
                      value: staff.id,
                      child: Text(
                        '${staff.fullName} (${staff.employeeCode.isNotEmpty ? staff.employeeCode : 'NV#${staff.id}'}) - KV: ${staff.area}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _submitting
                      ? null
                      : (val) {
                          setState(() => _selectedStaffId = val);
                        },
                ),
              const SizedBox(height: 14),

              const Text(
                'Lý do chuyển phân công (*):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: forest),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do đổi nhân viên (sự cố xe, quá tải...)',
                  hintStyle: const TextStyle(fontSize: 12, color: muted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'HỦY',
            style: TextStyle(color: muted, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE65520),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: (_loading || _selectedStaffId == null || _submitting)
              ? null
              : _confirmReassign,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('XÁC NHẬN', fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

