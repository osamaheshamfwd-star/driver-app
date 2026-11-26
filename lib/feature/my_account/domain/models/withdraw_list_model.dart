// ─────────────────────────────────────────────────────────────────────────────
// WithdrawListModel + WithdrawRequest
//
// Mapped from GET /api/v1/delivery-man/get-withdraw-list response.
// Follows the same paginated envelope pattern used by WalletPaymentModel and
// DisbursementReportModel.
//
// Status values: "pending" | "approved" | "denied"
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawListModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<WithdrawRequest>? requests;

  WithdrawListModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.requests,
  });

  factory WithdrawListModel.fromJson(Map<String, dynamic> json) {
    List<WithdrawRequest>? requests;
    // API may key the list as "withdraw_requests", "data", or "withdraws".
    final raw = json['withdraw_requests'] ?? json['data'] ?? json['withdraws'];
    if (raw != null) {
      requests = (raw as List)
          .map((item) => WithdrawRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return WithdrawListModel(
      totalSize: json['total_size'] as int?,
      limit: json['limit'] is int
          ? json['limit'] as int?
          : int.tryParse(json['limit']?.toString() ?? ''),
      offset: json['offset'] is int
          ? json['offset'] as int?
          : int.tryParse(json['offset']?.toString() ?? ''),
      requests: requests,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'total_size': totalSize,
      'limit': limit,
      'offset': offset,
    };
    if (requests != null) {
      data['withdraw_requests'] = requests!.map((r) => r.toJson()).toList();
    }
    return data;
  }
}

class WithdrawRequest {
  int?    id;
  double? amount;
  /// Status string — one of: "pending", "approved", "denied"
  String? status;
  String? createdAt;
  String? updatedAt;
  String? ref;

  WithdrawRequest({
    this.id,
    this.amount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  factory WithdrawRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawRequest(
      id: json['id'] as int?,
      // Accept "amount", "withdraw_amount", or "disbursement_amount"
      amount: (json['amount'] ?? json['withdraw_amount'] ?? json['disbursement_amount'])
          ?.toDouble(),
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      ref: json['ref'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'ref': ref,
    };
  }
}
