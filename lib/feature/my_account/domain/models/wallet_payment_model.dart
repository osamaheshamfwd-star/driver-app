// ─────────────────────────────────────────────────────────────────────────────
// Safely parse a dynamic value as int?.
//
// Laravel (and some other PHP backends) occasionally encodes numeric
// pagination fields as JSON strings (e.g. "limit": "10", "offset": "1").
// A plain `json['limit'] as int?` will throw
//   type 'String' is not a subtype of type 'int?'
// in that case.  This helper accepts int, double, or String and returns null
// only when the raw value itself is null or unparseable.
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

class WalletPaymentModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Transactions>? transactions;

  WalletPaymentModel({this.totalSize, this.limit, this.offset, this.transactions});

  WalletPaymentModel.fromJson(Map<String, dynamic> json) {
    totalSize    = _parseInt(json['total_size']);
    limit        = _parseInt(json['limit']);
    offset       = _parseInt(json['offset']);
    if (json['transactions'] != null) {
      transactions = <Transactions>[];
      json['transactions'].forEach((v) {
        transactions!.add(Transactions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size']    = totalSize;
    data['limit']         = limit;
    data['offset']        = offset;
    if (transactions != null) {
      data['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Transactions {
  int?    id;
  String? fromType;
  int?    fromId;
  double? currentBalance;
  double? amount;
  String? method;
  String? ref;
  String? createdAt;
  String? updatedAt;
  String? type;
  String? createdBy;
  String? paymentMethod;
  String? status;
  String? paymentTime;

  Transactions({
    this.id,
    this.fromType,
    this.fromId,
    this.currentBalance,
    this.amount,
    this.method,
    this.ref,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.createdBy,
    this.paymentMethod,
    this.status,
    this.paymentTime,
  });

  Transactions.fromJson(Map<String, dynamic> json) {
    id             = _parseInt(json['id']);
    fromType       = json['from_type'];
    fromId         = _parseInt(json['from_id']);
    currentBalance = json['current_balance']?.toDouble();
    amount         = json['amount']?.toDouble();
    method         = json['method'];
    ref            = json['ref'];
    createdAt      = json['created_at'];
    updatedAt      = json['updated_at'];
    type           = json['type'];
    createdBy      = json['created_by'];
    paymentMethod  = json['payment_method'];
    status         = json['status'];
    paymentTime    = json['payment_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id']              = id;
    data['from_type']       = fromType;
    data['from_id']         = fromId;
    data['current_balance'] = currentBalance;
    data['amount']          = amount;
    data['method']          = method;
    data['ref']             = ref;
    data['created_at']      = createdAt;
    data['updated_at']      = updatedAt;
    data['type']            = type;
    data['created_by']      = createdBy;
    data['payment_method']  = paymentMethod;
    data['status']          = status;
    data['payment_time']    = paymentTime;
    return data;
  }
}