import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyBillScreen extends StatelessWidget {
  final String phoneNumber;
  final Function(bool) onBillStatusChanged;
  const MyBillScreen({
    super.key,
    required this.phoneNumber,
    required this.onBillStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn phòng trọ')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(phoneNumber)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin phòng.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final roomNumber = data['roomNo'] ?? 'Không xác định';

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(phoneNumber)
                    .collection('bills')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, billSnapshot) {
              if (billSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!billSnapshot.hasData || billSnapshot.data!.docs.isEmpty) {
                // không có bill ⇒ chắc chắn không có bill chưa thanh toán
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onBillStatusChanged(false),
                );
                return const Center(child: Text('Chưa có hóa đơn nào.'));
              }

              final bills = billSnapshot.data!.docs;
              // Kiểm tra các hóa đơn chưa thanh toán
              bool hasUnpaidBill = bills.any((bill) {
                final d = bill.data() as Map<String, dynamic>;
                final paid = (d['isPaid'] as bool?) ?? false;
                return !paid;
              });
              // Báo về HomeScreen (sau frame)
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onBillStatusChanged(hasUnpaidBill),
              );

              return ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final d = bill.data() as Map<String, dynamic>;

                  final grandTotal = (d['grandTotal'] ?? 0).toDouble();
                  final createdAt = d['timestamp'] as Timestamp?;
                  final formattedDate =
                      createdAt != null
                          ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
                          : 'Không xác định';

                  final note = d['note'] as String?;
                  final isPaid = (d['isPaid'] as bool?) ?? false;
                  final pending = (d['isPending'] as bool?) ?? false;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày: $formattedDate',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildBillDetail('🔧 Điện', [
                            'Số điện đầu: ${d['startElectric'] ?? 0}',
                            'Số điện cuối: ${d['endElectric'] ?? 0}',
                            'Giá mỗi kW: ${_formatCurrency(d['pricePerKw'] ?? 0)}',
                            'Tổng tiền điện: ${_formatCurrency(d['electricTotal'] ?? 0)}',
                          ]),
                          _buildBillDetail('🚰 Nước', [
                            'Số nước đầu: ${d['startWater'] ?? 0}',
                            'Số nước cuối: ${d['endWater'] ?? 0}',
                            'Giá mỗi m³: ${_formatCurrency(d['pricePerM3'] ?? 0)}',
                            'Tổng tiền nước: ${_formatCurrency(d['waterTotal'] ?? 0)}',
                          ]),
                          _buildBillDetail('🏠 Tiền phòng', [
                            'Tiền phòng: ${_formatCurrency(d['roomCharge'] ?? 0)}',
                          ]),
                          _buildBillDetail('📌 Khoản thu khác', [
                            'Khoản khác: ${_formatCurrency(d['otherCharge'] ?? 0)}',
                          ]),
                          if (note != null && note.isNotEmpty)
                            _buildBillDetail('🗒️ Ghi chú', [note]),
                          const SizedBox(height: 10),
                          Text(
                            'Tổng hóa đơn: ${_formatCurrency(grandTotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          isPaid
                              ? Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 5),
                                  Text(
                                    'Đã thanh toán thành công',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              )
                              : pending
                              ? Row(
                                children: const [
                                  Icon(
                                    Icons.hourglass_top,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Đang chờ xử lý',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ],
                              )
                              : ElevatedButton(
                                onPressed:
                                    () => _payBill(
                                      context,
                                      phoneNumber,
                                      roomNumber,
                                      bill.id,
                                      grandTotal,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Thanh toán'),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBillDetail(String title, List<String> details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...details.map((detail) => Text(detail)),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final format = NumberFormat('#,##0', 'vi_VN');
    return '${format.format(value)} VND';
  }

  
Future<void> _showBankTransferInfoDialog(BuildContext context) async {
    // Lấy dữ liệu từ Firestore
    final snapshot =
        await FirebaseFirestore.instance
            .collection('transfer_info')
            .orderBy('timestamp', descending: true)
            .limit(1) // Giới hạn lấy 1 ảnh mới nhất
            .get();

    // Nếu có dữ liệu, hiển thị ảnh
    if (snapshot.docs.isNotEmpty) {
      final String imageUrl = snapshot.docs.first['imageUrl'];

      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Thông tin chuyển khoản'),
            content: GestureDetector(
              // Hiển thị ảnh từ Firebase Storage
              child: Image.network(imageUrl),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } else {
      // Nếu không có ảnh nào, hiển thị thông báo
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Thông tin chuyển khoản'),
            content: const Text(
              'Chưa có thông tin chuyển khoản nào được tải lên.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    }
  }

// Future<void> _saveImage(BuildContext context) async {
//     try {
//       // Load dữ liệu ảnh từ asset
//       final byteData = await rootBundle.load(
//         'assets/images/myVcb.jpg',
//       );
//       final result = await ImageGallerySaver.saveImage(
//         byteData.buffer.asUint8List(),
//         quality: 100,
//         name: 'bank_transfer_info',
//       );
//       // Kiểm tra kết quả lưu ảnh (result trả về Map hoặc String tùy phiên bản)
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Hình ảnh đã được lưu vào thư viện!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu hình ảnh: $e')));
//     }
//   }
  Future<void> _payBill(
    BuildContext context,
    String phoneNumber,
    String roomNumber,
    String billId,
    double grandTotal,
  ) async {
    String? paymentMethod = await _showConfirmDialog(context, grandTotal);
    if (paymentMethod == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('bills')
          .doc(billId)
          .update({'isPending': true, 'paymentMethod': paymentMethod});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán đang chờ xử lý bằng $paymentMethod!'),
          ),
        );
      }
      await sendNotification(
        roomNumber.toString(),
        paymentMethod,
        grandTotal.toString(),
      );

      // Nếu chọn chuyển khoản, hiển thị hình ảnh thông tin chuyển khoản
      if (paymentMethod == 'Chuyển khoản') {
        _showBankTransferInfoDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi thanh toán: $e')));
      }
    }
  }


  Future<void> sendNotification(
    String roomNo,
    String paymentMethod,
    String grandTotal,
  ) async {
    const serverUrl = 'https://pushnoti-8jr2.onrender.com/sendFCM';
    final body = jsonEncode({
      'roomNo': roomNo,
      'paymentMethod': paymentMethod,
      'ownerPhone': '+84906950367',
      'grandTotal': grandTotal,
    });
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        debugPrint('🔔 Gửi thông báo thành công qua server');
      } else {
        debugPrint('❌ Server báo lỗi: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi kết nối server: $e');
    }
  }

  Future<String?> _showConfirmDialog(
    BuildContext context,
    double grandTotal,
  ) async {
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận thanh toán'),
            content: Text(
              'Bạn có chắc chắn muốn thanh toán hóa đơn với tổng số tiền là ${_formatCurrency(grandTotal)} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('Tiền mặt'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Tiền mặt'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('Chuyển khoản'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Chuyển khoản'),
              ),
            ],
          ),
    );
  }
}
