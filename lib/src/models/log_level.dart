/// Log verbosity levels for the Encore SDK.
///
/// Mirrors the native SDK log levels on both iOS and Android.
/// Higher ordinal values include all lower-level messages.
enum LogLevel {
  none,
  error,
  warn,
  info,
  debug;

  String get nativeValue => name.toUpperCase();
}
