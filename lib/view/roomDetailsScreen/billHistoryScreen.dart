import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BillHistoryScreen extends StatelessWidget {
  final String userId;

  const BillHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hóa đơn')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('bills')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có hóa đơn nào.'));
          }

          final bills = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final data = bill.data() as Map<String, dynamic>;

              // ✅ Lấy dữ liệu từ Firestore
              double startElectric = data['startElectric'] ?? 0;
              double endElectric = data['endElectric'] ?? 0;
              double electricConsumption = data['electricConsumption'] ?? 0;
              double pricePerKw = data['pricePerKw'] ?? 0;
              double electricTotal = data['electricTotal'] ?? 0;

              double startWater = data['startWater'] ?? 0;
              double endWater = data['endWater'] ?? 0;
              double waterConsumption = data['waterConsumption'] ?? 0;
              double pricePerM3 = data['pricePerM3'] ?? 0;
              double waterTotal = data['waterTotal'] ?? 0;

              double grandTotal = data['grandTotal'] ?? 0;

              Timestamp? createdAt = data['timestamp'] as Timestamp?;
              String formattedDate = createdAt != null
                  ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
                  : 'Không xác định';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long,
                      color: Colors.blue, size: 40),
                  title: Text(
                    'Ngày: $formattedDate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔋 Điện
                      const Text('💡 Điện',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Số điện đầu: $startElectric'),
                      Text('Số điện cuối: $endElectric'),
                      Text('Tiêu thụ: $electricConsumption kW'),
                      Text('Giá mỗi kW: ${pricePerKw.toStringAsFixed(0)} VND'),
                      Text(
                          'Tổng tiền điện: ${electricTotal.toStringAsFixed(0)} VND'),

                      const SizedBox(height: 8),

                      // 🚰 Nước
                      const Text('🚰 Nước',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Số nước đầu: $startWater'),
                      Text('Số nước cuối: $endWater'),
                      Text('Tiêu thụ: $waterConsumption m³'),
                      Text('Giá mỗi m³: ${pricePerM3.toStringAsFixed(0)} VND'),
                      Text(
                          'Tổng tiền nước: ${waterTotal.toStringAsFixed(0)} VND'),

                      const SizedBox(height: 8),

                      // 💰 Tổng tiền
                      Text(
                        'Tổng hóa đơn: ${grandTotal.toStringAsFixed(0)} VND',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBill(context, bill.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔥 Xóa hóa đơn
  Future<void> _deleteBill(BuildContext context, String billId) async {
    bool confirmDelete = await _showConfirmDialog(context);
    if (confirmDelete) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hóa đơn thành công!')),
      );
    }
  }

  /// 🛠️ Hộp thoại xác nhận xóa
  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa hóa đơn này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
