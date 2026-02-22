import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/order/order_model.dart';
import '../../repositories/order_repository.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  Razorpay? _razorpay;

  // Your Razorpay Test Credentials
  static const String _keyId = 'rzp_test_SHXkRbcNWvrk0G';

  // Payment state
  OrderModel? pendingOrder;
  OrderRepository? orderRepository;
  bool isPaymentInProgress = false;
  bool orderCreated = false;
  String? errorMessage;

  // Callback for UI notification
  VoidCallback? onPaymentComplete;

  void init() {
    if (_razorpay == null) {
      debugPrint('🔧 Creating new Razorpay instance...');
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      debugPrint('✅ Razorpay initialized');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🎉 PAYMENT SUCCESS!');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
    debugPrint('═══════════════════════════════════════');

    if (pendingOrder == null || orderRepository == null) {
      debugPrint('❌ ERROR: No pending order or repository!');
      errorMessage = 'Payment successful but no order data found';
      isPaymentInProgress = false;
      return;
    }

    try {
      debugPrint('📝 Creating order in Firestore...');
      await orderRepository!.createOrder(pendingOrder!);
      debugPrint('✅ Order created successfully!');
      orderCreated = true;
      errorMessage = null;
    } catch (e) {
      debugPrint('❌ Failed to create order: $e');
      errorMessage = 'Payment successful but failed to create order: $e';
      orderCreated = false;
    }

    isPaymentInProgress = false;

    // Notify UI
    debugPrint('📢 Notifying UI of payment completion...');
    onPaymentComplete?.call();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('❌ PAYMENT FAILED!');
    debugPrint('Code: ${response.code}');
    debugPrint('Message: ${response.message}');
    debugPrint('═══════════════════════════════════════');

    errorMessage = response.message ?? 'Payment failed';
    orderCreated = false;
    isPaymentInProgress = false;
    pendingOrder = null;

    // Notify UI
    onPaymentComplete?.call();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('💳 External Wallet: ${response.walletName}');
  }

  void startPayment({
    required OrderModel order,
    required OrderRepository repository,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  }) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('💳 STARTING PAYMENT');
    debugPrint('Amount: ₹$amount');
    debugPrint('Customer: $customerName');
    debugPrint('Email: $customerEmail');
    debugPrint('Phone: $customerPhone');
    debugPrint('═══════════════════════════════════════');

    // Store order data for later
    pendingOrder = order;
    orderRepository = repository;
    isPaymentInProgress = true;
    orderCreated = false;
    errorMessage = null;

    // Ensure Razorpay is initialized
    init();

    // Amount in paise (multiply by 100)
    final amountInPaise = (amount * 100).toInt();

    final options = {
      'key': _keyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'FoodSaver',
      'description': description,
      'prefill': {
        'name': customerName,
        'email': customerEmail.isNotEmpty ? customerEmail : 'customer@foodsaver.com',
        'contact': customerPhone.isNotEmpty ? customerPhone : '9999999999',
      },
      'theme': {
        'color': '#FF6B6B',
      },
    };

    debugPrint('📋 Razorpay Options: $options');

    try {
      _razorpay!.open(options);
      debugPrint('✅ Razorpay checkout opened');
    } catch (e) {
      debugPrint('❌ Error opening Razorpay: $e');
      errorMessage = 'Failed to open payment: $e';
      isPaymentInProgress = false;
    }
  }

  void reset() {
    pendingOrder = null;
    orderCreated = false;
    errorMessage = null;
    isPaymentInProgress = false;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    reset();
  }
}