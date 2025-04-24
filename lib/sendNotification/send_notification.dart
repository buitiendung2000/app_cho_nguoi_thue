import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

void main() async {
  final serviceAccountPath =
      'C:/my_project_flutter/app_thue_phong/dung60th1-b0c7b-firebase-adminsdk-4ku3w-104a94b576.json';

  final accountCredentials = ServiceAccountCredentials.fromJson(
    await File(serviceAccountPath).readAsString(),
  );

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  final authClient = await clientViaServiceAccount(accountCredentials, scopes);

  final fcmUrl =
      'https://fcm.googleapis.com/v1/projects/dung60th1-b0c7b/messages:send';

  final messagePayload = {
    'message': {
      'token': 'dyGJPyCCRJ62gTj3YncHwB:APA91bHn_zrN5erZs53OIqVjKDnhwvNP7zyYP8uTSTxQz0R2E7yFk44lj4jM_VVxOuUEWFTTYsq3s7XJ8FHDWDfdFqXBt1Piy97UIqDnM6F4Lf4bDmf-NfA', // 🔔 Thay bằng token thật
      'notification': {
        'title': 'Thanh toán phòng trọ',
        'body': 'Phòng trọ số 1 - Lựa chọn thanh toán tiền mặt',
      },
    },
  };

  final response = await authClient.post(
    Uri.parse(fcmUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(messagePayload),
  );

  if (response.statusCode == 200) {
    print('✅ Gửi thông báo thành công: ${response.body}');
  } else {
    print('❌ Gửi thất bại: ${response.statusCode} - ${response.body}');
  }

  authClient.close();
}
