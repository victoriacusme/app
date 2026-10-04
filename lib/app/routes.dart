abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const transfer = '/transfer';
  static const profile = '/profile';
  static String account(String id) => '/accounts/$id';
  static String transferFrom(String accountId) => '$transfer?from=$accountId';
}
