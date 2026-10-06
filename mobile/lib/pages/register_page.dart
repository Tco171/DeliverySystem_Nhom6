import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage(
        'Mật khẩu xác nhận chưa khớp.',
        error: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.register(
        fullName: _fullNameController.text,
        shopName: _shopNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      _showMessage(
        'Đăng ký thành công. Vui lòng đăng nhập.',
      );

      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? Colors.red.shade700
            : const Color(0xFF2E7658),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF123F31),
        foregroundColor: Colors.white,
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPRESS',
                  style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF668177),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Đăng ký tài khoản',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173E32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo tài khoản để bắt đầu sử dụng dịch vụ giao hàng.',
                  style: TextStyle(
                    color: Color(0xFF66756F),
                  ),
                ),
                const SizedBox(height: 28),

                _field(
                  label: 'Họ và tên',
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên.';
                    }
                    return null;
                  },
                ),

                _field(
                  label: 'Tên cửa hàng (nếu có)',
                  controller: _shopNameController,
                  hint: 'Bỏ trống nếu bạn là người dùng cá nhân',
                ),

                _field(
                    label: 'Số điện thoại',
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại.';
                        }

                        final phone = value.trim();

                        if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
                        return 'Số điện thoại phải gồm 10 số và bắt đầu bằng số 0.';
                        }

                        return null;
                    },
                    ),

                _field(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại.';
                        }

                        final phone = value.trim();

                        final phoneRegex = RegExp(r'^0[0-9]{9}$');

                        if (!phoneRegex.hasMatch(phone)) {
                            return 'Số điện thoại phải gồm 10 số và bắt đầu bằng số 0.';
                        }

                        return null;
                    },
                ),

                _field(
                  label: 'Mật khẩu',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Mật khẩu cần ít nhất 8 ký tự.';
                    }
                    return null;
                  },
                ),

                _field(
                  label: 'Xác nhận mật khẩu',
                  controller: _confirmPasswordController,
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu.';
                    }
                    return null;
                  },
                ),

                Row(
                  children: [
                    Checkbox(
                      value: _showPassword,
                      onChanged: (value) {
                        setState(() {
                          _showPassword = value ?? false;
                        });
                      },
                    ),
                    const Text('Hiển thị mật khẩu'),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65520),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _register,
                    child: Text(
                      _loading
                          ? 'Đang xử lý...'
                          : 'Tạo tài khoản',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
        required String label,
        required TextEditingController controller,
        String? hint,
        bool obscureText = false,
        TextInputType? keyboardType,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? validator,
    }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              counterText: '',
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}