import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'widgets.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  String? _area;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _handleRegister() {
    if (_nameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty ||
        _birthDate == null ||
        _gender == null ||
        _area == null) {
      _showSnack('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnack('Mật khẩu nhập lại không khớp');
      return;
    }

    final dateOnlyString =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    context.read<AuthBloc>().add(
      SignUpRequested(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: dateOnlyString,
        address: _area,
      ),
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _showSnack('Đăng ký thành công, vui lòng nhập OTP để xác thực');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OtpPage(
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text,
              ),
            ),
          );
        } else if (state is AuthFailure) {
          _showSnack(state.message);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                const CinemaHeader(small: true),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        RoundedTextField(
                          controller: _nameCtrl,
                          label: 'Họ và tên *',
                        ),
                        const SizedBox(height: 12),
                        RoundedTextField(
                          controller: _phoneCtrl,
                          label: 'Số điện thoại *',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        RoundedTextField(
                          controller: _emailCtrl,
                          label: 'Email *',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        RoundedTextField(
                          controller: _passwordCtrl,
                          label: 'Mật khẩu *',
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RoundedTextField(
                          controller: _confirmPasswordCtrl,
                          label: 'Nhập lại mật khẩu *',
                          obscure: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickBirthDate,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ngày sinh'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _birthDate == null
                                                ? 'Chọn ngày sinh'
                                                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                            style: TextStyle(
                                              color: _birthDate == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Giới tính'),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: _gender,
                                    isExpanded: true,
                                    hint: const Text('Chọn giới tính'),
                                    items: ['Nam', 'Nữ', 'Khác'].map((g) {
                                      return DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _gender = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tỉnh, thành phố'),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _area,
                              isExpanded: true,
                              hint: const Text('Chọn Khu vực'),
                              items: ['Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Khác'].map((a) {
                                return DropdownMenuItem(
                                  value: a,
                                  child: Text(a),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _area = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Hoàn tất',
                          onPressed: _handleRegister,
                          loading: loading,
                        ),
                      ],
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
}
