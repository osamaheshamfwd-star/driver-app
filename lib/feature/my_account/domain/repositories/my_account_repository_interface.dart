import 'package:stackfood_multivendor_driver/interface/repository_interface.dart';

abstract class MyAccountRepositoryInterface implements RepositoryInterface {
  Future<dynamic> makeCollectCashPayment(double amount, String paymentGatewayName);
  Future<dynamic> makeWalletAdjustment();
  Future<dynamic> getWalletSummary();
  Future<dynamic> getWalletPaymentList({String? from, String? to, int limit, int offset});
  Future<dynamic> getWithdrawList({String? from, String? to, int limit, int offset});
}