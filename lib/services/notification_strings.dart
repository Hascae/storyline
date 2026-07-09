/// 通知文案。由 UI 層在語言解析完成後注入，
/// 讓排程出去的通知永遠跟隨系統語言。
class NotificationStrings {
  String alarmDefaultTitle = '鬧鐘';
  String alarmBody = '到點了，輕點以停止';
  String snoozeAction = '稍後再響';
  String stopAction = '停止';
  String timerDoneTitle = '時間到';
  String timerDoneBody = '計時結束';
  String timerChannelName = '計時器';
  String timerChannelDescription = '計時完成提醒';
  String ringChannelName = '響鈴控制';
  String ringChannelDescription = '響鈴時的稍後再響／停止';
}
