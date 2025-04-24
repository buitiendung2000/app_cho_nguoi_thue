import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// ProfileScreen
/// --------------
/// • Lấy thông tin người dùng từ Firestore (doc‑id = số điện thoại)
/// • Cho phép chọn ảnh, upload lên Firebase Storage → lấy downloadURL
/// • Lưu URL vào Firestore bằng `set(…, merge:true)` (tạo mới field nếu chưa có)
/// • Hiển thị avatar từ File (khi vừa chọn) hoặc NetworkImage (khi reload)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  File? avatarImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  //───────────────────────────────────────────────────────────────────────────
  // Firestore: load hồ sơ
  //───────────────────────────────────────────────────────────────────────────
  Future<void> _loadUserData() async {
    try {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phone == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(phone).get();

      setState(() {
        userData = doc.data() ?? {};
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load error: $e');
      setState(() => isLoading = false);
    }
  }

  //───────────────────────────────────────────────────────────────────────────
  // Storage: upload ảnh và trả về downloadURL
  //───────────────────────────────────────────────────────────────────────────
  Future<String?> _uploadAvatar(File file) async {
    try {
      final phone = FirebaseAuth.instance.currentUser!.phoneNumber!;
      final ref = FirebaseStorage.instance.ref('avatars/$phone');

      final task = ref.putFile(file);
      task.snapshotEvents.listen((s) {
        debugPrint(
          '🟡 upload ${s.state} ${s.bytesTransferred}/${s.totalBytes}',
        );
      });

      await task;
      final url = await ref.getDownloadURL();
      debugPrint('✅ URL = $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseEx code=${e.code} msg=${e.message}');
      return null;
    }
  }

  //───────────────────────────────────────────────────────────────────────────
  // Chọn ảnh, upload, lưu URL
  //───────────────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => avatarImage = file);

    final url = await _uploadAvatar(file);
    if (url == null) return;

    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null) return;

    await FirebaseFirestore.instance.collection('users').doc(phone).set({
      'avatarUrl': url,
    }, SetOptions(merge: true));

    setState(() => userData?['avatarUrl'] = url);
  }

  //───────────────────────────────────────────────────────────────────────────
  // Lưu thay đổi khác của hồ sơ
  //───────────────────────────────────────────────────────────────────────────
  Future<void> _updateUserData() async {
    try {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phone == null || userData == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .set(userData!, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Đã cập nhật thông tin thành công!')),
        );
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Lỗi khi cập nhật thông tin!')),
        );
      }
    }
  }

  //───────────────────────────────────────────────────────────────────────────
  // UI
  //───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('❌ Không có dữ liệu hồ sơ!')),
      );
    }

    final avatarUrl = userData!['avatarUrl'] as String?;
final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ người thuê'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blueGrey.shade100,
                          backgroundImage:
                              avatarImage != null
                                  ? FileImage(avatarImage!)
                                  : (avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null)
                                      as ImageProvider?,
                          child:
                              (avatarImage == null && avatarUrl == null)
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userData?['fullName'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInputField('Phòng trọ số', 'roomNo', readOnly: true),
              _buildInputField('Họ và tên', 'fullName', readOnly: true),
              _buildInputField('Ngày sinh', 'dob'),
              _buildInputField('Giới tính', 'gender'),
              _buildInputField('Số định danh/CCCD', 'idNumber'),
              _buildInputField('Số điện thoại', 'phoneNumber', readOnly: true),
              _buildInputField('Email', 'email'),
              _buildInputField('Nơi thường trú', 'permanentAddress'),
              _buildInputField('Nơi tạm trú', 'temporaryAddress'),
              _buildInputField('Nơi ở hiện tại', 'currentAddress'),
              _buildInputField('Công việc', 'job'),
              _buildInputField('Tên chủ hộ', 'householdOwner'),
              _buildInputField('Quan hệ chủ hộ', 'relationship'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _updateUserData,
                icon: const Icon(Icons.save,color: Colors.white,),
                label: const Text('Lưu thay đổi',style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────────────────
  // Input field helper
  //───────────────────────────────────────────────────────────────────────────
  Widget _buildInputField(String label, String field, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: userData?[field]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          // fillColor: Theme.of(context).cardColor, hoặc colorScheme.surface
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).cardColor,
          labelStyle:
              Theme.of(context).textTheme.titleSmall, // Tự đổi màu theo theme
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),

        readOnly: readOnly,
        onChanged: (value) => setState(() => userData?[field] = value),
      ),
    );
  }
}
