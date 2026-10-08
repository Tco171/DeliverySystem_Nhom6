import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class EditAccountPage
    extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditAccountPage({
    super.key,
    required this.user,
  });

  @override
  State<EditAccountPage> createState() =>
      _EditAccountPageState();
}

class _EditAccountPageState
    extends State<EditAccountPage> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _fullNameController;

  late final TextEditingController
      _emailController;

  late final TextEditingController
      _phoneController;

  late final TextEditingController
      _shopNameController;

  bool _saving = false;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color forest =
      Color(0xFF123F31);

  static const Color orange =
      Color(0xFFE65520);

  static const Color muted =
      Color(0xFF668177);

  static const Color lime =
      Color(0xFFEAF6A6);

  static const Color background =
      Color(0xFFF7F8F4);

  // =========================================================
  // ACCOUNT
  // =========================================================

  bool get _isBusiness {
    return widget.user['accountType']
            ?.toString()
            .toLowerCase() ==
        'business';
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _fullNameController =
        TextEditingController(
      text:
          widget.user['fullName']
                  ?.toString() ??
              widget.user['name']
                  ?.toString() ??
              '',
    );

    _emailController =
        TextEditingController(
      text:
          widget.user['email']
                  ?.toString() ??
              '',
    );

    _phoneController =
        TextEditingController(
      text:
          widget.user['phone']
                  ?.toString() ??
              '',
    );

    _shopNameController =
        TextEditingController(
      text:
          widget.user['shopName']
                  ?.toString() ??
              '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();

    super.dispose();
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  String? _validateName(
    String? value,
  ) {
    final name =
        value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Vui lòng nhập họ và tên.';
    }

    if (name.length > 100) {
      return 'Họ và tên quá dài.';
    }

    return null;
  }

  String? _validateEmail(
    String? value,
  ) {
    final email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }

    final regex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Email không hợp lệ.';
    }

    return null;
  }

  String? _validatePhone(
    String? value,
  ) {
    final phone =
        value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }

    if (!RegExp(
      r'^0[0-9]{9}$',
    ).hasMatch(phone)) {
      return 'Số điện thoại phải gồm 10 số và bắt đầu bằng 0.';
    }

    return null;
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updated =
          await ApiService.updateAccount(
        fullName:
            _fullNameController.text,

        email:
            _emailController.text,

        phone:
            _phoneController.text,

        shopName: _isBusiness
            ? _shopNameController.text
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Cập nhật thông tin thành công.',
          ),
          backgroundColor: forest,
        ),
      );

      Navigator.pop(
        context,
        updated,
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
        ),
        backgroundColor: forest,
        foregroundColor: Colors.white,
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            _header(),

            const SizedBox(
              height: 20,
            ),

            _card(
              children: [
                _field(
                  controller:
                      _fullNameController,

                  label:
                      'Họ và tên',

                  icon:
                      Icons.person_outline,

                  validator:
                      _validateName,
                ),

                _field(
                  controller:
                      _emailController,

                  label: 'Email',

                  icon:
                      Icons.email_outlined,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  validator:
                      _validateEmail,
                ),

                _field(
                  controller:
                      _phoneController,

                  label:
                      'Số điện thoại',

                  icon:
                      Icons.phone_outlined,

                  keyboardType:
                      TextInputType.phone,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,

                    LengthLimitingTextInputFormatter(
                      10,
                    ),
                  ],

                  validator:
                      _validatePhone,
                ),

                if (_isBusiness)
                  _field(
                    controller:
                        _shopNameController,

                    label:
                        'Tên cửa hàng',

                    icon:
                        Icons
                            .storefront_outlined,

                    validator: (_) =>
                        null,
                  ),

                _readOnlyField(
                  label:
                      'Loại tài khoản',

                  value: _isBusiness
                      ? 'Cửa hàng'
                      : 'Cá nhân',

                  icon:
                      Icons.badge_outlined,
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

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
                        : _save,

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
                        Icons.save_outlined,
                      ),

                label: Text(
                  _saving
                      ? 'Đang lưu...'
                      : 'Lưu thay đổi',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Email và số điện thoại phải là duy nhất trong hệ thống.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

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
              Icons.edit_outlined,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Thông tin cá nhân',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Cập nhật thông tin tài khoản của bạn.',

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

  // =========================================================
  // CARD
  // =========================================================

  Widget _card({
    required List<Widget> children,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

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
        children: children,
      ),
    );
  }

  // =========================================================
  // FIELD
  // =========================================================

  Widget _field({
    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    TextInputType keyboardType =
        TextInputType.text,

    List<TextInputFormatter>?
        inputFormatters,

    String? Function(String?)?
        validator,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: TextFormField(
        controller: controller,

        keyboardType:
            keyboardType,

        inputFormatters:
            inputFormatters,

        validator: validator,

        decoration:
            InputDecoration(
          labelText: label,

          prefixIcon:
              Icon(icon),

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

  // =========================================================
  // READ ONLY
  // =========================================================

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,

      enabled: false,

      decoration:
          InputDecoration(
        labelText: label,

        prefixIcon:
            Icon(icon),

        filled: true,

        fillColor:
            const Color(
          0xFFF2F4F1,
        ),

        disabledBorder:
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
      ),
    );
  }
}