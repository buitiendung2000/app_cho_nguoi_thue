import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';

class UsageInputScreen extends StatefulWidget {
  const UsageInputScreen({super.key});

  @override
  State<UsageInputScreen> createState() => _UsageInputScreenState();
}

class _UsageInputScreenState extends State<UsageInputScreen> {
  String? phoneNumber;

  final _startElectricController = TextEditingController();
  final _endElectricController = TextEditingController();
  final _pricePerKwController = TextEditingController();

  final _startWaterController = TextEditingController();
  final _endWaterController = TextEditingController();
  final _pricePerM3Controller = TextEditingController();

  final _roomChargeController = TextEditingController();
  final _otherChargeController = TextEditingController();
  final _noteController = TextEditingController();

  double _electricTotal = 0;
  double _waterTotal = 0;
  double _roomCharge = 0;
  double _otherCharge = 0;
  double _grandTotal = 0;

  // ✅ Định dạng số thành chuỗi phân cách theo dấu chấm
  final _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
  }

  double _parseValue(String input) {
    return double.tryParse(input) ?? 0;
  }

  double _evaluateExpression(String input) {
    try {
      Parser p = Parser();
      Expression exp = p.parse(input);
      ContextModel cm = ContextModel();
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (_) {
      return 0;
    }
  }

  void _calculateElectricConsumption() {
    final start = _parseValue(_startElectricController.text);
    final end = _parseValue(_endElectricController.text);
    final price = _parseValue(_pricePerKwController.text);

    setState(() {
      _electricTotal = (end > start) ? (end - start) * price : 0;
      _calculateGrandTotal();
    });
  }

  void _calculateWaterConsumption() {
    final start = _parseValue(_startWaterController.text);
    final end = _parseValue(_endWaterController.text);
    final price = _parseValue(_pricePerM3Controller.text);

    setState(() {
      _waterTotal = (end > start) ? (end - start) * price : 0;
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    _roomCharge = _evaluateExpression(_roomChargeController.text);
    _otherCharge = _evaluateExpression(_otherChargeController.text);

    setState(() {
      _grandTotal = _electricTotal + _waterTotal + _roomCharge + _otherCharge;
    });
  }

  Future<void> _saveDataToFirebase() async {
    if (phoneNumber == null) return;

    if (_electricTotal <= 0 &&
        _waterTotal <= 0 &&
        _roomCharge <= 0 &&
        _otherCharge <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dữ liệu không hợp lệ!')),
      );
      return;
    }

    try {
      final billData = {
        'startElectric': _parseValue(_startElectricController.text),
        'endElectric': _parseValue(_endElectricController.text),
        'electricTotal': _electricTotal,
        'pricePerKw': _parseValue(_pricePerKwController.text),
        'startWater': _parseValue(_startWaterController.text),
        'endWater': _parseValue(_endWaterController.text),
        'waterTotal': _waterTotal,
        'pricePerM3': _parseValue(_pricePerM3Controller.text),
        'roomCharge': _roomCharge,
        'otherCharge': _otherCharge,
        'note': _noteController.text,
        'grandTotal': _grandTotal,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('bills')
          .add(billData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu dữ liệu thành công!')),
      );

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu dữ liệu: $e')),
      );
    }
  }

  void _clearFields() {
    _startElectricController.clear();
    _endElectricController.clear();
    _pricePerKwController.clear();
    _startWaterController.clear();
    _endWaterController.clear();
    _pricePerM3Controller.clear();
    _roomChargeController.clear();
    _otherChargeController.clear();
    _noteController.clear();

    setState(() {
      _electricTotal = 0;
      _waterTotal = 0;
      _roomCharge = 0;
      _otherCharge = 0;
      _grandTotal = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập thông tin sử dụng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection('🔋 Điện', [
              _buildInputField(_startElectricController, 'Số điện đầu',
                  _calculateElectricConsumption),
              _buildInputField(_endElectricController, 'Số điện cuối',
                  _calculateElectricConsumption),
              _buildInputField(_pricePerKwController, 'Giá mỗi kW',
                  _calculateElectricConsumption),
              Text('Tổng tiền điện: ${_formatter.format(_electricTotal)} đồng'),
            ]),
            _buildSection('🚰 Nước', [
              _buildInputField(_startWaterController, 'Số nước đầu',
                  _calculateWaterConsumption),
              _buildInputField(_endWaterController, 'Số nước cuối',
                  _calculateWaterConsumption),
              _buildInputField(_pricePerM3Controller, 'Giá mỗi m³',
                  _calculateWaterConsumption),
              Text('Tổng tiền nước: ${_formatter.format(_waterTotal)} đồng'),
            ]),
            _buildSection('🏠 Tiền phòng & khoản thu khác', [
              _buildInputField(
                  _roomChargeController, 'Tiền phòng', _calculateGrandTotal),
              _buildInputField(_otherChargeController, 'Khoản thu khác',
                  _calculateGrandTotal),
              _buildInputField(
                  _noteController,
                  'Ghi chú (ví dụ: Tiền rác 15.000 đồng)',
                  _calculateGrandTotal),
            ]),
            Text(
              'Tổng hóa đơn: ${_formatter.format(_grandTotal)} đồng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _saveDataToFirebase,
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, VoidCallback onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        onChanged: (value) => onChanged(),
      ),
    );
  }
}
