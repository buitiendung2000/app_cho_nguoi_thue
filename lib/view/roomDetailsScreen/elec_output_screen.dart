import 'package:app_thue_phong/view/roomDetailsScreen/billHistoryScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ElectricityHistoryScreen extends StatefulWidget {
  const ElectricityHistoryScreen({super.key});

  @override
  State<ElectricityHistoryScreen> createState() => _ElectricityHistoryScreenState();
}

class _ElectricityHistoryScreenState extends State<ElectricityHistoryScreen> {
  // Điện
  final TextEditingController _startElectricController =
      TextEditingController();
  final TextEditingController _endElectricController = TextEditingController();
  final TextEditingController _pricePerKwController = TextEditingController();

  // Nước
  final TextEditingController _startWaterController = TextEditingController();
  final TextEditingController _endWaterController = TextEditingController();
  final TextEditingController _pricePerM3Controller = TextEditingController();

  double _electricConsumption = 0;
  double _waterConsumption = 0;
  double _electricTotal = 0;
  double _waterTotal = 0;
  double _grandTotal = 0;

  void _calculateConsumption() {
    double startElectric = double.tryParse(_startElectricController.text) ?? 0;
    double endElectric = double.tryParse(_endElectricController.text) ?? 0;
    double startWater = double.tryParse(_startWaterController.text) ?? 0;
    double endWater = double.tryParse(_endWaterController.text) ?? 0;

    setState(() {
      _electricConsumption = endElectric - startElectric;
      _waterConsumption = endWater - startWater;
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double pricePerKw = double.tryParse(_pricePerKwController.text) ?? 0;
    double pricePerM3 = double.tryParse(_pricePerM3Controller.text) ?? 0;

    setState(() {
      _electricTotal = _electricConsumption * pricePerKw;
      _waterTotal = _waterConsumption * pricePerM3;
      _grandTotal = _electricTotal + _waterTotal;
    });
  }

  /// ✅ Lưu dữ liệu vào Firestore theo số điện thoại
 Future<void> _saveDataToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final phoneNumber = user.phoneNumber;
      if (_electricConsumption <= 0 ||
          _waterConsumption <= 0 ||
          _grandTotal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dữ liệu không hợp lệ!')),
        );
        return;
      }

      final data = {
        'startElectric': double.tryParse(_startElectricController.text) ?? 0,
        'endElectric': double.tryParse(_endElectricController.text) ?? 0,
        'electricConsumption': _electricConsumption,
        'pricePerKw': double.tryParse(_pricePerKwController.text) ?? 0,
        'electricTotal': _electricTotal,
        'startWater': double.tryParse(_startWaterController.text) ?? 0,
        'endWater': double.tryParse(_endWaterController.text) ?? 0,
        'waterConsumption': _waterConsumption,
        'pricePerM3': double.tryParse(_pricePerM3Controller.text) ?? 0,
        'waterTotal': _waterTotal,
        'grandTotal': _grandTotal,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('bills')
          .add(data);

      // ✅ Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu dữ liệu thành công!')),
      );

      // ✅ Chuyển hướng sang BillHistoryScreen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillHistoryScreen(userId: phoneNumber!),
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _startElectricController.dispose();
    _endElectricController.dispose();
    _pricePerKwController.dispose();
    _startWaterController.dispose();
    _endWaterController.dispose();
    _pricePerM3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập hóa đơn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🔋 Điện
            const Text('💡 Điện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _startElectricController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số điện đầu'),
              onChanged: (value) => _calculateConsumption(),
            ),
            TextField(
              controller: _endElectricController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số điện cuối'),
              onChanged: (value) => _calculateConsumption(),
            ),
            TextField(
              controller: _pricePerKwController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá mỗi kW'),
              onChanged: (value) => _calculateTotal(),
            ),
            Text('Số điện tiêu thụ: $_electricConsumption kW'),
            Text('Tổng tiền điện: $_electricTotal VND'),

            const SizedBox(height: 16),

            // 🚰 Nước
            const Text('🚰 Nước',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _startWaterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số nước đầu'),
              onChanged: (value) => _calculateConsumption(),
            ),
            TextField(
              controller: _endWaterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số nước cuối'),
              onChanged: (value) => _calculateConsumption(),
            ),
            TextField(
              controller: _pricePerM3Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá mỗi m³'),
              onChanged: (value) => _calculateTotal(),
            ),
            Text('Số nước tiêu thụ: $_waterConsumption m³'),
            Text('Tổng tiền nước: $_waterTotal VND'),

            const SizedBox(height: 16),

            // 💰 Tổng tiền
            Text(
              'Tổng hóa đơn: $_grandTotal VND',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _saveDataToFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child:
                  const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
