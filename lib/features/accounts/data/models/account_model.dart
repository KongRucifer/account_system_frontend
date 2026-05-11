class Account {
  final String accNumber;
  final String? accNameLao;
  final String? accNameEng;
  final double currentBalance;
  final String? accountType;
  final String vbCode;
  final String? vbName;
  final DateTime? openingDate;
  final String status;

  Account({
    required this.accNumber,
    this.accNameLao,
    this.accNameEng,
    required this.currentBalance,
    this.accountType,
    required this.vbCode,
    this.vbName,
    this.openingDate,
    required this.status,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accNumber: json['accNumber'] as String,
      accNameLao: json['accNameLao'] as String?,
      accNameEng: json['accNameEng'] as String?,
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble()
          : 0.0,
      accountType: json['accountType'] as String?,
      vbCode: json['vbCode'] as String? ?? '',
      vbName: json['vb'] != null
          ? (json['vb']['nameLao'] ?? json['vb']['nameEng']) as String?
          : json['vbName'] as String?,
      openingDate: json['openingDate'] != null
          ? DateTime.tryParse(json['openingDate'] as String)
          : null,
      status: (json['statusId'] ?? json['status'] ?? '') as String,
    );
  }

  String get displayName => accNameLao ?? accNameEng ?? accNumber;
}
