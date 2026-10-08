import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'create_order_page.dart';
import 'login_page.dart';
import 'order_detail_page.dart';
import 'orders_page.dart';
import 'policy_faq_page.dart';
import 'price_list_page.dart';
import 'account_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HomePage({
    super.key,
    this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // =========================================================
  // CONTROLLER / STATE
  // =========================================================

  final TextEditingController _trackingController =
      TextEditingController();

  bool _loading = true;
  bool _tracking = false;

  List<Map<String, dynamic>> _orders = [];

  // =========================================================
  // COLORS
  // =========================================================

  static const Color forest = Color(0xFF123F31);
  static const Color orange = Color(0xFFE65520);
  static const Color background = Color(0xFFF7F8F4);
  static const Color muted = Color(0xFF668177);
  static const Color lime = Color(0xFFEAF6A6);

  // =========================================================
  // AUTH STATE
  // =========================================================

  bool get _isLoggedIn => widget.user != null;

  // =========================================================
  // LIFE CYCLE
  // =========================================================

  @override
  void initState() {
    super.initState();

    if (_isLoggedIn) {
      _loadOrders();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  // =========================================================
  // API
  // =========================================================

  Future<void> _loadOrders() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
          _orders = [];
        });
      }

      return;
    }

    try {
      final data = await ApiService.listOrders();

      if (!mounted) return;

      setState(() {
        _orders = data;
      });
    } catch (_) {
      // Home vẫn hoạt động nếu thống kê chưa tải được.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshHome() async {
    if (_isLoggedIn) {
      await _loadOrders();
    } else {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _trackOrder() async {
    final code = _trackingController.text.trim();

    if (code.isEmpty) {
      _message('Vui lòng nhập mã vận đơn.');
      return;
    }

    setState(() {
      _tracking = true;
    });

    try {
      final order = await ApiService.getOrder(code);

      if (!mounted) return;

      final shipmentId =
          order['id']?.toString() ?? code;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            shipmentId: shipmentId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _tracking = false;
        });
      }
    }
  }

  // =========================================================
  // LOGIN / LOGOUT
  // =========================================================

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    ApiService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
      (_) => false,
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _openCreateOrder() async {
    final created = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateOrderPage(),
      ),
    );

    if (!mounted) return;

    if (_isLoggedIn) {
      await _loadOrders();
      return;
    }

    final shipmentId = created?['id']?.toString();
    if (shipmentId != null && shipmentId.isNotEmpty) {
      _trackingController.text = shipmentId;
      _message(
        'Đã tạo đơn $shipmentId. Hãy lưu mã này để tra cứu vận đơn.',
      );
    }
  }

  Future<void> _openOrders() async {
    if (!_isLoggedIn) {
      _showLoginRequired(
        'Đăng nhập để xem và quản lý các đơn hàng của bạn.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrdersPage(),
      ),
    );

    if (mounted) {
      await _loadOrders();
    }
  }

  void _openPriceList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PriceListPage(),
      ),
    );
  }

  void _openPolicyFaq() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PolicyFaqPage(),
      ),
    );
  }

  // =========================================================
  // LOGIN REQUIRED
  // =========================================================

  void _showLoginRequired(String message) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              8,
              22,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: lime,
                      foregroundColor: forest,
                      child: Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Yêu cầu đăng nhập',
                      style: TextStyle(
                        color: forest,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  message,
                  style: const TextStyle(
                    color: muted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _openLogin();
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Đăng nhập'),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    child: const Text(
                      'Tiếp tục với tư cách khách',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // =========================================================
  // STATISTICS
  // =========================================================

  int get _deliveredCount {
    return _orders.where((order) {
      return order['status']?.toString() ==
          'delivered';
    }).length;
  }

  int get _activeCount {
    const completed = {
      'delivered',
      'returned',
      'return_confirmed',
    };

    return _orders.where((order) {
      return !completed.contains(
        order['status']?.toString(),
      );
    }).length;
  }

  num get _codCollected {
    num total = 0;

    for (final order in _orders) {
      total +=
          num.tryParse(
            order['codCollected']
                    ?.toString() ??
                '0',
          ) ??
          0;
    }

    return total;
  }

  String _money(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      if (i > 0 &&
          (raw.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(raw[i]);
    }

    return '$bufferđ';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final name =
        widget.user?['name'] ??
        widget.user?['fullName'] ??
        'Khách vãng lai';

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: forest,
        foregroundColor: Colors.white,

        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: lime,
              foregroundColor: forest,
              child: Text(
                'E',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(width: 10),

            Text(
              'express.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          if (_isLoggedIn)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: _logout,
              icon: const Icon(
                Icons.logout,
              ),
            )
          else
            TextButton.icon(
              onPressed: _openLogin,
              icon: const Icon(
                Icons.login,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshHome,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          children: [
            const Text(
              'EXPRESS / MOBILE',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _isLoggedIn
                  ? 'Xin chào, $name'
                  : 'Xin chào!',
              style: const TextStyle(
                color: forest,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            if (!_isLoggedIn) ...[
              const SizedBox(height: 4),

              const Text(
                'Bạn có thể sử dụng Express mà không cần tài khoản.',
                style: TextStyle(
                  color: muted,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 20),

            _hero(),

            if (!_isLoggedIn) ...[
              const SizedBox(height: 16),

              _guestCard(),
            ],

            const SizedBox(height: 24),

            _trackingBox(),

            if (_isLoggedIn) ...[
              const SizedBox(height: 26),

              _sectionTitle(
                'Tổng quan đơn hàng',
              ),

              const SizedBox(height: 12),

              _statistics(),
            ],

            const SizedBox(height: 28),

            _sectionTitle(
              _isLoggedIn
                  ? 'Chức năng'
                  : 'Khám phá Express',
            ),

            const SizedBox(height: 12),

            _featureGrid(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: forest,
        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'GIAO HÀNG DỄ DÀNG HƠN',
            style: TextStyle(
              color: lime,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Gửi hàng nhanh chóng,\nđơn giản và minh bạch.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _isLoggedIn
                ? 'Tạo đơn, quản lý đơn hàng và theo dõi hành trình giao hàng.'
                : 'Bạn vẫn có thể tạo đơn nhanh, xem bảng giá và tra cứu vận đơn mà không cần đăng nhập.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
            onPressed: _openCreateOrder,
            icon: const Icon(Icons.add),
            label: Text(
              _isLoggedIn
                  ? 'Tạo đơn mới'
                  : 'Tạo đơn nhanh',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GUEST CARD
  // =========================================================

  Widget _guestCard() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8E4),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.person_outline,
                color: forest,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Bạn đang sử dụng với tư cách khách vãng lai',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Bạn có thể tạo đơn nhanh, tra cứu vận đơn, '
            'xem bảng giá, dịch vụ, chính sách và FAQ. '
            'Đăng nhập để quản lý đơn hàng, COD và thông tin tài khoản.',
            style: TextStyle(
              color: muted,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: _openLogin,
            icon: const Icon(Icons.login),
            label: const Text(
              'Đăng nhập / Đăng ký',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRACKING
  // =========================================================

  Widget _trackingBox() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8E4),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.location_searching_outlined,
                color: forest,
              ),

              SizedBox(width: 8),

              Text(
                'Tra cứu vận đơn',
                style: TextStyle(
                  color: forest,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Nhập mã vận đơn để xem trạng thái và hành trình giao hàng.',
            style: TextStyle(
              color: muted,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _trackingController,
            textInputAction:
                TextInputAction.search,

            onSubmitted: (_) {
              if (!_tracking) {
                _trackOrder();
              }
            },

            decoration:
                const InputDecoration(
              hintText: 'Ví dụ: EXP-...',
              prefixIcon:
                  Icon(Icons.search),
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor: forest,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 13,
                ),
              ),

              onPressed:
                  _tracking
                      ? null
                      : _trackOrder,

              icon: _tracking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.search,
                    ),

              label: Text(
                _tracking
                    ? 'Đang tra cứu...'
                    : 'Tra cứu',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATISTICS
  // =========================================================

  Widget _statistics() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,

      children: [
        _statCard(
          icon:
              Icons.receipt_long_outlined,
          label: 'Tổng đơn',
          value:
              _orders.length.toString(),
        ),

        _statCard(
          icon: Icons.sync_outlined,
          label: 'Đang xử lý',
          value:
              _activeCount.toString(),
        ),

        _statCard(
          icon:
              Icons.check_circle_outline,
          label: 'Giao thành công',
          value:
              _deliveredCount.toString(),
        ),

        _statCard(
          icon:
              Icons.payments_outlined,
          label: 'COD đã thu',
          value:
              _money(_codCollected),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8E4),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: forest,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: forest,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FEATURE GRID
  // =========================================================

  Widget _featureGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.18,

      children: [
        _featureCard(
          icon:
              Icons.add_box_outlined,
          title: _isLoggedIn
              ? 'Tạo đơn'
              : 'Tạo đơn nhanh',
          subtitle:
              'Tạo yêu cầu giao hàng',
          onTap: _openCreateOrder,
        ),

        if (_isLoggedIn)
          _featureCard(
            icon:
                Icons.receipt_long_outlined,
            title: 'Đơn hàng',
            subtitle:
                'Xem và theo dõi đơn',
            onTap: _openOrders,
          )
        else
          _featureCard(
            icon: Icons.login,
            title: 'Đăng nhập',
            subtitle:
                'Quản lý đơn hàng của bạn',
            onTap: _openLogin,
          ),

        _featureCard(
          icon:
              Icons.local_shipping_outlined,
          title:
              'Bảng giá & Dịch vụ',
          subtitle:
              'Xem dịch vụ và cước phí',
          onTap: _openPriceList,
        ),

        _featureCard(
          icon: Icons.help_outline,
          title:
              'Chính sách & FAQ',
          subtitle:
              'Quy định và câu hỏi thường gặp',
          onTap: _openPolicyFaq,
        ),

        if (_isLoggedIn)
          _featureCard(
            icon: Icons.person_outline,
            title: 'Tài khoản',
            subtitle: 'Thông tin và bảo mật',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountPage(
                    user: widget.user!,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(
                0xFFE2E8E4,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    BoxDecoration(
                  color: lime,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,
                  color: forest,
                  size: 25,
                ),
              ),

              const SizedBox(height: 11),

              Text(
                title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: forest,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // COMMON
  // =========================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: forest,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}