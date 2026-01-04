import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'Nam';
  bool _isLoading = true;

  // Toggle visibility cho mật khẩu
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DBHelper.getProfile(widget.userId);
    final username = await DBHelper.getUsername(widget.userId);

    if (!mounted) return;

    _nameController.text = profile?['name'] ?? '';
    _usernameController.text = username ?? '';
    _ageController.text = profile?['age']?.toString() ?? '';
    _heightController.text = profile?['height']?.toString() ?? '';
    _gender = profile?['gender'] ?? 'Nam';

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileData = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text),
      'height': double.tryParse(_heightController.text.replaceAll(',', '.')),
      'gender': _gender,
    };

    final successProfile = await DBHelper.updateProfile(widget.userId, profileData);

    bool successUsername = true;
    final newUsername = _usernameController.text.trim();
    if (newUsername.isNotEmpty) {
      successUsername = await DBHelper.updateUsername(widget.userId, newUsername);
    }

    if (!mounted) return;
    _showSnackBar(
      successProfile && successUsername ? '✅ Đã lưu thông tin' : '❌ Lưu thất bại',
      successProfile && successUsername,
    );
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin', false);
      return;
    }

    if (newPass != confirm) {
      _showSnackBar('Mật khẩu mới không trùng khớp', false);
      return;
    }

    final success = await DBHelper.changePassword(widget.userId, oldPass, newPass);

    _showSnackBar(
      success ? '✅ Đổi mật khẩu thành công' : '❌ Mật khẩu cũ không đúng',
      success,
    );

    if (success) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  PasswordInputDecoration _passwordDecoration(String label, IconData icon, bool visible, Function(bool) toggle) {
    return PasswordInputDecoration(
      label: label,
      icon: icon,
      visible: visible,
      onToggle: toggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save, size: 28),
              tooltip: 'Lưu thông tin',
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            /// ===== AVATAR =====
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isEmpty ? 'Chưa cập nhật tên' : _nameController.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// ===== THÔNG TIN CÁ NHÂN =====
            Card(
              elevation: 8,
              shadowColor: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.deepPurple, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Thông tin cá nhân',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Họ và tên', Icons.badge),
                      validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Tên đăng nhập', Icons.person_outline),
                      validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Tuổi', Icons.cake),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Chiều cao',
                              prefixIcon: Icon(Icons.height, color: Colors.deepPurple),
                              suffixText: 'm',
                              suffixStyle: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ===== GIỚI TÍNH =====
            Card(
              elevation: 8,
              shadowColor: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wc, color: Colors.deepPurple, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Giới tính',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Nam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            value: 'Nam',
                            groupValue: _gender,
                            onChanged: (v) => setState(() => _gender = v!),
                            activeColor: Colors.deepPurple,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Nữ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            value: 'Nữ',
                            groupValue: _gender,
                            onChanged: (v) => setState(() => _gender = v!),
                            activeColor: Colors.deepPurple,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ===== ĐỔI MẬT KHẨU =====
            Card(
              elevation: 8,
              shadowColor: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.deepPurple, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: !_oldPasswordVisible,
                      decoration: _passwordDecoration(
                        'Mật khẩu cũ',
                        Icons.lock_outline,
                        _oldPasswordVisible,
                        (v) => setState(() => _oldPasswordVisible = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_newPasswordVisible,
                      decoration: _passwordDecoration(
                        'Mật khẩu mới',
                        Icons.lock,
                        _newPasswordVisible,
                        (v) => setState(() => _newPasswordVisible = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      decoration: _passwordDecoration(
                        'Xác nhận mật khẩu',
                        Icons.lock,
                        _confirmPasswordVisible,
                        (v) => setState(() => _confirmPasswordVisible = v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: Colors.deepPurple.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

/// Custom InputDecoration cho Password field với eye icon
class PasswordInputDecoration extends InputDecoration {
  PasswordInputDecoration({
    required String label,
    required IconData icon,
    required bool visible,
    required Function(bool) onToggle,
  }) : super(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          suffixIcon: GestureDetector(
            onTap: () => onToggle(!visible),
            child: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade600,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        );
}
