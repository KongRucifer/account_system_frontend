class DashboardData {
  final AccountInfo account;
  final LoanInfo? loan;
  final SavingsInfo? savings;
  final FinancialSummary? financialSummary;

  DashboardData({
    required this.account,
    this.loan,
    this.savings,
    this.financialSummary,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      account: AccountInfo.fromJson(json['account'] as Map<String, dynamic>),
      loan: json['loan'] != null
          ? LoanInfo.fromJson(json['loan'] as Map<String, dynamic>)
          : null,
      savings: json['savings'] != null
          ? SavingsInfo.fromJson(json['savings'] as Map<String, dynamic>)
          : null,
      financialSummary: json['financialSummary'] != null
          ? FinancialSummary.fromJson(
              json['financialSummary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AccountInfo {
  final String accNumber;
  final String? accNameLao;
  final String? accNameEng;
  final double currentBalance;
  final String? accountType;
  final String vbCode;
  final String? vbName;
  final DateTime? openingDate;
  final String status;

  AccountInfo({
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

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      accNumber: json['accNumber'] as String,
      accNameLao: json['accNameLao'] as String?,
      accNameEng: json['accNameEng'] as String?,
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble()
          : 0.0,
      accountType: json['accountType'] as String?,
      vbCode: json['vbCode'] as String? ?? '',
      vbName: json['vbName'] as String?,
      openingDate: json['openingDate'] != null
          ? DateTime.tryParse(json['openingDate'] as String)
          : null,
      status: (json['status'] ?? json['statusId'] ?? '') as String,
    );
  }

  String get displayName => accNameLao ?? accNameEng ?? accNumber;
}

class LoanInfo {
  final int id;
  final double totalLoanAmount;
  final double loanOutstanding;
  final double interestDue;
  final double interestUnpaid;
  final double principalDue;
  final double principalPaid;
  final DateTime startDate;
  final DateTime? endDate;
  final int loanPeriodMonths;
  final double interestRate;
  final String? repaymentType;
  final String status;

  LoanInfo({
    required this.id,
    required this.totalLoanAmount,
    required this.loanOutstanding,
    required this.interestDue,
    required this.interestUnpaid,
    required this.principalDue,
    required this.principalPaid,
    required this.startDate,
    this.endDate,
    required this.loanPeriodMonths,
    required this.interestRate,
    this.repaymentType,
    required this.status,
  });

  factory LoanInfo.fromJson(Map<String, dynamic> json) {
    return LoanInfo(
      id: (json['id'] as num).toInt(),
      totalLoanAmount: json['totalLoanAmount'] != null
          ? (json['totalLoanAmount'] as num).toDouble() : 0.0,
      loanOutstanding: json['loanOutstanding'] != null
          ? (json['loanOutstanding'] as num).toDouble() : 0.0,
      interestDue: json['interestDue'] != null
          ? (json['interestDue'] as num).toDouble() : 0.0,
      interestUnpaid: json['interestUnpaid'] != null
          ? (json['interestUnpaid'] as num).toDouble() : 0.0,
      principalDue: json['principalDue'] != null
          ? (json['principalDue'] as num).toDouble() : 0.0,
      principalPaid: json['principalPaid'] != null
          ? (json['principalPaid'] as num).toDouble() : 0.0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      loanPeriodMonths: json['loanPeriodMonths'] != null
          ? (json['loanPeriodMonths'] as num).toInt() : 0,
      interestRate: json['interestRate'] != null
          ? (json['interestRate'] as num).toDouble() : 0.0,
      repaymentType: json['repaymentType'] as String?,
      status: (json['status'] ?? '') as String,
    );
  }
}

class SavingsInfo {
  final int id;
  final double currentBalance;
  final double? savingAmount;
  final double? withdrawalAmount;
  final double interestNumerator;
  final DateTime date;

  SavingsInfo({
    required this.id,
    required this.currentBalance,
    this.savingAmount,
    this.withdrawalAmount,
    required this.interestNumerator,
    required this.date,
  });

  factory SavingsInfo.fromJson(Map<String, dynamic> json) {
    return SavingsInfo(
      id: (json['id'] as num).toInt(),
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble() : 0.0,
      savingAmount: json['savingAmount'] != null
          ? (json['savingAmount'] as num).toDouble() : null,
      withdrawalAmount: json['withdrawalAmount'] != null
          ? (json['withdrawalAmount'] as num).toDouble() : null,
      interestNumerator: json['interestNumerator'] != null
          ? (json['interestNumerator'] as num).toDouble() : 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FinancialSummary {
  final double currentBalance;
  final double totalLoanAmount;
  final double loanOutstanding;
  final double savingsBalance;
  final double netPosition;

  FinancialSummary({
    required this.currentBalance,
    required this.totalLoanAmount,
    required this.loanOutstanding,
    required this.savingsBalance,
    required this.netPosition,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble() : 0.0,
      totalLoanAmount: json['totalLoanAmount'] != null
          ? (json['totalLoanAmount'] as num).toDouble() : 0.0,
      loanOutstanding: json['loanOutstanding'] != null
          ? (json['loanOutstanding'] as num).toDouble() : 0.0,
      savingsBalance: json['savingsBalance'] != null
          ? (json['savingsBalance'] as num).toDouble() : 0.0,
      netPosition: json['netPosition'] != null
          ? (json['netPosition'] as num).toDouble() : 0.0,
    );
  }
}
