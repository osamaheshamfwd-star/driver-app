import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_summary_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/withdraw_list_model.dart';

abstract class MyAccountServiceInterface {
  Future<dynamic> makeCollectCashPayment(double amount, String paymentGatewayName);
  Future<dynamic> makeWalletAdjustment();
  Future<WalletSummaryModel?> getWalletSummary();
  Future<WalletPaymentModel?> getWalletPaymentList({String? from, String? to, int limit, int offset});
  Future<WithdrawListModel?> getWithdrawList({String? from, String? to, int limit, int offset});
}