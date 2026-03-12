import 'api_service.dart';

/// Service for forgot password flow using OTP
class ForgotPasswordService {
  /// Step 1: Request OTP to phone number
  /// POST /forgot-password
  static Future<ApiResult> requestOTP(String phoneNumber) async {
    final res = await ApiService.post(
      '/forgot-password',
      body: {'utas': phoneNumber},
    );
    return res;
  }

  /// Step 2: Verify OTP and get reset token
  /// POST /verify-otp
  static Future<ApiResult> verifyOTP(String phoneNumber, String otp) async {
    final res = await ApiService.post(
      '/verify-otp',
      body: {'utas': phoneNumber, 'otp': otp},
    );
    return res;
  }

  /// Step 3: Reset password using reset token
  /// POST /reset-password
  static Future<ApiResult> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    final res = await ApiService.post(
      '/reset-password',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
    return res;
  }
}
