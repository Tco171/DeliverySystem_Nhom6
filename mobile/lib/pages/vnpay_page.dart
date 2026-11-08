import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class VnPayPage extends StatefulWidget {
  final String shipmentId;
  const VnPayPage({super.key, required this.shipmentId});

  @override
  State<VnPayPage> createState() => _VnPayPageState();
}

class _VnPayPageState extends State<VnPayPage> with WidgetsBindingObserver {
  String? _paymentId;
  String _status = '';
  String? _error;
  bool _busy = false;
  bool _openedBrowser = false;
  Timer? _paymentRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShipmentStatus();
  }

  @override
  void dispose() {
    _paymentRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The VNPay checkout is opened in an external browser. Re-check as soon
    // as the user returns to the Flutter app; the backend is authoritative.
    if (state == AppLifecycleState.resumed && _openedBrowser) {
      _openedBrowser = false;
      if (_paymentId != null) {
        _checkPayment();
      } else {
        _loadShipmentStatus();
      }
    }
  }

  Future<void> _loadShipmentStatus() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final statuses = await ApiService.getShipmentPaymentStatuses();
      if (!mounted) return;
      setState(() { _status = statuses[widget.shipmentId] ?? 'unpaid'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _message(e); });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPayment() async {
    if (_busy || _status == 'paid' || _status == 'pending') return;
    setState(() { _busy = true; _error = null; });
    try {
      final payment = await ApiService.createVnPayPayment(widget.shipmentId);
      final id = (payment['paymentId'] ?? '').toString();
      final urlText = (payment['paymentUrl'] ?? '').toString();
      final uri = Uri.tryParse(urlText);
      if (id.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw Exception('Backend trả về thông tin thanh toán VNPay không hợp lệ.');
      }
      if (!mounted) return;
      setState(() {
        _paymentId = id;
        _status = (payment['status'] ?? 'pending').toString().toLowerCase();
      });
      _openedBrowser = true;
      // On web opening VNPay does not necessarily change the Flutter lifecycle.
      // Poll while checkout is pending, so returning to this tab updates automatically.
      _paymentRefreshTimer?.cancel();
      _paymentRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || _status != 'pending') {
          _paymentRefreshTimer?.cancel();
          return;
        }
        _checkPayment();
      });
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _openedBrowser = false;
        // URL could not be opened: don't leave the retry button locked.
        if (mounted) setState(() => _status = '');
        throw Exception('Không mở được trình duyệt thanh toán VNPay.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _message(e); });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkPayment() async {
    if (_busy) return;
    final paymentId = _paymentId;
    if (paymentId == null) {
      await _loadShipmentStatus();
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final payment = await ApiService.getPaymentStatus(paymentId);
      if (!mounted) return;
      setState(() { _status = (payment['status'] ?? 'pending').toString().toLowerCase(); });
      if (_status == 'paid' || _status == 'failed') _paymentRefreshTimer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _message(e); });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');
  String get _statusText => switch (_status) {
    'paid' => 'Đã thanh toán',
    'pending' => 'Đang chờ xác nhận',
    'failed' => 'Thanh toán thất bại',
    _ => 'Chưa thanh toán',
  };

  @override
  Widget build(BuildContext context) {
    final paid = _status == 'paid';
    final pending = _status == 'pending';
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VNPay')),
      body: RefreshIndicator(
        onRefresh: _paymentId == null ? _loadShipmentStatus : _checkPayment,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text('Mã vận đơn: ${widget.shipmentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Icon(paid ? Icons.check_circle : pending ? Icons.schedule : _status == 'failed' ? Icons.error_outline : Icons.payments_outlined,
                    size: 54, color: paid ? Colors.green : _status == 'failed' ? Colors.red : const Color(0xFF123F31)),
                const SizedBox(height: 10),
                Text(_statusText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (pending) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Quay lại ứng dụng sau khi thanh toán và nhấn Kiểm tra trạng thái.', textAlign: TextAlign.center),
                ),
                if (_status == 'failed') const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Bạn có thể tạo giao dịch mới để thử lại.'),
                ),
              ]),
            )),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _busy || paid || pending ? null : _createPayment,
              icon: const Icon(Icons.open_in_browser),
              label: Text(_status == 'failed' ? 'Thanh toán lại bằng VNPay' : 'Thanh toán VNPay'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : (_paymentId == null ? _loadShipmentStatus : _checkPayment),
              icon: const Icon(Icons.refresh),
              label: const Text('Kiểm tra trạng thái thanh toán'),
            ),
            if (_busy) const Center(child: Padding(
              padding: EdgeInsets.all(12), child: CircularProgressIndicator(),
            )),
            const SizedBox(height: 10),
            const Text('Trạng thái được xác nhận từ Backend Express. Thanh toán trên Mobile và Web dùng chung một dữ liệu.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
