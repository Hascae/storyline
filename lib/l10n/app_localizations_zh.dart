// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '物语时钟';

  @override
  String get tabClock => '时钟';

  @override
  String get tabAlarm => '闹钟';

  @override
  String get tabTimer => '计时';

  @override
  String get tabStopwatch => '秒表';

  @override
  String get chapterDawn => '晨之章';

  @override
  String get chapterDay => '昼之章';

  @override
  String get chapterDusk => '暮之章';

  @override
  String get chapterNight => '夜之章';

  @override
  String get verseDawn => '晨光初染，故事翻开新的一页。';

  @override
  String get verseDay => '日色正好，时间缓缓向前。';

  @override
  String get verseDusk => '暮色四合，这一章将尽未尽。';

  @override
  String get verseNight => '夜幕低垂，故事仍在低语。';

  @override
  String get worldClock => '世界时钟';

  @override
  String get addCity => '添加城市';

  @override
  String get searchCityHint => '搜索城市或地区';

  @override
  String get remove => '移除';

  @override
  String get sameDay => '今天';

  @override
  String get nextDay => '明天';

  @override
  String get prevDay => '昨天';

  @override
  String get sameAsLocal => '与本地同步';

  @override
  String aheadBy(String diff) {
    return '快 $diff';
  }

  @override
  String behindBy(String diff) {
    return '慢 $diff';
  }

  @override
  String get monthUnit => '月';

  @override
  String get dayUnit => '日';

  @override
  String get weekFull => '星期';

  @override
  String get hourUnit => '小时';

  @override
  String get minuteUnit => '分';

  @override
  String get secondUnit => '秒';

  @override
  String get halfHourUnit => '半';

  @override
  String get morning => '上午';

  @override
  String get afternoon => '下午';

  @override
  String get noAlarms => '还没有闹钟。夜里安静，也别忘了明早的约定。';

  @override
  String get addAlarm => '添加闹钟';

  @override
  String get editAlarm => '编辑闹钟';

  @override
  String get alarmDefaultName => '闹钟';

  @override
  String get alarmLabelHint => '给这声铃一个名字';

  @override
  String get once => '仅一次';

  @override
  String get everyDay => '每天';

  @override
  String get workdays => '工作日';

  @override
  String get weekends => '周末';

  @override
  String nextRingIn(String time) {
    return '距下次响铃还有 $time';
  }

  @override
  String get allAlarmsResting => '所有闹钟都在休息';

  @override
  String get ringUnderMinute => '不到 1 分钟';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get weekPrefix => '周';

  @override
  String get snooze => '稍后再响';

  @override
  String get stopAlarm => '停止';

  @override
  String get skipNext => '跳过下一次';

  @override
  String get resumeNext => '恢复下一次';

  @override
  String get skipNextOn => '已跳过下一次响铃';

  @override
  String get vibrate => '振动';

  @override
  String get snoozeInterval => '稍后再响间隔';

  @override
  String minutesN(int n) {
    return '$n 分钟';
  }

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get alarmNotifBody => '到点了，轻点以停止';

  @override
  String snoozedToast(int n) {
    return '好，$n 分钟后再叫你';
  }

  @override
  String get timerTitle => '计时器';

  @override
  String get noTimers => '没有正在进行的计时。倒一杯茶，从这里开始。';

  @override
  String get newTimer => '新建计时';

  @override
  String get timerDone => '时间到';

  @override
  String timerNotifBody(String label) {
    return '「$label」的时间到了';
  }

  @override
  String get timerNotifBodyPlain => '计时结束';

  @override
  String get timerLabelHint => '这段时间留给什么';

  @override
  String get start => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get reset => '复位';

  @override
  String get plusOneMinute => '+1 分钟';

  @override
  String get lap => '计次';

  @override
  String lapN(int n) {
    return '第 $n 次';
  }

  @override
  String get fastest => '最快';

  @override
  String get slowest => '最慢';

  @override
  String get stopwatchHint => '按下开始，让这一段有个记号。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '物語時鐘';

  @override
  String get tabClock => '時鐘';

  @override
  String get tabAlarm => '鬧鐘';

  @override
  String get tabTimer => '計時';

  @override
  String get tabStopwatch => '碼錶';

  @override
  String get chapterDawn => '晨之章';

  @override
  String get chapterDay => '晝之章';

  @override
  String get chapterDusk => '暮之章';

  @override
  String get chapterNight => '夜之章';

  @override
  String get verseDawn => '晨光初染，故事翻開新的一頁。';

  @override
  String get verseDay => '日色正好，時間緩緩向前。';

  @override
  String get verseDusk => '暮色四合，這一章將盡未盡。';

  @override
  String get verseNight => '夜幕低垂，故事仍在低語。';

  @override
  String get worldClock => '世界時鐘';

  @override
  String get addCity => '新增城市';

  @override
  String get searchCityHint => '搜尋城市或地區';

  @override
  String get remove => '移除';

  @override
  String get sameDay => '今天';

  @override
  String get nextDay => '明天';

  @override
  String get prevDay => '昨天';

  @override
  String get sameAsLocal => '與本地同步';

  @override
  String aheadBy(String diff) {
    return '快 $diff';
  }

  @override
  String behindBy(String diff) {
    return '慢 $diff';
  }

  @override
  String get monthUnit => '月';

  @override
  String get dayUnit => '日';

  @override
  String get weekFull => '星期';

  @override
  String get hourUnit => '小時';

  @override
  String get minuteUnit => '分';

  @override
  String get secondUnit => '秒';

  @override
  String get halfHourUnit => '半';

  @override
  String get morning => '上午';

  @override
  String get afternoon => '下午';

  @override
  String get noAlarms => '還沒有鬧鐘。夜裡安靜，也別忘了明早的約定。';

  @override
  String get addAlarm => '新增鬧鐘';

  @override
  String get editAlarm => '編輯鬧鐘';

  @override
  String get alarmDefaultName => '鬧鐘';

  @override
  String get alarmLabelHint => '給這聲鈴一個名字';

  @override
  String get once => '僅一次';

  @override
  String get everyDay => '每天';

  @override
  String get workdays => '平日';

  @override
  String get weekends => '週末';

  @override
  String nextRingIn(String time) {
    return '距下次響鈴還有 $time';
  }

  @override
  String get allAlarmsResting => '所有鬧鐘都在休息';

  @override
  String get ringUnderMinute => '不到 1 分鐘';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get weekPrefix => '週';

  @override
  String get snooze => '稍後再響';

  @override
  String get stopAlarm => '停止';

  @override
  String get skipNext => '跳過下一次';

  @override
  String get resumeNext => '恢復下一次';

  @override
  String get skipNextOn => '已跳過下一次響鈴';

  @override
  String get vibrate => '震動';

  @override
  String get snoozeInterval => '稍後再響間隔';

  @override
  String minutesN(int n) {
    return '$n 分鐘';
  }

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get alarmNotifBody => '到點了，輕點以停止';

  @override
  String snoozedToast(int n) {
    return '好，$n 分鐘後再叫你';
  }

  @override
  String get timerTitle => '計時器';

  @override
  String get noTimers => '沒有進行中的計時。倒一杯茶，從這裡開始。';

  @override
  String get newTimer => '新增計時';

  @override
  String get timerDone => '時間到';

  @override
  String timerNotifBody(String label) {
    return '「$label」的時間到了';
  }

  @override
  String get timerNotifBodyPlain => '計時結束';

  @override
  String get timerLabelHint => '這段時間留給什麼';

  @override
  String get start => '開始';

  @override
  String get pause => '暫停';

  @override
  String get resume => '繼續';

  @override
  String get reset => '歸零';

  @override
  String get plusOneMinute => '+1 分鐘';

  @override
  String get lap => '計次';

  @override
  String lapN(int n) {
    return '第 $n 次';
  }

  @override
  String get fastest => '最快';

  @override
  String get slowest => '最慢';

  @override
  String get stopwatchHint => '按下開始，讓這一段有個記號。';
}
