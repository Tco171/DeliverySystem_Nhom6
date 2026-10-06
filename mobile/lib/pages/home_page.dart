import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'create_order_page.dart';
import 'login_page.dart';
import 'orders_page.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  // =========================================================
  // ĐĂNG XUẤT
  // =========================================================

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    // Xóa thông tin user đang đăng nhập
    ApiService.logout();

    if (!context.mounted) {
      return;
    }

    // Xóa toàn bộ navigation stack.
    // Người dùng không thể bấm Back để quay lại HomePage.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['fullName'] ?? 'Khách hàng';

    final role = user['role'] ?? 'customer';

    final accountType = user['accountType'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF123F31),
        foregroundColor: Colors.white,

        title: const Text('Express'),

        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                'EXPRESS / MOBILE',
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF668177),
                ),
              ),

              const SizedBox(height: 18),

              // =============================================
              // THÔNG TIN USER
              // =============================================
              Text(
                'Xin chào,\n$name',
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173E32),
                ),
              ),

              const SizedBox(height: 16),

              Text('Role: $role', style: const TextStyle(fontSize: 16)),

              if (accountType.toString().isNotEmpty)
                Text(
                  'Loại tài khoản: $accountType',
                  style: const TextStyle(fontSize: 16),
                ),

              const SizedBox(height: 24),

              // =============================================
              // CHỨC NĂNG
              // =============================================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Tạo đơn'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateOrderPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Đơn hàng'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =============================================
              // THÔNG BÁO
              // =============================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8E4)),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Đăng nhập thành công',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173E32),
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Ứng dụng Flutter đang sử dụng chung '
                      'ASP.NET Core Web API với website.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
