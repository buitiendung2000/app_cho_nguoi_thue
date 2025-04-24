import 'package:flutter/material.dart';

class GeneralRulesScreen extends StatelessWidget {
  const GeneralRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quy định chung'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.cleaning_services,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    '1. Quy định về vệ sinh phòng trọ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Người thuê trọ cần giữ gìn vệ sinh cá nhân và chung, dọn dẹp khu vực sinh hoạt, không vứt rác bừa bãi, hạn chế sử dụng các chất gây ô nhiễm môi trường.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.access_time,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    '2. Quy định về giờ giấc',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Người thuê trọ cần tuân thủ giờ giấc chung của khu trọ, tránh gây ồn ào sau 22:00 nhằm đảm bảo môi trường sống yên tĩnh cho tất cả mọi người.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.security, color: Colors.blueAccent),
                  title: const Text(
                    '3. Quy định về an ninh và trật tự',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Người thuê trọ cần giữ gìn an ninh, không cho người lạ vào khu trọ, khóa cửa cẩn thận và báo ngay cho quản lý khi có dấu hiệu bất thường.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.home_repair_service,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    '4. Quy định về bảo quản tài sản',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Người thuê trọ có trách nhiệm bảo quản tài sản của mình, không gây hư hại cho tài sản chung của khu trọ. Mọi hư hại do sơ suất cá nhân sẽ phải bồi thường theo quy định.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.payment, color: Colors.blueAccent),
                  title: const Text(
                    '5. Quy định về thanh toán',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Tiền thuê và các khoản dịch vụ cần được thanh toán đúng hạn theo hợp đồng. Việc chậm thanh toán có thể dẫn đến các biện pháp xử lý theo quy định của chủ trọ.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
