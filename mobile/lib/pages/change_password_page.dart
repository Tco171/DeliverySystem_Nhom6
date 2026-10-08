import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_page.dart';

class ChangePasswordPage
    extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChangePasswordPage({
    super.key,
    required this.user,
  });

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _currentPasswordController =
      TextEditingController();

  final _newPasswordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _saving = false;

  static const Color forest =
      Color(0xFF123F31);

  static const Color orange =
      Color(0xFFE65520);

  // static const Color muted =
  //     Color(0xFF668177);

  static const Color lime =
      Color(0xFFEAF6A6);

  static const Color background =
      Color(0xFFF7F8F4);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  String? _validateCurrentPassword(
    String? value,
  ) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại.';
    }

    return null;
  }

  String? _validateNewPassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }

    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }

    if (password ==
        _currentPasswordController.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới.';
    }

    if (value !=
        _newPasswordController.text) {
      return 'Mật khẩu nhập lại chưa khớp.';
    }

    return null;
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.changePassword(
        currentPassword:
            _currentPasswordController.text,

        newPassword:
            _newPasswordController.text,
      );

      if (!mounted) return;

      ApiService.logout();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Đổi mật khẩu thành công. '
            'Vui lòng đăng nhập lại.',
          ),
          backgroundColor: forest,
        ),
      );

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const LoginPage(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor:
              Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title:
            const Text('Đổi mật khẩu'),
        backgroundColor: forest,
        foregroundColor:
            Colors.white,
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            _header(),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.all(16),

              decoration:
                  BoxDecoration(
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
                  _passwordField(
                    controller:
                        _currentPasswordController,

                    label:
                        'Mật khẩu hiện tại',

                    hidden:
                        _hideCurrent,

                    onToggle: () {
                      setState(() {
                        _hideCurrent =
                            !_hideCurrent;
                      });
                    },

                    validator:
                        _validateCurrentPassword,
                  ),

                  _passwordField(
                    controller:
                        _newPasswordController,

                    label:
                        'Mật khẩu mới',

                    hidden:
                        _hideNew,

                    onToggle: () {
                      setState(() {
                        _hideNew =
                            !_hideNew;
                      });
                    },

                    validator:
                        _validateNewPassword,
                  ),

                  _passwordField(
                    controller:
                        _confirmPasswordController,

                    label:
                        'Nhập lại mật khẩu mới',

                    hidden:
                        _hideConfirm,

                    onToggle: () {
                      setState(() {
                        _hideConfirm =
                            !_hideConfirm;
                      });
                    },

                    validator:
                        _validateConfirmPassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _securityNote(),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,

              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      orange,

                  foregroundColor:
                      Colors.white,
                ),

                onPressed:
                    _saving
                        ? null
                        : _changePassword,

                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.lock_reset,
                      ),

                label: Text(
                  _saving
                      ? 'Đang đổi mật khẩu...'
                      : 'Đổi mật khẩu',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: forest,

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: lime,
            foregroundColor: forest,

            child: Icon(
              Icons.lock_outline,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Bảo mật tài khoản',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Thay đổi mật khẩu đăng nhập của bạn.',

                  style: TextStyle(
                    color:
                        Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityNote() {
    return Container(
      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color:
            lime.withValues(
          alpha: 0.45,
        ),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons
                .security_outlined,
            color: forest,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Mật khẩu nên có ít nhất 8 ký tự. '
              'Không chia sẻ mật khẩu hoặc mã xác nhận với người khác.',

              style: TextStyle(
                color: forest,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController
        controller,

    required String label,

    required bool hidden,

    required VoidCallback onToggle,

    required String? Function(String?)
        validator,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: TextFormField(
        controller: controller,

        obscureText: hidden,

        autocorrect: false,

        enableSuggestions: false,

        validator: validator,

        decoration:
            InputDecoration(
          labelText: label,

          prefixIcon:
              const Icon(
            Icons.lock_outline,
          ),

          suffixIcon:
              IconButton(
            onPressed: onToggle,

            tooltip: hidden
                ? 'Hiện mật khẩu'
                : 'Ẩn mật khẩu',

            icon: Icon(
              hidden
                  ? Icons
                      .visibility_off_outlined
                  : Icons
                      .visibility_outlined,
            ),
          ),

          filled: true,

          fillColor:
              const Color(
            0xFFFBFCFA,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),

            borderSide:
                const BorderSide(
              color:
                  Color(
                0xFFE2E8E4,
              ),
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),

            borderSide:
                const BorderSide(
              color: forest,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}