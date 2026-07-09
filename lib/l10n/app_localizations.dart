import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'物语时钟'**
  String get appTitle;

  /// No description provided for @tabClock.
  ///
  /// In zh, this message translates to:
  /// **'时钟'**
  String get tabClock;

  /// No description provided for @tabAlarm.
  ///
  /// In zh, this message translates to:
  /// **'闹钟'**
  String get tabAlarm;

  /// No description provided for @tabTimer.
  ///
  /// In zh, this message translates to:
  /// **'计时'**
  String get tabTimer;

  /// No description provided for @tabStopwatch.
  ///
  /// In zh, this message translates to:
  /// **'秒表'**
  String get tabStopwatch;

  /// No description provided for @chapterDawn.
  ///
  /// In zh, this message translates to:
  /// **'晨之章'**
  String get chapterDawn;

  /// No description provided for @chapterDay.
  ///
  /// In zh, this message translates to:
  /// **'昼之章'**
  String get chapterDay;

  /// No description provided for @chapterDusk.
  ///
  /// In zh, this message translates to:
  /// **'暮之章'**
  String get chapterDusk;

  /// No description provided for @chapterNight.
  ///
  /// In zh, this message translates to:
  /// **'夜之章'**
  String get chapterNight;

  /// No description provided for @verseDawn.
  ///
  /// In zh, this message translates to:
  /// **'晨光初染，故事翻开新的一页。'**
  String get verseDawn;

  /// No description provided for @verseDay.
  ///
  /// In zh, this message translates to:
  /// **'日色正好，时间缓缓向前。'**
  String get verseDay;

  /// No description provided for @verseDusk.
  ///
  /// In zh, this message translates to:
  /// **'暮色四合，这一章将尽未尽。'**
  String get verseDusk;

  /// No description provided for @verseNight.
  ///
  /// In zh, this message translates to:
  /// **'夜幕低垂，故事仍在低语。'**
  String get verseNight;

  /// No description provided for @worldClock.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟'**
  String get worldClock;

  /// No description provided for @addCity.
  ///
  /// In zh, this message translates to:
  /// **'添加城市'**
  String get addCity;

  /// No description provided for @searchCityHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索城市或地区'**
  String get searchCityHint;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @sameDay.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get sameDay;

  /// No description provided for @nextDay.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get nextDay;

  /// No description provided for @prevDay.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get prevDay;

  /// No description provided for @sameAsLocal.
  ///
  /// In zh, this message translates to:
  /// **'与本地同步'**
  String get sameAsLocal;

  /// No description provided for @aheadBy.
  ///
  /// In zh, this message translates to:
  /// **'快 {diff}'**
  String aheadBy(String diff);

  /// No description provided for @behindBy.
  ///
  /// In zh, this message translates to:
  /// **'慢 {diff}'**
  String behindBy(String diff);

  /// No description provided for @monthUnit.
  ///
  /// In zh, this message translates to:
  /// **'月'**
  String get monthUnit;

  /// No description provided for @dayUnit.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get dayUnit;

  /// No description provided for @weekFull.
  ///
  /// In zh, this message translates to:
  /// **'星期'**
  String get weekFull;

  /// No description provided for @hourUnit.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get hourUnit;

  /// No description provided for @minuteUnit.
  ///
  /// In zh, this message translates to:
  /// **'分'**
  String get minuteUnit;

  /// No description provided for @secondUnit.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get secondUnit;

  /// No description provided for @halfHourUnit.
  ///
  /// In zh, this message translates to:
  /// **'半'**
  String get halfHourUnit;

  /// No description provided for @morning.
  ///
  /// In zh, this message translates to:
  /// **'上午'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午'**
  String get afternoon;

  /// No description provided for @noAlarms.
  ///
  /// In zh, this message translates to:
  /// **'还没有闹钟。夜里安静，也别忘了明早的约定。'**
  String get noAlarms;

  /// No description provided for @addAlarm.
  ///
  /// In zh, this message translates to:
  /// **'添加闹钟'**
  String get addAlarm;

  /// No description provided for @editAlarm.
  ///
  /// In zh, this message translates to:
  /// **'编辑闹钟'**
  String get editAlarm;

  /// No description provided for @alarmDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'闹钟'**
  String get alarmDefaultName;

  /// No description provided for @alarmLabelHint.
  ///
  /// In zh, this message translates to:
  /// **'给这声铃一个名字'**
  String get alarmLabelHint;

  /// No description provided for @once.
  ///
  /// In zh, this message translates to:
  /// **'仅一次'**
  String get once;

  /// No description provided for @everyDay.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get everyDay;

  /// No description provided for @workdays.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get workdays;

  /// No description provided for @weekends.
  ///
  /// In zh, this message translates to:
  /// **'周末'**
  String get weekends;

  /// No description provided for @nextRingIn.
  ///
  /// In zh, this message translates to:
  /// **'距下次响铃还有 {time}'**
  String nextRingIn(String time);

  /// No description provided for @allAlarmsResting.
  ///
  /// In zh, this message translates to:
  /// **'所有闹钟都在休息'**
  String get allAlarmsResting;

  /// No description provided for @ringUnderMinute.
  ///
  /// In zh, this message translates to:
  /// **'不到 1 分钟'**
  String get ringUnderMinute;

  /// No description provided for @weekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @weekPrefix.
  ///
  /// In zh, this message translates to:
  /// **'周'**
  String get weekPrefix;

  /// No description provided for @snooze.
  ///
  /// In zh, this message translates to:
  /// **'稍后再响'**
  String get snooze;

  /// No description provided for @stopAlarm.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stopAlarm;

  /// No description provided for @skipNext.
  ///
  /// In zh, this message translates to:
  /// **'跳过下一次'**
  String get skipNext;

  /// No description provided for @resumeNext.
  ///
  /// In zh, this message translates to:
  /// **'恢复下一次'**
  String get resumeNext;

  /// No description provided for @skipNextOn.
  ///
  /// In zh, this message translates to:
  /// **'已跳过下一次响铃'**
  String get skipNextOn;

  /// No description provided for @vibrate.
  ///
  /// In zh, this message translates to:
  /// **'振动'**
  String get vibrate;

  /// No description provided for @snoozeInterval.
  ///
  /// In zh, this message translates to:
  /// **'稍后再响间隔'**
  String get snoozeInterval;

  /// No description provided for @minutesN.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟'**
  String minutesN(int n);

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @alarmNotifBody.
  ///
  /// In zh, this message translates to:
  /// **'到点了，轻点以停止'**
  String get alarmNotifBody;

  /// No description provided for @snoozedToast.
  ///
  /// In zh, this message translates to:
  /// **'好，{n} 分钟后再叫你'**
  String snoozedToast(int n);

  /// No description provided for @timerTitle.
  ///
  /// In zh, this message translates to:
  /// **'计时器'**
  String get timerTitle;

  /// No description provided for @noTimers.
  ///
  /// In zh, this message translates to:
  /// **'没有正在进行的计时。倒一杯茶，从这里开始。'**
  String get noTimers;

  /// No description provided for @newTimer.
  ///
  /// In zh, this message translates to:
  /// **'新建计时'**
  String get newTimer;

  /// No description provided for @timerDone.
  ///
  /// In zh, this message translates to:
  /// **'时间到'**
  String get timerDone;

  /// No description provided for @timerNotifBody.
  ///
  /// In zh, this message translates to:
  /// **'「{label}」的时间到了'**
  String timerNotifBody(String label);

  /// No description provided for @timerNotifBodyPlain.
  ///
  /// In zh, this message translates to:
  /// **'计时结束'**
  String get timerNotifBodyPlain;

  /// No description provided for @timerLabelHint.
  ///
  /// In zh, this message translates to:
  /// **'这段时间留给什么'**
  String get timerLabelHint;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'复位'**
  String get reset;

  /// No description provided for @plusOneMinute.
  ///
  /// In zh, this message translates to:
  /// **'+1 分钟'**
  String get plusOneMinute;

  /// No description provided for @lap.
  ///
  /// In zh, this message translates to:
  /// **'计次'**
  String get lap;

  /// No description provided for @lapN.
  ///
  /// In zh, this message translates to:
  /// **'第 {n} 次'**
  String lapN(int n);

  /// No description provided for @fastest.
  ///
  /// In zh, this message translates to:
  /// **'最快'**
  String get fastest;

  /// No description provided for @slowest.
  ///
  /// In zh, this message translates to:
  /// **'最慢'**
  String get slowest;

  /// No description provided for @stopwatchHint.
  ///
  /// In zh, this message translates to:
  /// **'按下开始，让这一段有个记号。'**
  String get stopwatchHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
