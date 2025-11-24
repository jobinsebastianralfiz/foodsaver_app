import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;

  // Test Mode Credentials
  static const String testKeyId = 'rzp_test_1DP5mmOlF5G5ag'; // Test key

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  /// Opens Razorpay checkout
  ///
  /// [amount] - Amount in rupees (will be converted to paise internally)
  /// [orderId] - Your order ID for reference
  /// [name] - Customer name
  /// [email] - Customer email
  /// [phone] - Customer phone number
  /// [description] - Order description
  void openCheckout({
    required double amount,
    required String orderId,
    required String name,
    required String email,
    required String phone,
    required String description,
  }) {
    // Convert amount to paise (Razorpay expects amount in smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': testKeyId,
      'amount': amountInPaise,
      'name': 'FoodSaver',
      'description': description,
      'order_id': orderId, // Your order ID
      'prefill': {
        'contact': phone,
        'email': email,
        'name': name,
      },
      'theme': {
        'color': '#FF6B6B', // Your app's primary color
      },
      'modal': {
        'ondismiss': () {
          debugPrint('Payment dismissed');
        }
      },
      // Test mode settings
      'notes': {
        'mode': 'test',
        'order_id': orderId,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}