import 'package:stackfood_multivendor_driver/common/models/response_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_summary_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/withdraw_list_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/repositories/my_account_repository_interface.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/services/my_account_service_interface.dart';

class MyAccountService implements MyAccountServiceInterface {
  final MyAccountRepositoryInterface myAccountRepositoryInterface;
  MyAccountService({required this.myAccountRepositoryInterface});

  @override
  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName) async {
    return await myAccountRepositoryInterface.makeCollectCashPayment(amount, paymentGatewayName);
  }

  @override
  Future<ResponseModel> makeWalletAdjustment() async {
    return await myAccountRepositoryInterface.makeWalletAdjustment();
  }

  @override
  Future<WalletSummaryModel?> getWalletSummary() async {
    return await myAccountRepositoryInterface.getWalletSummary();
  }

  @override
  Future<WalletPaymentModel?> getWalletPaymentList({
    String? from,
    String? to,
    int limit = 10,
    int offset = 1,
  }) async {
    return await myAccountRepositoryInterface.getWalletPaymentList(
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<WithdrawListModel?> getWithdrawList({
    String? from,
    String? to,
    int limit = 10,
    int offset = 1,
  }) async {
    return await myAccountRepositoryInterface.getWithdrawList(
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }

}