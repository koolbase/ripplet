abstract final class Env {
  static const baseUrl = String.fromEnvironment(
    'KOOLBASE_URL',
    defaultValue: 'https://api.koolbase.com',
  );

  static const publicKey = String.fromEnvironment(
    'KOOLBASE_KEY',
    defaultValue: 'pk_live_d93ddd785b9fa6a4e8845553',
  );
}
