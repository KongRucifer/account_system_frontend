class AppStrings {
  final String langCode;

  const AppStrings._(this.langCode);

  static const AppStrings en = AppStrings._('en');
  static const AppStrings lo = AppStrings._('lo');

  // ─── General ───────────────────────────────────────────────
  String get appName => _s('Lan Xang Banker', 'Lan Xang Banker');
  String get loading => _s('Loading...', 'ກຳລັງໂຫລດ...');
  String get retry => _s('Retry', 'ລອງໃໝ່');
  String get logout => _s('Logout', 'ອອກຈາກລະບົບ');
  String get save => _s('Save', 'ບັນທຶກ');
  String get cancel => _s('Cancel', 'ຍົກເລີກ');
  String get error => _s('Error', 'ຜິດພາດ');
  String get noData => _s('No data available', 'ບໍ່ມີຂໍ້ມູນ');
  String get language => _s('Language', 'ພາສາ');

  // ─── Login ─────────────────────────────────────────────────
  String get loginTitle => _s('Lan Xang Banker', 'Lan Xang Banker');
  String get loginSubtitle => _s('Sign in to continue', 'ເຂົ້າສູ່ລະບົບເພື່ອດຳເນີນການ');
  String get username => _s('Username', 'ຊື່ຜູ້ໃຊ້');
  String get password => _s('Password', 'ລະຫັດຜ່ານ');
  String get loginButton => _s('Login', 'ເຂົ້າສູ່ລະບົບ');
  String get usernameRequired => _s('Please enter username', 'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້');
  String get passwordRequired => _s('Please enter password', 'ກະລຸນາປ້ອນລະຫັດຜ່ານ');
  String get forgotPassword => _s('Forgot Password?', 'ລືມລະຫັດຜ່ານ?');
  String get usernameIncorrect => _s('Username is incorrect', 'ຊື່ຜູ້ໃຊ້ບໍ່ຖືກຕ້ອງ');
  String get bankbookIncorrect => _s('Username is incorrect', 'ຊື່ຜູ້ໃຊ້ບໍ່ຖືກຕ້ອງ');
  String get passwordIncorrect => _s('Password is incorrect', 'ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ');
  String get noAccount => _s("Don't have an account?", 'ຍັງບໍ່ມີບັນຊີ?');
  String get haveAccount => _s('Already have an account?', 'ມີບັນຊີແລ້ວ?');
  String get registerNow => _s('Register', 'ລົງທະບຽນ');
  String get loginNow => _s('Login', 'ເຂົ້າສູ່ລະບົບ');

  // ─── Register ──────────────────────────────────────────────
  String get registerTitle => _s('Create Account', 'ສ້າງບັນຊີ');
  String get registerSubtitle => _s('Fill in your information', 'ກະລຸນາປ້ອນຂໍ້ມູນຂອງທ່ານ');
  String get bankbookNumber => _s('Bankbook Number', 'ເລກປື້ມທະນາຄານ');
  String get confirmPassword => _s('Confirm Password', 'ຢືນຢັນລະຫັດຜ່ານ');
  String get phoneNumber => _s('Phone Number', 'ເບີໂທລະສັບ');
  String get vbCode => _s('Village Code', 'ເລກລະຫັດບ້ານ');
  String get bankbookRequired => _s('Please enter bankbook number', 'ກະລຸນາປ້ອນເລກປື້ມທະນາຄານ');
  String get passwordTooShort => _s('Password must be at least 8 characters', 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ຕົວອັກສອນ');
  String get passwordNoSpecial => _s('Password must contain at least one special character (!@#\$%^&*...)', 'ລະຫັດຜ່ານຕ້ອງມີອັກສອນພິເສດຢ່າງໜ້ອຍ 1 ຕົວ (!@#\$%^&*...)');
  String get passwordMismatch => _s('Passwords do not match', 'ລະຫັດຜ່ານບໍ່ກົງກັນ');
  String get passwordValid => _s('Password is valid', 'ລະຫັດຜ່ານຖືກຕ້ອງ');
  String get phoneRequired => _s('Please enter phone number', 'ກະລຸນາປ້ອນເບີໂທລະສັບ');
  String get vbCodeRequired => _s('Please enter village code', 'ກະລຸນາປ້ອນເລກລະຫັດບ້ານ');
  String get bankbookTooLong => _s('Bankbook number must be shorter than or equal to 5 characters', 'ເລກປື້ມທະນາຄານຕ້ອງມີບໍ່ເກີນ 5 ຕົວອັກສອນ');
  String get passwordConfirmMismatch => _s('Password and confirm password do not match', 'ລະຫັດຜ່ານ ແລະ ຢືນຢັນລະຫັດຜ່ານບໍ່ກົງກັນ');
  String get usernameTaken => _s('Username is already taken. Please choose another.', 'ຊື່ຜູ້ໃຊ້ນີ້ຖືກໃຊ້ແລ້ວ. ກະລຸນາເລືອກຊື່ອື່ນ.');
  String get registerButton => _s('Register', 'ລົງທະບຽນ');
  String get registerSuccess => _s('Registration successful!', 'ລົງທະບຽນສຳເລັດ!');
  String get registerSuccessMessage => _s('You can now login with your account.', 'ທ່ານສາມາດເຂົ້າສູ່ລະບົບດ້ວຍບັນຊີຂອງທ່ານໄດ້ແລ້ວ.');
  String get invalidClientInfo => _s('Invalid village code or bankbook number', 'ລະຫັດບ້ານ ຫຼື ເລກປື້ມທະນາຄານບໍ່ຖືກຕ້ອງ');

  String get alreadyHaveAccount => _s('You already have an account. Please login.', 'ທ່ານມີບັນຊີນີ້ແລ້ວ. ກະລຸນາເຂົ້າສູ່ລະບົບ.');

  // ─── Reset Password ────────────────────────────────────────
  String get resetPasswordTitle => _s('Reset Password', 'ຣີເຊັດລະຫັດຜ່ານ');
  String get resetPasswordSubtitle => _s('Enter your phone number and new password', 'ປ້ອນເບີໂທລະສັບ ແລະ ລະຫັດຜ່ານໃໝ່');
  String get newPassword => _s('New Password', 'ລະຫັດຜ່ານໃໝ່');
  String newPasswordRequired(String min) => _s('Please enter new password (min $min chars)', 'ກະລຸນາປ້ອນລະຫັດຜ່ານໃໝ່ (ຢ່າງຫນ້ອຍ $min ຕົວອັກສອນ)');
  String get resetButton => _s('Reset Password', 'ຣີເຊັດລະຫັດຜ່ານ');
  String get resetSuccess => _s('Password reset successful!', 'ຣີເຊັດລະຫັດຜ່ານສຳເລັດ!');
  String get resetSuccessMessage => _s('You can now login with your new password.', 'ທ່ານສາມາດເຂົ້າສູ່ລະບົບດ້ວຍລະຫັດຜ່ານໃໝ່ໄດ້ແລ້ວ.');
  String get resetSuccessBackend => _s('Password reset successful. You can now login with your new password.', 'ຣີເຊັດລະຫັດຜ່ານສຳເລັດ. ທ່ານສາມາດເຂົ້າສູ່ລະບົບດ້ວຍລະຫັດຜ່ານໃໝ່ໄດ້ແລ້ວ.');
  String get noAccountForPhone => _s('No account found for this phone number', 'ບໍ່ພົບບັນຊີທີ່ໃຊ້ເບີໂທລະສັບນີ້');
  String get phoneNumberNotFound => _s('No account found for this phone number', 'ບໍ່ພົບບັນຊີທີ່ໃຊ້ເບີໂທລະສັບນີ້');
  String get accountNotFoundForPhone => _s('No account found for this phone number', 'ບໍ່ພົບບັນຊີທີ່ໃຊ້ເບີໂທລະສັບນີ້');

  // ─── Default Error Messages ────────────────────────────────
  String get loginFailed => _s('Login failed', 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ');
  String get registrationFailed => _s('Registration failed', 'ລົງທະບຽນບໍ່ສຳເລັດ');
  String get resetPasswordFailed => _s('Reset password failed', 'ຣີເຊັດລະຫັດຜ່ານບໍ່ສຳເລັດ');

  // ─── Toast Messages ────────────────────────────────────────
  String get success => _s('Success', 'ສຳເລັດ');
  String get warning => _s('Warning', 'ເຕືອນ');
  String get info => _s('Info', 'ຂໍ້ມູນ');
  String get backToLogin => _s('Back to Login', 'ກັບໄປເຂົ້າສູ່ລະບົບ');

  // ─── Accounts ──────────────────────────────────────────────
  String get myAccounts => _s('My Accounts', 'ບັນຊີຂອງຂ້ອຍ');
  String get systemName => _s('Lan Xang Banker', 'Lan Xang Banker');
  String get accountNumber => _s('Account Number', 'ເລກບັນຊີ');
  String get accountType => _s('Account Type', 'ປະເພດບັນຊີ');
  String get currentBalance => _s('Current Balance', 'ຍອດເງິນປັດຈຸບັນ');
  String get branch => _s('Village', 'ບ້ານ');
  String get status => _s('Status', 'ສະຖານະ');
  String get openingDate => _s('Opening Date', 'ວັນທີເປີດ');
  String get noAccountsFound => _s('No accounts found', 'ບໍ່ພົບບັນຊີ');
  String get viewDashboard => _s('View Dashboard', 'ເບິ່ງໜ້າຫຼັກ');

  // ─── Account Owners ─────────────────────────────────────────
  String get accountOwners => _s('Account Owners', 'ເຈົ້າຂອງບັນຊີ');
  String get ownerName => _s('Name', 'ຊື່');
  String get bankbookNo => _s('Bankbook No.', 'ເລກປື້ມທະນາຄານ');
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
  String get interestDue => _s('Interest Due', 'ດອກເບ້ຍຕ້ອງຊຳລະ');
  String get interestUnpaid => _s('Interest Unpaid', 'ດອກເບ້ຍຄ້າງຊຳລະ');
  String get interestPaid => _s('Interest Paid', 'ດອກເບ້ຍຊຳລະແລ້ວ');
  String get viewTransactions => _s('View Transaction History', 'ເບິ່ງປະຫວັດການທຳທຸລະກຳ');

  // ─── Notifications ─────────────────────────────────────────
  String get markAllAsReadButton => _s('If read, please click here', 'ຖ້າອ່ານເເລ້ວກາລຸນາກົດທີ່ນີ້');

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
