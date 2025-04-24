import 'package:app_thue_phong/view/GuideScreen/onBoardingScreen.dart';
import 'package:flutter/material.dart';

class RulesScreen extends StatefulWidget {
  @override
  _RulesScreenState createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool isAgreed = false;
  bool hasScrolledToEnd = false;
  final ScrollController _scrollController = ScrollController();

  final String rulesContent = ''' 
I. Giới thiệu chung
Mục tiêu: Nội quy này được xây dựng với mục đích đảm bảo an ninh, trật tự và vệ sinh chung, tạo điều kiện thuận lợi cho một cuộc sống cộng đồng hòa thuận và trật tự.

Phạm vi áp dụng: Các quy định áp dụng đối với tất cả các khách thuê, người đại diện và khách đến thăm khu trọ.

II. Quy định về nhận – trả phòng và đăng ký
Quy trình nhận phòng:
- Khách thuê cần hoàn tất thủ tục đăng ký, cung cấp thông tin cá nhân chính xác và ký hợp đồng thuê phòng.
- Thời gian nhận phòng sẽ được thông báo cụ thể và bắt đầu theo giờ làm việc của ban quản lý.

Quy trình trả phòng:
- Khách thuê phải thông báo cho ban quản lý ít nhất 03 ngày trước khi rời khỏi.
- Phòng thuê phải được dọn dẹp sạch sẽ, không còn hư hại (nếu có, sẽ được tính phí sửa chữa).

III. An ninh và trật tự
Ra vào – ra khỏi khu trọ:
- Mỗi khách thuê được cấp thẻ ra vào cá nhân, không được chuyển giao, sao chép sang người khác.
- Các khách mời cần đăng ký với ban quản lý và chỉ được phép lưu trú tối đa theo quy định (đối với khách qua đêm, phải được sự đồng ý của ban quản lý).

Giờ giấc yên tĩnh:
- Từ 22:00 đến 06:00, mọi hoạt động cần giữ yên lặng để không làm ảnh hưởng đến cuộc sống của các khách thuê khác.

Quản lý an ninh:
- Hệ thống camera giám sát được lắp đặt tại các khu vực chung. Mọi hành vi vi phạm an ninh hoặc gây mất trật tự sẽ bị xử lý nghiêm khắc.

IV. Vệ sinh và bảo quản không gian chung
Dọn dẹp cá nhân:
- Mỗi khách thuê có trách nhiệm giữ gìn vệ sinh phòng ở và khu vực xung quanh chỗ ở của mình.
- Không để đồ đạc cá nhân rác thải hay bừa bộn ngoài khu vực phòng.

Khu vực chung:
- Các khu vực như hành lang, sảnh, nhà bếp và phòng sinh hoạt chung phải được bảo quản sạch sẽ.
- Rác thải phải được vứt đúng nơi quy định và theo lịch thu gom của khu trọ.

Bảo quản thiết bị chung:
- Các thiết bị, đồ dùng chung như đèn điện, máy lạnh, quạt, tủ lạnh… phải được sử dụng đúng mục đích và bảo quản cẩn thận.
- Mọi hư hỏng do sử dụng sai mục đích sẽ được xử lý theo quy định, có thể tính phí sửa chữa hoặc thay thế.

V. Sử dụng thiết bị và tiện nghi
Tiện ích sử dụng chung:
- Khách thuê vui lòng sử dụng thiết bị chung một cách có trách nhiệm, không gây tổn thất hay hư hỏng.
- Mọi sự cố cần được báo cáo ngay với ban quản lý để có biện pháp xử lý kịp thời.

Giới hạn khách qua đêm:
- Mỗi phòng chỉ được phép có tối đa 2 khách qua đêm nếu có sự đồng ý của ban quản lý.
- Khách mời phải tuân thủ các quy định liên quan đến an ninh và vệ sinh chung.

VI. Quy định về vi phạm và xử lý
Xử phạt vi phạm:
- Các hành vi vi phạm nội quy sẽ được ghi nhận và xử lý theo mức độ nghiêm trọng: cảnh cáo, phạt tiền, tạm đình chỉ quyền sử dụng phòng, hoặc chấm dứt hợp đồng thuê phòng.
- Trường hợp vi phạm nghiêm trọng, ảnh hưởng đến an ninh và trật tự chung, ban quản lý có quyền yêu cầu khách thuê rời khỏi khu trọ ngay lập tức.

Thủ tục giải quyết vi phạm:
- Mỗi trường hợp vi phạm sẽ được xem xét và xử lý thông qua quy trình báo cáo, thẩm định của ban quản lý.
- Khách thuê có quyền phản ánh và đề nghị giải trình nếu cảm thấy bị xử lý không công bằng.

VII. Liên hệ và hỗ trợ
Thông tin liên hệ:
- Khách thuê cần lưu lại số điện thoại của ban quản lý để liên hệ khi cần hỗ trợ hoặc báo cáo sự cố.
- Các thắc mắc hoặc góp ý về nội quy, dịch vụ sẽ được tiếp nhận và giải đáp trong thời gian sớm nhất.

Phản ánh sự cố:
- Các sự cố khẩn cấp (đời sống, an ninh, hỏa hoại…) cần được thông báo ngay lập tức cho ban quản lý hoặc liên hệ số điện thoại khẩn cấp được thông báo tại khu trọ.
''';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent - 10 &&
          !_scrollController.position.outOfRange) {
        if (!hasScrolledToEnd) {
          setState(() {
            hasScrolledToEnd = true;
          });
        }
      } else {
        if (hasScrolledToEnd) {
          setState(() {
            hasScrolledToEnd = false;
            isAgreed = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quy định phòng trọ"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Text(
                        rulesContent,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasScrolledToEnd ? Colors.green[50] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isAgreed,
                    onChanged:
                        hasScrolledToEnd
                            ? (bool? value) {
                              setState(() {
                                isAgreed = value ?? false;
                              });
                            }
                            : null,
                  ),
                  Expanded(
                    child: Text(
                      "Tôi đồng ý các quy định phòng trọ đưa ra",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isAgreed
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OnboardingScreen(),
                            ),
                          );
                        }
                        : null,
                child: Text("Tiếp tục"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
