/// 世界時鐘城市目錄。名稱依語言動態取簡體或繁體，
/// latin 欄位供拼音／英文搜尋。
class WorldCity {
  const WorldCity(this.tzId, this.hans, this.hant, this.latin);

  final String tzId;
  final String hans;
  final String hant;
  final String latin;

  String nameFor(bool traditional) => traditional ? hant : hans;

  bool matches(String query, bool traditional) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return hans.contains(q) ||
        hant.contains(q) ||
        latin.toLowerCase().contains(q);
  }
}

const List<WorldCity> worldCityCatalog = <WorldCity>[
  WorldCity('Asia/Shanghai', '北京', '北京', 'Beijing'),
  WorldCity('Asia/Shanghai', '上海', '上海', 'Shanghai'),
  WorldCity('Asia/Hong_Kong', '香港', '香港', 'Hong Kong'),
  WorldCity('Asia/Macau', '澳门', '澳門', 'Macau'),
  WorldCity('Asia/Taipei', '台北', '台北', 'Taipei'),
  WorldCity('Asia/Tokyo', '东京', '東京', 'Tokyo'),
  WorldCity('Asia/Seoul', '首尔', '首爾', 'Seoul'),
  WorldCity('Asia/Singapore', '新加坡', '新加坡', 'Singapore'),
  WorldCity('Asia/Kuala_Lumpur', '吉隆坡', '吉隆坡', 'Kuala Lumpur'),
  WorldCity('Asia/Bangkok', '曼谷', '曼谷', 'Bangkok'),
  WorldCity('Asia/Jakarta', '雅加达', '雅加達', 'Jakarta'),
  WorldCity('Asia/Manila', '马尼拉', '馬尼拉', 'Manila'),
  WorldCity('Asia/Ho_Chi_Minh', '胡志明市', '胡志明市', 'Ho Chi Minh'),
  WorldCity('Asia/Yangon', '仰光', '仰光', 'Yangon'),
  WorldCity('Asia/Dhaka', '达卡', '達卡', 'Dhaka'),
  WorldCity('Asia/Kolkata', '新德里', '新德里', 'New Delhi'),
  WorldCity('Asia/Karachi', '卡拉奇', '卡拉奇', 'Karachi'),
  WorldCity('Asia/Dubai', '迪拜', '杜拜', 'Dubai'),
  WorldCity('Asia/Riyadh', '利雅得', '利雅德', 'Riyadh'),
  WorldCity('Asia/Tehran', '德黑兰', '德黑蘭', 'Tehran'),
  WorldCity('Asia/Almaty', '阿拉木图', '阿拉木圖', 'Almaty'),
  WorldCity('Asia/Kathmandu', '加德满都', '加德滿都', 'Kathmandu'),
  WorldCity('Europe/Istanbul', '伊斯坦布尔', '伊斯坦堡', 'Istanbul'),
  WorldCity('Europe/Moscow', '莫斯科', '莫斯科', 'Moscow'),
  WorldCity('Europe/Athens', '雅典', '雅典', 'Athens'),
  WorldCity('Europe/Helsinki', '赫尔辛基', '赫爾辛基', 'Helsinki'),
  WorldCity('Europe/Berlin', '柏林', '柏林', 'Berlin'),
  WorldCity('Europe/Paris', '巴黎', '巴黎', 'Paris'),
  WorldCity('Europe/Rome', '罗马', '羅馬', 'Rome'),
  WorldCity('Europe/Madrid', '马德里', '馬德里', 'Madrid'),
  WorldCity('Europe/Amsterdam', '阿姆斯特丹', '阿姆斯特丹', 'Amsterdam'),
  WorldCity('Europe/Zurich', '苏黎世', '蘇黎世', 'Zurich'),
  WorldCity('Europe/Stockholm', '斯德哥尔摩', '斯德哥爾摩', 'Stockholm'),
  WorldCity('Europe/London', '伦敦', '倫敦', 'London'),
  WorldCity('Europe/Lisbon', '里斯本', '里斯本', 'Lisbon'),
  WorldCity('Africa/Cairo', '开罗', '開羅', 'Cairo'),
  WorldCity('Africa/Nairobi', '内罗毕', '奈洛比', 'Nairobi'),
  WorldCity('Africa/Johannesburg', '约翰内斯堡', '約翰尼斯堡', 'Johannesburg'),
  WorldCity('Africa/Lagos', '拉各斯', '拉哥斯', 'Lagos'),
  WorldCity('Australia/Sydney', '悉尼', '雪梨', 'Sydney'),
  WorldCity('Australia/Melbourne', '墨尔本', '墨爾本', 'Melbourne'),
  WorldCity('Australia/Perth', '珀斯', '伯斯', 'Perth'),
  WorldCity('Pacific/Auckland', '奥克兰', '奧克蘭', 'Auckland'),
  WorldCity('America/New_York', '纽约', '紐約', 'New York'),
  WorldCity('America/Toronto', '多伦多', '多倫多', 'Toronto'),
  WorldCity('America/Chicago', '芝加哥', '芝加哥', 'Chicago'),
  WorldCity('America/Denver', '丹佛', '丹佛', 'Denver'),
  WorldCity('America/Los_Angeles', '洛杉矶', '洛杉磯', 'Los Angeles'),
  WorldCity('America/Vancouver', '温哥华', '溫哥華', 'Vancouver'),
  WorldCity('America/Mexico_City', '墨西哥城', '墨西哥城', 'Mexico City'),
  WorldCity('America/Sao_Paulo', '圣保罗', '聖保羅', 'Sao Paulo'),
  WorldCity('America/Argentina/Buenos_Aires', '布宜诺斯艾利斯', '布宜諾斯艾利斯',
      'Buenos Aires'),
  WorldCity('Pacific/Honolulu', '檀香山', '檀香山', 'Honolulu'),
  WorldCity('UTC', '协调世界时', '協調世界時', 'UTC'),
];

WorldCity? cityByKey(String key) {
  for (final WorldCity c in worldCityCatalog) {
    if ('${c.tzId}|${c.latin}' == key) return c;
  }
  return null;
}

String cityKey(WorldCity city) => '${city.tzId}|${city.latin}';
