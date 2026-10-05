// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nexo Bank';

  @override
  String get loading => 'Loading';

  @override
  String get loadingMore => 'Loading more';

  @override
  String get retry => 'Retry';

  @override
  String supportCode(String code) {
    return 'Support code: $code';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get comingSoon => 'This feature will be available soon.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String buttonLoading(String label) {
    return '$label, loading';
  }

  @override
  String get offlineBanner =>
      'You\'re offline. You\'ll see the last saved data.';

  @override
  String staleRefreshFailed(String age) {
    return 'We couldn\'t refresh. Showing data from $age.';
  }

  @override
  String staleRefreshing(String age) {
    return 'Data from $age. Refreshing…';
  }

  @override
  String get relativeNow => 'just now';

  @override
  String relativeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String relativeHours(int count) {
    return '$count h ago';
  }

  @override
  String relativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String moneySpeechUsd(int units, int cents) {
    return '$units dollars and $cents cents';
  }

  @override
  String moneySpeechOther(int units, int cents, String currency) {
    return '$units $currency and $cents cents';
  }

  @override
  String moneySpeechNegative(String amount) {
    return 'minus $amount';
  }

  @override
  String maxChars(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get errorNetwork => 'We couldn\'t connect. Check your connection.';

  @override
  String get errorTimeout => 'The server took too long to respond.';

  @override
  String get errorServiceUnavailable =>
      'The service isn\'t available right now. Please try again in a few seconds.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorSession => 'Your session isn\'t valid. Please sign in again.';

  @override
  String get errorValidation => 'Please check the information you entered.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get loginWelcome => 'Welcome to Nexo';

  @override
  String get loginSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalidCredentials => 'Incorrect username or password.';

  @override
  String get loginLocked =>
      'Your user is locked after several failed attempts. Contact support to unlock it.';

  @override
  String get usernameRequired => 'Enter your username';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get createAccountLink => 'Don\'t have an account? Create one';

  @override
  String get lockedFailed => 'We couldn\'t verify your identity.';

  @override
  String get biometricLogin => 'Sign in with fingerprint or face';

  @override
  String get orDivider => 'or';

  @override
  String get useAnotherAccount => 'Not you? Use another account';

  @override
  String get biometricUnlockReason => 'Unlock Nexo Bank';

  @override
  String get biometricEnableReason => 'Confirm your identity to turn it on';

  @override
  String get onboardingStepPersonal => 'Your details';

  @override
  String get onboardingStepCredentials => 'Your username';

  @override
  String get onboardingStepTerms => 'Terms';

  @override
  String get onboardingStepWelcome => 'Welcome';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get idNumberLabel => 'ID number';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Mobile phone';

  @override
  String get phoneHelper => 'Example: 0991234567 or +593991234567';

  @override
  String get usernameHelper =>
      'You\'ll use it to sign in. Letters, numbers, \".\" or \"_\".';

  @override
  String get passwordHelper =>
      'At least 8 characters, with at least one letter and one number.';

  @override
  String get confirmPasswordLabel => 'Confirm your password';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get termsTitle => 'Before you finish';

  @override
  String get termsBody =>
      'When you create your account, Nexo Bank will open a savings account in your name with no maintenance fee. Your data is only used to identify you and operate your products, it is stored encrypted and is never shared with third parties without your consent. You can close your account at any time.';

  @override
  String get termsAccept =>
      'I accept the terms and conditions and the privacy policy';

  @override
  String welcomeTitle(String name) {
    return 'All set, $name!';
  }

  @override
  String get welcomeBody =>
      'Your savings account is open. From now on you can sign in with your username and password.';

  @override
  String get start => 'Get started';

  @override
  String get regFullNameRequired => 'Enter your full name';

  @override
  String get regFullNameSurname => 'Enter your first and last name';

  @override
  String get regIdNumber => 'The ID number must have 10 digits';

  @override
  String get regBirthDateRequired => 'Choose your date of birth';

  @override
  String get regBirthDateFuture => 'The date must be before today';

  @override
  String get regUnderage => 'You must be of legal age';

  @override
  String get regEmailRequired => 'Enter your email';

  @override
  String get regEmailInvalid => 'Invalid email';

  @override
  String get regPhoneInvalid => 'Invalid phone number (9 to 15 digits)';

  @override
  String get regUsernameInvalid =>
      'Between 3 and 30 letters, numbers, \".\" or \"_\"';

  @override
  String regPasswordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get regPasswordWeak =>
      'It must have at least one letter and one number';

  @override
  String get regPasswordMismatch => 'Passwords don\'t match';

  @override
  String get regTermsRequired => 'You must accept the terms to continue';

  @override
  String get regUsernameTaken => 'That username is taken. Choose another one.';

  @override
  String get regServerInvalid => 'Please check this field';

  @override
  String get onboardingUnavailable =>
      'We couldn\'t complete your registration right now. Please try again in a few minutes.';

  @override
  String get accountTypeSavings => 'Savings account';

  @override
  String get accountTypeChecking => 'Checking account';

  @override
  String get accountTypeGeneric => 'Account';

  @override
  String get accountMain => 'Main';

  @override
  String get accountInactive => 'Inactive';

  @override
  String get availableBalance => 'Available balance';

  @override
  String accountSemantics(
    String name,
    String type,
    String last4,
    String balance,
  ) {
    return '$name, $type ending in $last4. Available balance $balance';
  }

  @override
  String get accountInactiveSuffix => '. Inactive account';

  @override
  String get yourAccounts => 'Your accounts';

  @override
  String totalBalance(String amount) {
    return 'Total balance $amount';
  }

  @override
  String get noAccounts => 'You don\'t have any accounts yet.';

  @override
  String get movementCredit => 'Credit';

  @override
  String get movementDebit => 'Debit';

  @override
  String get movementIncoming => 'incoming';

  @override
  String get movementOutgoing => 'outgoing';

  @override
  String movementSemantics(
    String description,
    String kind,
    String amount,
    String time,
  ) {
    return '$description, $kind of $amount, $time';
  }

  @override
  String movementSubtitle(String time, String balance) {
    return '$time · Balance $balance';
  }

  @override
  String get movementsTitle => 'Transactions';

  @override
  String get noMovements => 'This account has no transactions yet.';

  @override
  String get loadMoreFailed => 'We couldn\'t load more. Retry';

  @override
  String get noMoreMovements => 'No more transactions';

  @override
  String get profileTitle => 'My profile';

  @override
  String get segmentYoung => 'Young';

  @override
  String get segmentPremium => 'Premium';

  @override
  String get segmentEntrepreneur => 'Entrepreneur';

  @override
  String get segmentStandard => 'Personal';

  @override
  String customerSegment(String segment) {
    return '$segment customer';
  }

  @override
  String get emailTitle => 'Email';

  @override
  String get phoneTitle => 'Mobile phone';

  @override
  String get preferences => 'Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Alerts about your transfers';

  @override
  String get promotions => 'Promotions';

  @override
  String get promotionsSubtitle => 'See offers on your home screen';

  @override
  String get logout => 'Sign out';

  @override
  String get biometricToggle => 'Sign in with fingerprint or face';

  @override
  String get biometricToggleSubtitle => 'Only on this device';

  @override
  String saveFailed(String reason) {
    return 'We couldn\'t save the change. $reason';
  }

  @override
  String get fxTitle => 'Exchange rates';

  @override
  String fxReference(String age) {
    return 'Reference rate · $age';
  }

  @override
  String get fxStale => 'Reference rate · couldn\'t refresh';

  @override
  String promoSemantics(String text) {
    return 'Promotion: $text';
  }

  @override
  String savingsSemantics(
    String title,
    String saved,
    String target,
    int percent,
  ) {
    return '$title. You have $saved of $target, $percent percent';
  }

  @override
  String savingsProgress(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String get quickActionTransfer => 'Transfer';

  @override
  String get quickActionTopup => 'Mobile top-up';

  @override
  String get quickActionGoals => 'My goals';

  @override
  String get quickActionInvest => 'Investments';

  @override
  String get quickActionAdvisor => 'My advisor';

  @override
  String get quickActionCollect => 'Collect with QR';

  @override
  String get quickActionSuppliers => 'Pay suppliers';

  @override
  String get quickActionProfile => 'My profile';

  @override
  String get transferTitle => 'Transfer';

  @override
  String get transferAction => 'Transfer';

  @override
  String get transferBetweenMyAccounts => 'Transfer between my accounts';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get transferOffline =>
      'You\'re offline. Transfers need internet: they aren\'t saved to be sent later.';

  @override
  String get transferNeedTwoAccounts =>
      'You need at least two active accounts, one of them with funds, to transfer between your accounts.';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get amountLabel => 'Amount';

  @override
  String availableAmount(String amount) {
    return 'Available: $amount';
  }

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get description => 'Description';

  @override
  String get reviewBeforeConfirm => 'Review the details before confirming';

  @override
  String get balanceAfter => 'Balance after';

  @override
  String get confirmTransfer => 'Confirm transfer';

  @override
  String get edit => 'Edit';

  @override
  String get transferDone => 'Transfer completed';

  @override
  String get date => 'Date';

  @override
  String get receiptNumber => 'Receipt number';

  @override
  String get backHome => 'Back to home';

  @override
  String get anotherTransfer => 'Make another transfer';

  @override
  String get transferRejectedTitle => 'The transfer wasn\'t made';

  @override
  String get fixData => 'Fix details';

  @override
  String get transferUnknownTitle => 'We couldn\'t confirm the result';

  @override
  String get transferUnknownBody =>
      'The connection was interrupted and we don\'t know if the transfer went through. Don\'t create it again: tap \"Check status\" and, if it was made, you\'ll see the receipt without it being repeated.';

  @override
  String get checkStatus => 'Check status';

  @override
  String get goHome => 'Go to home';

  @override
  String get transferSourceRequired => 'Choose the source account';

  @override
  String get transferSourceInactive => 'The source account isn\'t active';

  @override
  String get transferTargetRequired => 'Choose the destination account';

  @override
  String get transferTargetSame =>
      'The destination must be a different account';

  @override
  String get transferTargetInactive => 'The destination account isn\'t active';

  @override
  String get transferCurrencyMismatch =>
      'The accounts have different currencies';

  @override
  String get transferAmountRequired => 'Enter the amount';

  @override
  String get transferAmountInvalid => 'Enter a valid amount, for example 25.50';

  @override
  String get transferAmountNotPositive =>
      'The amount must be greater than zero';

  @override
  String transferInsufficient(String amount) {
    return 'Insufficient funds. Available: $amount';
  }

  @override
  String rejectInsufficient(String account) {
    return 'Insufficient funds in $account.';
  }

  @override
  String get rejectAccountNotActive => 'One of the accounts isn\'t active.';

  @override
  String get rejectSameAccount =>
      'Source and destination must be different accounts.';

  @override
  String get rejectCurrencyMismatch =>
      'The accounts have different currencies.';

  @override
  String get rejectAccountNotFound => 'We couldn\'t find one of the accounts.';

  @override
  String get transferNotFound => 'We couldn\'t find this transfer.';

  @override
  String get ownAccount => 'Own account';

  @override
  String get status => 'Status';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Under review';

  @override
  String get notificationTransferTitle => 'Transfer completed';

  @override
  String notificationTransferBody(String amount, String from, String to) {
    return 'You sent $amount from $from to $to.';
  }

  @override
  String get notificationChannelName => 'Transfers';

  @override
  String get notificationChannelDescription => 'Alerts about your transfers';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get aliasSavings => 'Savings';

  @override
  String get aliasChecking => 'Checking';

  @override
  String get aliasInvestments => 'Investments';

  @override
  String get aliasBusiness => 'Business';

  @override
  String get aliasPersonal => 'Personal';

  @override
  String get savingsGoal => 'Savings goal';

  @override
  String get promoSavingsTitle => 'Earn 5% extra on your first goal';

  @override
  String get promoSavingsSubtitle => 'This month only';

  @override
  String get promoAdvisorTitle => 'Free investment advice';

  @override
  String get promoAdvisorSubtitle => 'Book a session with your advisor';

  @override
  String get promoCreditTitle => 'Credit for your business';

  @override
  String promoCreditSubtitle(String amount) {
    return 'Pre-approved up to $amount';
  }

  @override
  String get promoTransfersTitle => 'Nexo Black Friday';

  @override
  String get promoTransfersSubtitle => '0% fees on all your transfers';
}
