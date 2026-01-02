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

    final successProfile =
        await DBHelper.updateProfile(widget.userId, profileData);

    bool successUsername = true;
    final newUsername = _usernameController.text.trim();
    if (newUsername.isNotEmpty) {
      successUsername =
          await DBHelper.updateUsername(widget.userId, newUsername);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successProfile && successUsername
              ? '✅ Đã lưu thông tin'
              : '❌ Lưu thất bại',
        ),
        backgroundColor:
            successProfile && successUsername ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới không trùng khớp')),
      );
      return;
    }

    final success =
        await DBHelper.changePassword(widget.userId, oldPass, newPass);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? '✅ Đổi mật khẩu thành công' : '❌ Mật khẩu cũ không đúng'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(onPressed: _saveProfile, icon: const Icon(Icons.save))
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
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Chưa cập nhật tên'
                        : _nameController.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ===== THÔNG TIN CÁ NHÂN =====
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin cá nhân',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('Họ tên', Icons.badge),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          _inputDecoration('Tên đăng nhập', Icons.person),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration('Tuổi', Icons.cake),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration(
                                'Chiều cao (m)', Icons.height),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== GIỚI TÍNH =====
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.wc),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RadioListTile(
                        title: const Text('Nam'),
                        value: 'Nam',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        title: const Text('Nữ'),
                        value: 'Nữ',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== ĐỔI MẬT KHẨU =====
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đổi mật khẩu',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration(
                          'Mật khẩu cũ', Icons.lock_outline),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration:
                          _inputDecoration('Mật khẩu mới', Icons.lock),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration(
                          'Xác nhận mật khẩu', Icons.lock),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text('Đổi mật khẩu'),
                      ),
                    )
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
