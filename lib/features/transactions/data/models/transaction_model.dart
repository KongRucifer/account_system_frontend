class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String? description;
  final String debitAccNumber;
  final TransactionCode? transactionCode;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    this.description,
    required this.debitAccNumber,
    this.transactionCode,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      debitAccNumber: json['debitAccNumber'] as String,
      transactionCode: json['transactionCode'] != null
          ? TransactionCode.fromJson(json['transactionCode'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TransactionCode {
  final String? transactionCode;
  final String? nameEng;
  final String? nameLao;

  TransactionCode({
    this.transactionCode,
    this.nameEng,
    this.nameLao,
  });

  factory TransactionCode.fromJson(Map<String, dynamic> json) {
    return TransactionCode(
      transactionCode: json['transactionCode'] as String?,
      nameEng: json['nameEng'] as String?,
      nameLao: json['nameLao'] as String?,
    );
  }

  String get displayName => nameLao ?? nameEng ?? transactionCode ?? 'Unknown';
}

class PaginatedTransactions {
  final bool success;
  final int code;
  final String message;
  final List<Transaction> results;
  final Pagination pagination;

  PaginatedTransactions({
    required this.success,
    required this.code,
    required this.message,
    required this.results,
    required this.pagination,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedTransactions(
      success: json['success'] as bool,
      code: json['code'] as int,
      message: json['message'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }
}
