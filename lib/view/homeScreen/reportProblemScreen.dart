import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _additionalFeedback = '';

  // Map lưu trạng thái các CheckBox cho các vấn đề cần báo cáo
  final Map<String, bool> _issueMap = {
    '1. Cúp điện, mất điện không rõ lý do': false,
    '2. Nước không chảy, nước yếu hoặc có mùi lạ': false,
    '3. Cống, bồn cầu, hoặc bể phốt bị tắc nghẽn, gây tràn hoặc ngập nước':
        false,
    '4. Mất chìa khóa phòng hoặc khóa bị hỏng': false,
    '5. Phát hiện bất kỳ dấu hiệu đột nhập, kẻ xâm nhập hoặc tình huống bất thường':
        false,
    '6. Điều hòa, máy giặt, lò vi sóng hoặc các thiết bị trong phòng bị hư hỏng':
        false,
    '7. Cửa sổ, cửa ra vào không đóng được, hoặc bị hỏng': false,
    '8. Phát hiện côn trùng như gián, chuột, hoặc côn trùng gây hại khác':
        false,
    '9. Mùi hôi khó chịu không thể xử lý': false,
    '10. Tường, trần nhà bị nứt, rò rỉ nước, hay có dấu hiệu của sự cố kết cấu':
        false,
    '11. Mái nhà hoặc cửa sổ bị hỏng do mưa bão': false,
    '12. Rò rỉ gas hoặc hệ thống sưởi không hoạt động': false,
    '13. Động vật gây hại hoặc thiên tai ảnh hưởng đến phòng': false,
    '14. Không nhận được hóa đơn thanh toán hoặc các vấn đề liên quan đến tiền thuê phòng':
        false,
    '15. Hỏa hoạn, cháy nổ, hay các tình huống khẩn cấp đe dọa đến tính mạng hoặc tài sản':
        false,
  };

  /// Hàm gửi feedback: Lưu dữ liệu lên Firestore và gọi API để gửi thông báo cho chủ trọ.
  Future<void> _sendFeedback() async {
    // Lấy số điện thoại của người dùng từ FirebaseAuth
    String phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    // Lấy roomNo từ Firestore dựa trên phoneNumber
    String roomNo = 'unknown';
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(phoneNumber)
              .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        roomNo = data['roomNo'] ?? 'unknown';
      } else {
        print('[DEBUG] Document không tồn tại cho user: $phoneNumber');
      }
    } catch (error) {
      print('[DEBUG] Lỗi khi lấy roomNo từ Firestore: $error');
    }

    // Thu thập danh sách các vấn đề được chọn
    List<String> selectedIssues =
        _issueMap.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
    print('[DEBUG] Selected issues: $selectedIssues');

    // Tạo map dữ liệu để gửi lên Firestore
    Map<String, dynamic> feedbackData = {
      'roomNo': roomNo,
      'phoneNumber': phoneNumber,
      'selectedIssues': selectedIssues,
      'additionalFeedback': _additionalFeedback,
      'processed': false, // Thêm trường processed mặc định bằng false
      'timestamp': FieldValue.serverTimestamp(),
    };

    print('[DEBUG] feedbackData: $feedbackData');

    try {
      // Lưu feedback vào Firestore
      await FirebaseFirestore.instance
          .collection('feedbacks')
          .add(feedbackData);
      print('[DEBUG] Feedback đã được lưu vào Firestore.');

      // Gọi API để gửi thông báo tới app Chủ trọ
      final Uri notificationUrl = Uri.parse(
        'https://pushnoti-8jr2.onrender.com/sendFeedbackNoti',
      );

      Map<String, String> notificationBody = {
        'roomNo': roomNo,
        'phoneNumber': phoneNumber,
        'selectedIssues': selectedIssues.join(', '),
        'additionalFeedback': _additionalFeedback,
      };
      print('[DEBUG] Gửi request tới API với body: $notificationBody');

      final notificationResponse = await http.post(
        notificationUrl,
        body: notificationBody,
      );
      print(
        "[DEBUG] Owner notification response: ${notificationResponse.body}",
      );

      // Thông báo thành công cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cảm ơn bạn đã gửi phản hồi!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      print("[DEBUG] Lỗi khi gửi feedback: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi phản hồi thất bại: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo lỗi, góp ý'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB388FF), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn các vấn đề gặp phải:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                // Hiển thị danh sách các CheckboxListTile trong Card với hiệu ứng bo góc
                ..._issueMap.keys.map((issue) {
                  return Card(
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: CheckboxListTile(
                      title: Text(
                        issue,
                        style: TextStyle(color: Colors.black87),
                      ),
                      value: _issueMap[issue],
                      activeColor: Colors.deepPurple,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _issueMap[issue] = newValue ?? false;
                        });
                      },
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                Text(
                  'Góp ý thêm (nếu có):',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Nhập góp ý / báo lỗi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  onSaved: (value) {
                    _additionalFeedback = value ?? '';
                  },
                ),
                SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _sendFeedback();
                      }
                    },
                    child: Text('Gửi', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
