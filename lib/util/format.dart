import '../l10n/app_localizations.dart';

String two(int n) => n.toString().padLeft(2, '0');

/// 倒數顯示：超過一小時 H:MM:SS，否則 MM:SS。
String formatCountdown(Duration d) {
  final int totalSeconds = d.inSeconds;
  final int h = totalSeconds ~/ 3600;
  final int m = (totalSeconds % 3600) ~/ 60;
  final int s = totalSeconds % 60;
  if (h > 0) return '$h:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

/// 碼錶顯示：MM:SS.CC（過小時則 H:MM:SS.CC）。
String formatStopwatch(Duration d) {
  final int centis = (d.inMilliseconds ~/ 10) % 100;
  final int totalSeconds = d.inSeconds;
  final int h = totalSeconds ~/ 3600;
  final int m = (totalSeconds % 3600) ~/ 60;
  final int s = totalSeconds % 60;
  if (h > 0) return '$h:${two(m)}:${two(s)}.${two(centis)}';
  return '${two(m)}:${two(s)}.${two(centis)}';
}

/// 「7 小時 24 分」式的時長描述。
String describeSpan(AppLocalizations l10n, Duration d) {
  if (d.inMinutes < 1) return l10n.ringUnderMinute;
  final int h = d.inHours;
  final int m = d.inMinutes % 60;
  final StringBuffer out = StringBuffer();
  if (h > 0) out.write('$h ${l10n.hourUnit}');
  if (m > 0) {
    if (out.isNotEmpty) out.write(' ');
    out.write('$m ${l10n.minuteUnit}');
  }
  return out.toString();
}

/// 時差描述：「快 8 小時」「慢 2 小時 30 分」「與本地同步」。
String describeOffset(AppLocalizations l10n, Duration diff) {
  if (diff.inMinutes == 0) return l10n.sameAsLocal;
  final Duration abs = diff.isNegative ? -diff : diff;
  final int h = abs.inHours;
  final int m = abs.inMinutes % 60;
  final StringBuffer span = StringBuffer();
  if (h > 0) span.write('$h ${l10n.hourUnit}');
  if (m > 0) {
    if (span.isNotEmpty) span.write(' ');
    span.write('$m ${l10n.minuteUnit}');
  }
  return diff.isNegative
      ? l10n.behindBy(span.toString())
      : l10n.aheadBy(span.toString());
}
