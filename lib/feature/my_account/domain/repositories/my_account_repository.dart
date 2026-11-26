import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfood_multivendor_driver/common/models/response_model.dart';
import 'package:stackfood_multivendor_driver/api/api_client.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_summary_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/withdraw_list_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/repositories/my_account_repository_interface.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/app_constants.dart';

class MyAccountRepository implements MyAccountRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  MyAccountRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName) async {
    ResponseModel responseModel;
    Response response = await apiClient.postData(AppConstants.makeCollectedCashPaymentUri, {
      "amount": amount,
      "payment_gateway": paymentGatewayName,
      "callback": RouteHelper.success,
      "token": _getUserToken(),
    });
    if (response.statusCode == 200) {
      String redirectUrl = response.body['redirect_link'];
      Get.back();
      if(GetPlatform.isWeb) {
        // html.window.open(redirectUrl,"_self");
      } else{
        Get.toNamed(RouteHelper.getPaymentRoute(redirectUrl));
      }
      responseModel = ResponseModel(true, response.body.toString());
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future<ResponseModel> makeWalletAdjustment() async {
    ResponseModel responseModel;
    Response response = await apiClient.postData(AppConstants.makeWalletAdjustmentUri, {'token': _getUserToken()}, handleError: false);
    if(response.statusCode == 200) {
      responseModel = ResponseModel(true, 'wallet_adjustment_successfully'.tr);
    }else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  // ── wallet-summary ────────────────────────────────────────────────────────

  @override
  Future<WalletSummaryModel?> getWalletSummary() async {
    WalletSummaryModel? model;
    Response response = await apiClient.getData(
      '${AppConstants.walletSummaryUri}?token=${_getUserToken()}',
    );
    // ── DIAGNOSTIC LOG ───────────────────────────────────────────────────────
    debugPrint('[wallet-summary] status=${response.statusCode}');
    if (response.body is Map) {
      final m = response.body as Map;
      // ── FULL RAW JSON (copy this entire line from the terminal) ──────────
      try {
        debugPrint('[wallet-summary] FULL_RAW_JSON=${m.toString()}');
      } catch (_) {}
      // ── All top-level keys present in the response ───────────────────────
      debugPrint('[wallet-summary] keys=${m.keys.toList()}');
      // ── Existing fields ──────────────────────────────────────────────────
      debugPrint('[wallet-summary] show_pay_now_button   raw=${m['show_pay_now_button']}   type=${m['show_pay_now_button'].runtimeType}');
      debugPrint('[wallet-summary] adjust_able           raw=${m['adjust_able']}           type=${m['adjust_able'].runtimeType}');
      debugPrint('[wallet-summary] over_flow_warning     raw=${m['over_flow_warning']}     type=${m['over_flow_warning'].runtimeType}');
      debugPrint('[wallet-summary] over_flow_block_warning raw=${m['over_flow_block_warning']} type=${m['over_flow_block_warning'].runtimeType}');
      debugPrint('[wallet-summary] payable_balance       raw=${m['payable_balance']}       type=${m['payable_balance'].runtimeType}');
      // ── CRITICAL: fields for "الفلوس اللي عليك" (dues card) ─────────────
      debugPrint('[wallet-summary] cash_in_hands         raw=${m['cash_in_hands']}         type=${m['cash_in_hands'].runtimeType}');
      debugPrint('[wallet-summary] cash_in_hand          raw=${m['cash_in_hand']}          type=${m['cash_in_hand'].runtimeType}');
      // ── CRITICAL: fields for "الفلوس اللي ليك" (earnings card) ──────────
      debugPrint('[wallet-summary] withdraw_able_balance raw=${m['withdraw_able_balance']} type=${m['withdraw_able_balance'].runtimeType}');
      debugPrint('[wallet-summary] withdrawable_balance  raw=${m['withdrawable_balance']}  type=${m['withdrawable_balance'].runtimeType}');
      // ── Probe for service_fee / admin_commission / commission fields ──────
      debugPrint('[wallet-summary] service_fee           raw=${m['service_fee']}           (${m['service_fee'].runtimeType})');
      debugPrint('[wallet-summary] admin_commission      raw=${m['admin_commission']}      (${m['admin_commission'].runtimeType})');
      debugPrint('[wallet-summary] commission            raw=${m['commission']}            (${m['commission'].runtimeType})');
      debugPrint('[wallet-summary] commission_rate       raw=${m['commission_rate']}       (${m['commission_rate'].runtimeType})');
    } else {
      debugPrint('[wallet-summary] body type=${response.body.runtimeType}  body=${response.body}');
    }
    // ────────────────────────────────────────────────────────────────────────
    if (response.statusCode == 200) {
      try {
        model = WalletSummaryModel.fromJson(response.body as Map<String, dynamic>);
        debugPrint('[wallet-summary] parse OK — showPayNowButton=${model.showPayNowButton}  adjustable=${model.adjustable}');
      } catch (e, st) {
        debugPrint('[wallet-summary] *** fromJson THREW: $e');
        debugPrint('[wallet-summary] *** stacktrace: $st');
        // Leave model null — controller falls back to ProfileModel.
      }
    }
    return model;
  }

  // ── wallet-payment-list ───────────────────────────────────────────────────

  @override
  Future<WalletPaymentModel?> getWalletPaymentList({
    String? from,
    String? to,
    int limit = 10,
    int offset = 1,
  }) async {
    WalletPaymentModel? model;
    final StringBuffer url = StringBuffer(AppConstants.walletPaymentListUri);
    url.write('?token=${_getUserToken()}&limit=$limit&offset=$offset');
    if (from != null && from.isNotEmpty) url.write('&from=$from');
    if (to != null && to.isNotEmpty) url.write('&to=$to');
    Response response = await apiClient.getData(url.toString());
    // ── DIAGNOSTIC LOG ───────────────────────────────────────────────────────
    debugPrint('[wallet-payment-list] status=${response.statusCode}');
    if (response.body is Map) {
      final bodyMap = response.body as Map;
      debugPrint('[wallet-payment-list] keys=${bodyMap.keys.toList()}');
      debugPrint('[wallet-payment-list] total_size=${bodyMap['total_size']} (${bodyMap['total_size'].runtimeType})');
      debugPrint('[wallet-payment-list] limit=${bodyMap['limit']} (${bodyMap['limit'].runtimeType})');
      debugPrint('[wallet-payment-list] offset=${bodyMap['offset']} (${bodyMap['offset'].runtimeType})');
      final txRaw = bodyMap['transactions'];
      debugPrint('[wallet-payment-list] transactions type=${txRaw.runtimeType}, count=${txRaw is List ? txRaw.length : "n/a"}');
    } else {
      debugPrint('[wallet-payment-list] body type=${response.body.runtimeType}');
      debugPrint('[wallet-payment-list] body=${response.body}');
    }
    // ────────────────────────────────────────────────────────────────────────
    if (response.statusCode == 200) {
      try {
        model = WalletPaymentModel.fromJson(response.body as Map<String, dynamic>);
        debugPrint('[wallet-payment-list] parse OK — ${model.transactions?.length ?? 0} items');
      } catch (e, st) {
        // Should no longer reach here after _parseInt fix in WalletPaymentModel.
        // Kept as a safety net: log and return empty model rather than propagating.
        debugPrint('[wallet-payment-list] *** fromJson THREW (unexpected): $e');
        debugPrint('[wallet-payment-list] *** stacktrace: $st');
        model = WalletPaymentModel(totalSize: 0, limit: 10, offset: 1, transactions: []);
      }
    }
    return model;
  }

  // ── get-withdraw-list ─────────────────────────────────────────────────────

  @override
  Future<WithdrawListModel?> getWithdrawList({
    String? from,
    String? to,
    int limit = 10,
    int offset = 1,
  }) async {
    WithdrawListModel? model;
    final StringBuffer url = StringBuffer(AppConstants.getWithdrawListUri);
    url.write('?token=${_getUserToken()}&limit=$limit&offset=$offset');
    if (from != null && from.isNotEmpty) url.write('&from=$from');
    if (to != null && to.isNotEmpty) url.write('&to=$to');
    Response response = await apiClient.getData(url.toString());
    if (response.statusCode == 200) {
      model = WithdrawListModel.fromJson(response.body as Map<String, dynamic>);
    }
    return model;
  }

  String _getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  // ── RepositoryInterface stubs ─────────────────────────────────────────────

  @override
  Future<List<Transactions>?> getList() async {
    // Legacy stub kept for interface compliance — use getWalletPaymentList() instead.
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future get(int id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

}