import 'package:app_thue_phong/view/authScreen/emailScreen.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../controller/provider/authProvider/mobileAuthProvider.dart';
import '../../controller/services/authServices/mobileAuthServices.dart';
import '../../utils/colors.dart';
import '../../utils/textStyles.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  String selectedCountry = '+84';
  final TextEditingController mobileController = TextEditingController();
  bool receiveOTPButtonPressed = false;

  @override
  void initState() {
    super.initState();
    // Nếu có logic nào cần thực hiện sau lần build đầu tiên thì có thể sử dụng addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        receiveOTPButtonPressed = false;
      });
    });
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
  return SafeArea(
    child: Scaffold(
      body: Container(
          width: double.infinity,
          height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)], // Gradient nền tươi sáng
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Logo và tiêu đề
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.home_work_rounded,
                        size: 8.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Chào mừng đến với App Phòng Trọ!',
                        style: AppTextStyles.body16.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),

                /// Nhập số điện thoại
                Text(
                  'Nhập số điện thoại của bạn',
                  style: AppTextStyles.body16.copyWith(color: Colors.white),
                ),
                SizedBox(height: 3.h),

                /// Chọn quốc gia và nhập số điện thoại
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (Country country) {
                            setState(() {
                              selectedCountry = '+${country.phoneCode}';
                            });
                          },
                        );
                      },
                      child: Container(
                        height: 6.h,
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedCountry,
                          style: AppTextStyles.body14.copyWith(color: black),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.textFieldTextStyle,
                        cursorColor: Colors.orangeAccent,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Số điện thoại',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orangeAccent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepOrange),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                /// Nút Tiếp theo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        receiveOTPButtonPressed = true;
                      });
                      final fullPhone =
                          '$selectedCountry${mobileController.text.trim()}';
                      context
                          .read<MobileAuthProvider>()
                          .updateMobileNumber(fullPhone);
                      MobileAuthServices.receiveOTP(
                        context: context,
                        mobileNo: fullPhone,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: receiveOTPButtonPressed
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tiếp theo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 3.h),

                /// Thông báo dưới về điều khoản
                Text(
                  'Bằng cách tiếp tục, bạn đồng ý nhận cuộc gọi, tin nhắn Whatsapp hoặc SMS từ Uber và các chi nhánh.',
                  style: AppTextStyles.small12.copyWith(color: Colors.white70),
                ),
                SizedBox(height: 2.h),

                /// Divider với từ "hoặc"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white70)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Text(
                        'hoặc',
                        style: AppTextStyles.small12.copyWith(color: Colors.white70),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white70)),
                  ],
                ),
                SizedBox(height: 2.h),

                /// Đăng nhập với Google
                ElevatedButton.icon(
                  onPressed: () {
                    // Thêm logic đăng nhập với Google ở đây
                  },
                  icon: FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.deepOrange,
                    size: 3.h,
                  ),
                  label: Text(
                    'Đăng nhập với Google',
                    style: AppTextStyles.body16.copyWith(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.deepOrangeAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}




 
