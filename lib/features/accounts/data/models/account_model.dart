class AccountOwnerInfo {
  final String clientId;
  final String bankbookNumber;
  final String clientName;
  final String? phoneNumber;
  final String? gender;
  final DateTime? birthDate;
  final String? clientType;

  AccountOwnerInfo({
    required this.clientId,
    required this.bankbookNumber,
    required this.clientName,
    this.phoneNumber,
    this.gender,
    this.birthDate,
    this.clientType,
  });

  factory AccountOwnerInfo.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final firstName = client?['firstName'] as String? ?? '';
    final lastName  = client?['lastName']  as String? ?? '';
    final nickName  = client?['nickName']  as String?;
    return AccountOwnerInfo(
      clientId:       json['clientId'] as String? ?? '',
      bankbookNumber: json['bankbookNumber'] as String? ?? '',
      clientName:     nickName ?? '$firstName $lastName'.trim(),
      phoneNumber:    client?['phoneNumber'] as String?,
      gender:         client?['genderLao'] as String? ?? client?['genderEng'] as String?,
      birthDate:      client?['birthDate'] != null
          ? DateTime.tryParse(client!['birthDate'] as String)
          : null,
      clientType: client?['clientType'] as String?,
    );
  }
}

class AccountsResponse {
  final AccountOwnerInfo? accountOwner;
  final List<Account> myAccounts;

  AccountsResponse({this.accountOwner, required this.myAccounts});

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['accountOwner'] as Map<String, dynamic>?;
    final accountsList = json['myAccounts'] as List<dynamic>? ?? [];
    return AccountsResponse(
      accountOwner: ownerJson != null ? AccountOwnerInfo.fromJson(ownerJson) : null,
      myAccounts: accountsList
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

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
