import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';

void main() async {
  final accountCredentials = ServiceAccountCredentials.fromJson(
    File(
      'C:/my_project_flutter/app_thue_phong/dung60th1-b0c7b-firebase-adminsdk-4ku3w-104a94b576.json',
    ).readAsStringSync(),
  );

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  final client = await clientViaServiceAccount(accountCredentials, scopes);
  final accessToken = client.credentials.accessToken.data;

  print('Bearer Token: $accessToken');
  client.close();
}
