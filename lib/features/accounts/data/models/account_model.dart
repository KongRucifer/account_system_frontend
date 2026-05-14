class AccountOwnerInfo {
  final String clientId;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? phoneNumber;
  final String? gender;
  final DateTime? birthDate;
  final String? clientType;

  AccountOwnerInfo({
    required this.clientId,
    this.firstName,
    this.lastName,
    this.nickName,
    this.phoneNumber,
    this.gender,
    this.birthDate,
    this.clientType,
  });

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }

  String get displayName => fullName.isNotEmpty ? fullName : (nickName ?? '');

  factory AccountOwnerInfo.fromJson(Map<String, dynamic> json) {
    return AccountOwnerInfo(
      clientId:   json['clientId'] as String? ?? '',
      firstName:  json['firstName'] as String?,
      lastName:   json['lastName'] as String?,
      nickName:   json['nickName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      gender:     json['genderLao'] as String? ?? json['genderEng'] as String?,
      birthDate:  json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      clientType: json['clientType'] as String?,
    );
  }
}

class AccountsResponse {
  final String bankbookNumber;
  final String? vbCode;
  final String? username;
  final List<AccountOwnerInfo> accountOwners;
  final List<Account> savingsAccounts;
  final List<Account> loanAccounts;

  AccountsResponse({
    this.bankbookNumber = '',
    this.vbCode,
    this.username,
    this.accountOwners = const [],
    this.savingsAccounts = const [],
    this.loanAccounts = const [],
  });

  List<Account> get myAccounts => [...savingsAccounts, ...loanAccounts];

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    final ownersList = json['accountOwners'] as List<dynamic>? ?? [];
    final savingsList = json['savingsAccounts'] as List<dynamic>? ?? [];
    final loansList = json['loanAccounts'] as List<dynamic>? ?? [];
    return AccountsResponse(
      bankbookNumber: json['bankbookNumber'] as String? ?? '',
      vbCode: json['vbCode'] as String?,
      username: json['username'] as String?,
      accountOwners: ownersList
          .map((e) => AccountOwnerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      savingsAccounts: savingsList
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
      loanAccounts: loansList
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
  final String? accTypeId;
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
    this.accTypeId,
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
      accTypeId: json['accTypeId'] as String?,
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
