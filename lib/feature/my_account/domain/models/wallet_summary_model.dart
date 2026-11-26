// ─────────────────────────────────────────────────────────────────────────────
// WalletSummaryModel
//
// Mapped from GET /api/v1/delivery-man/wallet-summary response.
// Fallback strategy: if any field is absent from the API response (null),
// MyAccountController merged getters fall back to ProfileModel equivalents.
// ─────────────────────────────────────────────────────────────────────────────

/// Safely converts bool, int 0/1, or string "true"/"1" to a nullable bool.
bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    return s == 'true' || s == '1';
  }
  return null;
}

/// Safely converts int, double, or numeric String to a nullable double.
double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

class WalletSummaryModel {
  double? payableBalance;       // "المبلغ المطلوب سداده" — banner amount
  double? withDrawableBalance;  // old "ليك" formula (kept for legacy fallback)
  double? freeDeliveryDue;      // "الفلوس اللي ليك" — card 1 (API key: free_delivery_due)
  double? adminPayable;         // "الفلوس اللي عليك" — card 2 (API key: admin_payable)
  double? cashInHands;          // raw cash the DM holds — kept for legacy fallback
  bool?   adjustable;           // controls "adjust_payments" button visibility
  bool?   showPayNowButton;     // controls "pay_now" button enabled state
  bool?   overFlowWarning;      // bottom warning bar (soft)
  bool?   overFlowBlockWarning; // bottom warning bar (hard block)

  WalletSummaryModel({
    this.payableBalance,
    this.withDrawableBalance,
    this.freeDeliveryDue,
    this.adminPayable,
    this.cashInHands,
    this.adjustable,
    this.showPayNowButton,
    this.overFlowWarning,
    this.overFlowBlockWarning,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletSummaryModel(
      payableBalance: _parseDouble(json['payable_balance'] ?? json['Payable_Balance']),
      withDrawableBalance: _parseDouble(json['withdraw_able_balance'] ?? json['withdrawable_balance']),
      freeDeliveryDue: _parseDouble(json['free_delivery_due']),
      adminPayable: _parseDouble(json['admin_payable']),
      cashInHands: _parseDouble(json['cash_in_hands'] ?? json['cash_in_hand']),
      adjustable:            _parseBool(json['adjust_able']),
      showPayNowButton:      _parseBool(json['show_pay_now_button']),
      overFlowWarning:       _parseBool(json['over_flow_warning']),
      overFlowBlockWarning:  _parseBool(json['over_flow_block_warning']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payable_balance': payableBalance,
      'withdraw_able_balance': withDrawableBalance,
      'free_delivery_due': freeDeliveryDue,
      'admin_payable': adminPayable,
      'cash_in_hands': cashInHands,
      'adjust_able': adjustable,
      'show_pay_now_button': showPayNowButton,
      'over_flow_warning': overFlowWarning,
      'over_flow_block_warning': overFlowBlockWarning,
    };
  }
}
