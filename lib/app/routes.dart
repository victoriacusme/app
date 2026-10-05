abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const transfer = '/transfer';
  static const profile = '/profile';
  static String account(String id) => '/accounts/$id';
  static String transferDetail(String id) => '/transfers/$id';
  static String transferFrom(String accountId) => '$transfer?from=$accountId';
}
