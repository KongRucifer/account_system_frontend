class AppStrings {
  final String langCode;

  const AppStrings._(this.langCode);

  static const AppStrings en = AppStrings._('en');
  static const AppStrings lo = AppStrings._('lo');

  // ─── General ───────────────────────────────────────────────
  String get appName => _s('Account System', 'ລະບົບບັນຊີ');
  String get loading => _s('Loading...', 'ກຳລັງໂຫລດ...');
  String get retry => _s('Retry', 'ລອງໃໝ່');
  String get logout => _s('Logout', 'ອອກຈາກລະບົບ');
  String get save => _s('Save', 'ບັນທຶກ');
  String get cancel => _s('Cancel', 'ຍົກເລີກ');
  String get error => _s('Error', 'ຜິດພາດ');
  String get noData => _s('No data available', 'ບໍ່ມີຂໍ້ມູນ');
  String get language => _s('Language', 'ພາສາ');

  // ─── Login ─────────────────────────────────────────────────
  String get loginTitle => _s('Account System', 'ລະບົບບັນຊີ');
  String get loginSubtitle => _s('Sign in to continue', 'ເຂົ້າສູ່ລະບົບເພື່ອດຳເນີນການ');
  String get username => _s('Username', 'ຊື່ຜູ້ໃຊ້');
  String get password => _s('Password', 'ລະຫັດຜ່ານ');
  String get loginButton => _s('Login', 'ເຂົ້າສູ່ລະບົບ');
  String get usernameRequired => _s('Please enter username', 'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້');
  String get passwordRequired => _s('Please enter password', 'ກະລຸນາປ້ອນລະຫັດຜ່ານ');

  // ─── Accounts ──────────────────────────────────────────────
  String get myAccounts => _s('My Accounts', 'ບັນຊີຂອງຂ້ອຍ');
  String get accountNumber => _s('Account Number', 'ເລກບັນຊີ');
  String get accountType => _s('Account Type', 'ປະເພດບັນຊີ');
  String get currentBalance => _s('Current Balance', 'ຍອດເງິນປັດຈຸບັນ');
  String get branch => _s('Branch', 'ສາຂາ');
  String get status => _s('Status', 'ສະຖານະ');
  String get openingDate => _s('Opening Date', 'ວັນທີເປີດ');
  String get noAccountsFound => _s('No accounts found', 'ບໍ່ພົບບັນຊີ');
  String get viewDashboard => _s('View Dashboard', 'ເບິ່ງໜ້າຫຼັກ');

  // ─── Account Owners ─────────────────────────────────────────
  String get accountOwners => _s('Account Owners', 'ເຈົ້າຂອງບັນຊີ');
  String get ownerName => _s('Name', 'ຊື່');
  String get bankbookNo => _s('Bankbook No.', 'ເລກສະໝຸດ');
  String get phone => _s('Phone', 'ເບີໂທ');
  String get gender => _s('Gender', 'ເພດ');
  String get birthDate => _s('Birth Date', 'ວັນເດືອນປີເກີດ');
  String get clientType => _s('Client Type', 'ປະເພດລູກຄ້າ');
  String get noOwners => _s('No owners found', 'ບໍ່ພົບເຈົ້າຂອງບັນຊີ');

  // ─── Dashboard ─────────────────────────────────────────────
  String get dashboard => _s('Account Dashboard', 'ໜ້າຫຼັກບັນຊີ');
  String get accountInfo => _s('Account Information', 'ຂໍ້ມູນບັນຊີ');
  String get financialSummary => _s('Financial Summary', 'ສະຫຼຸບການເງິນ');
  String get loanInfo => _s('Loan Information', 'ຂໍ້ມູນເງິນກູ້');
  String get savingsInfo => _s('Savings Information', 'ຂໍ້ມູນເງິນຝາກ');
  String get loanOutstanding => _s('Loan Outstanding', 'ເງິນກູ້ຄົງເຫຼືອ');
  String get savingsBalance => _s('Savings Balance', 'ຍອດເງິນຝາກ');
  String get netPosition => _s('Net Position', 'ສຸດທິ');
  String get interestRate => _s('Interest Rate', 'ອັດຕາດອກເບ້ຍ');
  String get loanPeriod => _s('Loan Period', 'ໄລຍະກູ້');
  String get months => _s('months', 'ເດືອນ');
  String get repaymentType => _s('Repayment Type', 'ປະເພດຊຳລະ');
  String get totalLoan => _s('Total Loan Amount', 'ຍອດເງິນກູ້');
  String get interestDue => _s('Interest Due', 'ດອກເບ້ຍຄ້າງຊຳລະ');
  String get interestPaid => _s('Interest Paid', 'ດອກເບ້ຍຊຳລະແລ້ວ');
  String get viewTransactions => _s('View Transaction History', 'ເບິ່ງປະຫວັດການທຳທຸລະກຳ');

  // ─── Transactions ──────────────────────────────────────────
  String get transactionHistory => _s('Transaction History', 'ປະຫວັດລາຍການ');
  String get filterByYear => _s('Filter by Year', 'ກັ່ນຕອງຕາມປີ');
  String get allYears => _s('All', 'ທັງໝົດ');
  String get loadMore => _s('Load More', 'ໂຫລດເພີ່ມ');
  String get noTransactions => _s('No transactions found', 'ບໍ່ພົບລາຍການ');
  String get transactionIn => _s('IN', 'ເຂົ້າ');
  String get transactionOut => _s('OUT', 'ອອກ');
  String get page => _s('Page', 'ໜ້າ');
  String get of => _s('of', 'ຈາກ');
  String get total => _s('Total', 'ທັງໝົດ');
  String get transactions => _s('transactions', 'ລາຍການ');

  // ─── Helper ────────────────────────────────────────────────
  String _s(String en, String lo) => langCode == 'lo' ? lo : en;
}
