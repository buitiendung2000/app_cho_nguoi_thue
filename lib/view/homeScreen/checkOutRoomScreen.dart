import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  // Danh sách checkbox cho tình trạng phòng
  List<ConditionItem> conditions = [
    ConditionItem("Tường, trần, sàn nhà (kiểm tra vết ố, nứt, bong tróc)"),
    ConditionItem("Nội thất và trang thiết bị (đồ đạc, điện tử)"),
    ConditionItem("Hệ thống điện nước (ổ cắm, công tắc, vòi, bồn cầu)"),
    ConditionItem("Cửa ra vào và cửa sổ (kiểm tra khóa, an toàn)"),
    ConditionItem("Thiết bị an ninh (chuông, camera, báo động)"),
    ConditionItem("Vệ sinh và phụ kiện (khu vực bếp, tủ, rèm)"),
    ConditionItem("Tình trạng hao mòn (ghi nhận hư hỏng vượt mức hao mòn)"),
    ConditionItem("Vật dụng kèm theo (kiểm tra theo hợp đồng)"),
  ];

  // Giá tạm tính
  double totalCost = 1000000;
  // Phương thức thanh toán mặc định
  String selectedPayment = "Tiền mặt";
  // Controller cho TextField "Dự kiến trả"
  final TextEditingController _duKienTraController = TextEditingController();
  // Lấy số điện thoại của user đang đăng nhập
  final String? _currentPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
  final currencyFormatter = NumberFormat("#,##0", "vi_VN");

  // Các biến lưu thông tin người dùng
  String? fullName;
  String? phoneNumber;
  String? roomNo;
  String registrationDateStr = '---';

  @override
  void initState() {
    super.initState();
    if (_currentPhone != null) {
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentPhone)
              .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          fullName = data['fullName'] ?? 'Chưa có tên';
          phoneNumber = data['phoneNumber'] ?? 'Chưa có SĐT';
          roomNo = data['roomNo'] ?? 'N/A';
          final Timestamp? regTS = data['registrationDate'];
          if (regTS != null) {
            registrationDateStr = DateFormat(
              'dd/MM/yyyy',
            ).format(regTS.toDate());
          } else {
            registrationDateStr = '---';
          }
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Hàm gửi thông báo "Trả phòng" cho chủ trọ qua API
  Future<void> sendCheckOutNotification() async {
    // URL của server đã triển khai (thay đổi theo cấu hình thực tế của bạn)
    final url = 'https://pushnoti-8jr2.onrender.com/sendCheckOutNoti';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'roomNo': roomNo ?? '',
          'phoneNumber': phoneNumber ?? '',
          'fullName': fullName ?? '',
        },
      );
      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // Hàm tạo document trong collection "returnRoom"
  Future<void> createReturnRoomRequest(String expectedReturn) async {
    // Lấy danh sách các điều kiện đã được chọn
    final selectedConditions =
        conditions
            .where((condition) => condition.isChecked)
            .map((e) => e.title)
            .toList();

    final requestData = {
      'roomNumber': roomNo,
      'tenantName': fullName,
      'tenantPhone': phoneNumber,
      'checkInDate':
          registrationDateStr, // Có thể lưu dạng string hoặc Timestamp
      'expectedCheckOutDate': expectedReturn,
      'roomCondition': selectedConditions,
      'paymentMethod': selectedPayment,
      'totalCost': totalCost,
      'submittedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('returnRoom')
          .add(requestData);
      print("Return room request created successfully.");
    } catch (e) {
      print("Error creating return room request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trả Phòng"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body:
          fullName == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: const [
                          Icon(Icons.hotel, size: 60, color: Colors.blueAccent),
                          SizedBox(height: 8),
                          Text(
                            "Trả Phòng",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Card Thông tin phòng
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Thông tin phòng",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Text(
                              "Số phòng: $roomNo",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "Nhận phòng: $registrationDateStr",
                              style: const TextStyle(fontSize: 16),
                            ),
                            // Row nhập "Dự kiến trả" với DatePicker
                            Row(
                              children: [
                                const Text(
                                  "Dự kiến trả: ",
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _duKienTraController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onTap: () async {
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        _duKienTraController.text = DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(picked);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Thông tin khách hàng
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Thông tin khách hàng",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Text(
                              "Tên: $fullName",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "SĐT: $phoneNumber",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card danh sách kiểm tra tình trạng phòng
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tình trạng phòng",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: conditions.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  title: Text(
                                    conditions[index].title,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  value: conditions[index].isChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      conditions[index].isChecked =
                                          value ?? false;
                                    });
                                  },
                                );
                              },
                            ),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Tạm tính: ${currencyFormatter.format(totalCost)}đ",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Phương thức thanh toán
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Phương thức thanh toán",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            RadioListTile<String>(
                              title: const Text(
                                "Tiền mặt",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Tiền mặt",
                              groupValue: selectedPayment,
                              onChanged: (value) {
                                setState(() {
                                  selectedPayment = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text(
                                "Chuyển khoản",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Chuyển khoản",
                              groupValue: selectedPayment,
                              onChanged: (value) {
                                setState(() {
                                  selectedPayment = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text(
                                "Ví điện tử",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Ví điện tử",
                              groupValue: selectedPayment,
                              onChanged: (value) {
                                setState(() {
                                  selectedPayment = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nút xác nhận trả phòng
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final duKienTra = _duKienTraController.text.trim();
                          if (duKienTra.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập ngày dự kiến trả.',
                                ),
                              ),
                            );
                            return;
                          }

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text("Xác nhận trả phòng"),
                                  content: Text(
                                    "Bạn có chắc chắn muốn trả phòng vào ngày $duKienTra không?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text("Hủy"),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text("Xác nhận"),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            // Tạo document mới trong collection "returnRoom"
                            await createReturnRoomRequest(duKienTra);

                            // Gửi thông báo "Trả phòng" cho chủ trọ qua API
                            await sendCheckOutNotification();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trả phòng thành công!'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "Xác nhận trả phòng",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class ConditionItem {
  String title;
  bool isChecked;
  ConditionItem(this.title, {this.isChecked = false});
}
