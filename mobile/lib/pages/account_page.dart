import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'change_password_page.dart';
import 'edit_account_page.dart';
import 'home_page.dart';

class AccountPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AccountPage({
    super.key,
    required this.user,
  });

  @override
  State<AccountPage> createState() =>
      _AccountPageState();
}

class _AccountPageState
    extends State<AccountPage> {
  static const Color forest =
      Color(0xFF123F31);

  static const Color muted =
      Color(0xFF668177);

  static const Color lime =
      Color(0xFFEAF6A6);

  static const Color background =
      Color(0xFFF7F8F4);

  late Map<String, dynamic> _user;

  bool _loadingAccount = true;

  @override
  void initState() {
    super.initState();

    _user = Map<String, dynamic>.from(widget.user);
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final fresh = await ApiService.getAccount();

      if (!mounted) return;

      setState(() {
        _user = fresh;
        _loadingAccount = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAccount = false;
      });
    }
  }

  String get _name {
    return _user['name']?.toString() ??
        _user['fullName']?.toString() ??
        'Khách hàng';
  }

  String get _email {
    return _user['email']?.toString() ??
        'Chưa cập nhật';
  }

  String get _phone {
    return _user['phone']?.toString() ??
        'Chưa cập nhật';
  }

  String get _shopName {
    final value =
        _user['shopName']?.toString() ?? '';

    if (value.trim().isEmpty) {
      return 'Không có';
    }

    return value;
  }

  String get _accountType {
    final value =
        _user['accountType']
            ?.toString()
            .toLowerCase();

    if (value == 'business') {
      return 'Cửa hàng';
    }

    return 'Cá nhân';
  }

  String get _role {
    final value =
        _user['role']?.toString();

    if (value == null ||
        value.isEmpty) {
      return 'Customer';
    }

    return value;
  }

  Future<void> _editProfile() async {
    final result =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditAccountPage(
          user: _user,
        ),
      ),
    );

    if (!mounted ||
        result == null) {
      return;
    }

    setState(() {
      _user = result;
    });
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChangePasswordPage(
          user: _user,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Đăng xuất'),
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
              child:
                  const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'Đăng xuất',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    ApiService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const HomePage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title:
            const Text('Tài khoản'),

        backgroundColor: forest,
        foregroundColor:
            Colors.white,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [
          if (_loadingAccount) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 14),
          ],

          _profileHeader(),

          const SizedBox(
            height: 20,
          ),

          _infoCard(),

          const SizedBox(
            height: 20,
          ),

          _actionButton(
            icon:
                Icons.edit_outlined,
            title:
                'Chỉnh sửa thông tin',
            subtitle:
                'Cập nhật họ tên, email, số điện thoại và tên cửa hàng',
            onTap: _editProfile,
          ),

          const SizedBox(
            height: 12,
          ),

          _actionButton(
            icon:
                Icons.lock_outline,
            title:
                'Đổi mật khẩu',
            subtitle:
                'Thay đổi mật khẩu đăng nhập',
            onTap:
                _changePassword,
          ),

          const SizedBox(
            height: 12,
          ),

          _actionButton(
            icon:
                Icons.security_outlined,
            title:
                'Bảo mật tài khoản',
            subtitle:
                'Không chia sẻ mật khẩu hoặc mã xác nhận cho người khác',
            onTap: () {},
          ),

          const SizedBox(
            height: 22,
          ),

          SizedBox(
            width: double.infinity,

            child:
                OutlinedButton.icon(
              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    Colors.red
                        .shade700,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
              ),

              onPressed: _logout,

              icon:
                  const Icon(
                Icons.logout,
              ),

              label:
                  const Text(
                'Đăng xuất',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: forest,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,

            backgroundColor: lime,

            foregroundColor:
                forest,

            child: Icon(
              Icons.person,
              size: 40,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            _name,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white,

              fontSize: 22,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            _role,

            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color:
              const Color(
            0xFFE2E8E4,
          ),
        ),
      ),

      child: Column(
        children: [
          _infoRow(
            Icons.person_outline,
            'Họ và tên',
            _name,
          ),

          _divider(),

          _infoRow(
            Icons.email_outlined,
            'Email',
            _email,
          ),

          _divider(),

          _infoRow(
            Icons.phone_outlined,
            'Số điện thoại',
            _phone,
          ),

          _divider(),

          _infoRow(
            Icons.badge_outlined,
            'Loại tài khoản',
            _accountType,
          ),

          if (_accountType ==
              'Cửa hàng') ...[
            _divider(),

            _infoRow(
              Icons
                  .storefront_outlined,
              'Tên cửa hàng',
              _shopName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 24,
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 21,
          color: forest,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Text(
                label,

                style:
                    const TextStyle(
                  color: muted,

                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                value,

                style:
                    const TextStyle(
                  color: forest,

                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFE2E8E4,
              ),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    BoxDecoration(
                  color: lime,

                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,

                  color: forest,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        color: forest,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,

                      style:
                          const TextStyle(
                        color: muted,

                        fontSize: 12,

                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .chevron_right,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}