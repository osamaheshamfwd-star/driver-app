import 'package:flutter/foundation.dart';
import 'package:stackfood_multivendor_driver/common/models/response_model.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_summary_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/withdraw_list_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/services/my_account_service_interface.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';

class MyAccountController extends GetxController implements GetxService {
  final MyAccountServiceInterface myAccountServiceInterface;
  MyAccountController({required this.myAccountServiceInterface});

  // ── General action loading ────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── wallet-summary state ──────────────────────────────────────────────────

  WalletSummaryModel? _walletSummary;
  WalletSummaryModel? get walletSummary => _walletSummary;

  bool _summaryLoading = false;
  bool get summaryLoading => _summaryLoading;

  bool _summaryError = false;
  bool get summaryError => _summaryError;

  // ── Tab 1 — wallet-payment-list state ────────────────────────────────────

  WalletPaymentModel? _paymentListModel;
  WalletPaymentModel? get paymentListModel => _paymentListModel;

  List<Transactions> _paymentList = [];
  List<Transactions> get paymentList => _paymentList;

  bool _paymentListLoading = false;
  bool get paymentListLoading => _paymentListLoading;

  bool _paymentListError = false;
  bool get paymentListError => _paymentListError;

  bool _paymentListLoadingMore = false;
  bool get paymentListLoadingMore => _paymentListLoadingMore;

  DateTime? _tab1From;
  DateTime? _tab1To;
  DateTime? get tab1From => _tab1From;
  DateTime? get tab1To => _tab1To;

  int _paymentOffset = 1;
  static const int _pageSize = 10;

  // ── Tab 2 — withdraw-list state ───────────────────────────────────────────

  WithdrawListModel? _withdrawListModel;
  WithdrawListModel? get withdrawListModel => _withdrawListModel;

  List<WithdrawRequest> _withdrawList = [];
  List<WithdrawRequest> get withdrawList => _withdrawList;

  bool _withdrawListLoading = false;
  bool get withdrawListLoading => _withdrawListLoading;

  bool _withdrawListError = false;
  bool get withdrawListError => _withdrawListError;

  bool _withdrawListLoadingMore = false;
  bool get withdrawListLoadingMore => _withdrawListLoadingMore;

  DateTime? _tab2From;
  DateTime? _tab2To;
  DateTime? get tab2From => _tab2From;
  DateTime? get tab2To => _tab2To;

  int _withdrawOffset = 1;

  // ── Payment flow state ────────────────────────────────────────────────────

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  int _paymentIndex = 0;
  int get paymentIndex => _paymentIndex;

  // ── Initialisation (called from screen initState) ─────────────────────────

  Future<void> initWalletData() async {
    await Future.wait([
      getWalletSummary(),
      fetchPaymentList(reset: true),
      fetchWithdrawList(reset: true),
    ]);
    // ── DIAGNOSTIC: showPayNowButton fallback chain ───────────────────────────
    final profileModel = Get.find<ProfileController>().profileModel;
    debugPrint('[pay_now] _walletSummary is null? ${_walletSummary == null}');
    debugPrint('[pay_now] _walletSummary.showPayNowButton=${_walletSummary?.showPayNowButton}');
    debugPrint('[pay_now] profileModel is null? ${profileModel == null}');
    debugPrint('[pay_now] profileModel.showPayNowButton raw=${profileModel?.showPayNowButton}  type=${profileModel?.showPayNowButton.runtimeType}');
    debugPrint('[pay_now] ctrl.showPayNowButton (resolved getter)=$showPayNowButton');
    // ─────────────────────────────────────────────────────────────────────────
  }

  // ── wallet-summary ────────────────────────────────────────────────────────

  Future<void> getWalletSummary() async {
    _summaryLoading = true;
    _summaryError = false;
    update();
    try {
      final model = await myAccountServiceInterface.getWalletSummary();
      if (model != null) {
        _walletSummary = model;
        _summaryError = false;
      } else {
        _summaryError = true;
      }
    } catch (_) {
      _summaryError = true;
    }
    _summaryLoading = false;
    update();
  }

  // ── wallet-payment-list (Tab 1) ───────────────────────────────────────────

  Future<void> fetchPaymentList({bool reset = false}) async {
    if (reset) {
      _paymentOffset = 1;
      _paymentList = [];
      _paymentListModel = null;
      _paymentListError = false;
    }
    if (_paymentOffset == 1) {
      _paymentListLoading = true;
    } else {
      _paymentListLoadingMore = true;
    }
    update();
    try {
      final model = await myAccountServiceInterface.getWalletPaymentList(
        from: _tab1From != null ? _formatDate(_tab1From!) : null,
        to: _tab1To != null ? _formatDate(_tab1To!) : null,
        limit: _pageSize,
        offset: _paymentOffset,
      );
      if (model != null) {
        _paymentListModel = model;
        _paymentList.addAll(model.transactions ?? []);
        _paymentListError = false;
      } else {
        _paymentListError = _paymentOffset == 1;
      }
    } catch (_) {
      _paymentListError = _paymentOffset == 1;
    }
    _paymentListLoading = false;
    _paymentListLoadingMore = false;
    update();
  }

  Future<void> loadMorePayments() async {
    final total = _paymentListModel?.totalSize ?? 0;
    if (_paymentList.length >= total || _paymentListLoadingMore) return;
    _paymentOffset++;
    await fetchPaymentList();
  }

  void setTab1DateRange(DateTime? from, DateTime? to) {
    _tab1From = from;
    _tab1To = to;
    fetchPaymentList(reset: true);
  }

  void clearTab1DateFilter() => setTab1DateRange(null, null);

  // ── get-withdraw-list (Tab 2) ─────────────────────────────────────────────

  Future<void> fetchWithdrawList({bool reset = false}) async {
    if (reset) {
      _withdrawOffset = 1;
      _withdrawList = [];
      _withdrawListModel = null;
      _withdrawListError = false;
    }
    if (_withdrawOffset == 1) {
      _withdrawListLoading = true;
    } else {
      _withdrawListLoadingMore = true;
    }
    update();
    try {
      final model = await myAccountServiceInterface.getWithdrawList(
        from: _tab2From != null ? _formatDate(_tab2From!) : null,
        to: _tab2To != null ? _formatDate(_tab2To!) : null,
        limit: _pageSize,
        offset: _withdrawOffset,
      );
      if (model != null) {
        _withdrawListModel = model;
        _withdrawList.addAll(model.requests ?? []);
        _withdrawListError = false;
      } else {
        _withdrawListError = _withdrawOffset == 1;
      }
    } catch (_) {
      _withdrawListError = _withdrawOffset == 1;
    }
    _withdrawListLoading = false;
    _withdrawListLoadingMore = false;
    update();
  }

  Future<void> loadMoreWithdraws() async {
    final total = _withdrawListModel?.totalSize ?? 0;
    if (_withdrawList.length >= total || _withdrawListLoadingMore) return;
    _withdrawOffset++;
    await fetchWithdrawList();
  }

  void setTab2DateRange(DateTime? from, DateTime? to) {
    _tab2From = from;
    _tab2To = to;
    fetchWithdrawList(reset: true);
  }

  void clearTab2DateFilter() => setTab2DateRange(null, null);

  // ── Payment actions ───────────────────────────────────────────────────────

  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await myAccountServiceInterface.makeCollectCashPayment(amount, paymentGatewayName);
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> makeWalletAdjustment() async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await myAccountServiceInterface.makeWalletAdjustment();
    if(responseModel.isSuccess) {
      await Get.find<ProfileController>().getProfile();
      await getWalletSummary(); // refresh banner after adjustment
      Get.back();
      showCustomSnackBar(responseModel.message, isError: false);
    }else{
      Get.back();
      showCustomSnackBar(responseModel.message, isError: true);
    }
    _isLoading = false;
    update();
  }

  // ── Payment method selection ──────────────────────────────────────────────

  void setPaymentIndex(int index){
    _paymentIndex = index;
    update();
  }

  void changeDigitalPaymentName(String? name, {bool canUpdate = true}){
    _digitalPaymentName = name;
    if(canUpdate) {
      update();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Format DateTime → 'yyyy-MM-dd' for API query params.
  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // ── Convenience getters — fall back to ProfileModel when summary is null ──
  //
  // These are used by the screen so it doesn't need to know where data comes from.

  double? get payableBalance =>
      _walletSummary?.payableBalance
      ?? Get.find<ProfileController>().profileModel?.payableBalance;

  double? get withDrawableBalance =>
      _walletSummary?.withDrawableBalance
      ?? Get.find<ProfileController>().profileModel?.withDrawableBalance;

  /// Amount the delivery man owes admin — displayed in "الفلوس اللي عليك".
  /// Sourced exclusively from wallet-summary → admin_payable.
  /// No ProfileModel fallback (ProfileModel has no equivalent field).
  double? get adminPayable => _walletSummary?.adminPayable;

  /// Amount the app owes the delivery man — displayed in "الفلوس اللي ليك".
  /// Sourced exclusively from wallet-summary → free_delivery_due.
  double? get freeDeliveryDue => _walletSummary?.freeDeliveryDue;

  /// Net amount the delivery man owes the app (service fees minus free-delivery
  /// compensation). Negative means the app owes the delivery man.
  double get netDue => (adminPayable ?? 0) - (freeDeliveryDue ?? 0);

  /// Raw cash the DM physically holds (cash_in_hands from profile/wallet-summary).
  /// NOT the same as adminPayable — kept for other consumers (e.g. home screen overflow check).
  double? get cashInHands =>
      _walletSummary?.cashInHands
      ?? Get.find<ProfileController>().profileModel?.cashInHands;

  bool get adjustable =>
      _walletSummary?.adjustable
      ?? Get.find<ProfileController>().profileModel?.adjustable
      ?? false;

  bool get showPayNowButton =>
      _walletSummary?.showPayNowButton
      ?? Get.find<ProfileController>().profileModel?.showPayNowButton
      ?? false;

  bool get overFlowWarning =>
      _walletSummary?.overFlowWarning
      ?? Get.find<ProfileController>().profileModel?.overFlowWarning
      ?? false;

  bool get overFlowBlockWarning =>
      _walletSummary?.overFlowBlockWarning
      ?? Get.find<ProfileController>().profileModel?.overFlowBlockWarning
      ?? false;
}
