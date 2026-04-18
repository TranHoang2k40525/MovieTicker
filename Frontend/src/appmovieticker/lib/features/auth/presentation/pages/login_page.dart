import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'widgets.dart';
import 'register_page.dart';
import '../../../movies/presentation/pages/movies_page.dart';

class LoginPage extends StatefulWidget {
  final String? prefilledEmail;
  final String? prefilledPassword;
  final bool returnToPreviousOnSuccess;

  const LoginPage({
    super.key,
    this.prefilledEmail,
    this.prefilledPassword,
    this.returnToPreviousOnSuccess = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefilledEmail ?? '');
    _passwordCtrl = TextEditingController(text: widget.prefilledPassword ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    context.read<AuthBloc>().add(
      SignInRequested(_emailCtrl.text.trim(), _passwordCtrl.text),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _showSnack('Đăng nhập thành công!');
          if (widget.returnToPreviousOnSuccess) {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MoviesPage()),
            );
          }
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
                const CinemaHeader(),
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
                          controller: _emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        RoundedTextField(
                          controller: _passwordCtrl,
                          label: 'Mật khẩu',
                          obscure: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Đăng nhập',
                          onPressed: _handleLogin,
                          loading: loading,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'hoặc',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              side: const BorderSide(color: Colors.black87),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Đăng ký tài khoản 67CS',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
