import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/world_city.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../util/format.dart';
import '../widgets/analog_clock.dart';
import '../widgets/ink_glyphs.dart';
import '../widgets/ink_kit.dart';
import 'city_picker_page.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({super.key, required this.store});

  final ClockStore store;

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  late DateTime _now;
  Timer? _ticker;
  final Map<String, tz.Location> _locations = <String, tz.Location>{};

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final DateTime now = DateTime.now();
      if (now.second != _now.second) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  tz.Location? _locationOf(String tzId) {
    if (_locations.containsKey(tzId)) return _locations[tzId];
    try {
      final tz.Location loc = tz.getLocation(tzId);
      _locations[tzId] = loc;
      return loc;
    } catch (_) {
      return null;
    }
  }

  String _chapterName(AppLocalizations l10n, Chapter c) {
    switch (c) {
      case Chapter.dawn:
        return l10n.chapterDawn;
      case Chapter.day:
        return l10n.chapterDay;
      case Chapter.dusk:
        return l10n.chapterDusk;
      case Chapter.night:
        return l10n.chapterNight;
    }
  }

  String _verse(AppLocalizations l10n, Chapter c) {
    switch (c) {
      case Chapter.dawn:
        return l10n.verseDawn;
      case Chapter.day:
        return l10n.verseDay;
      case Chapter.dusk:
        return l10n.verseDusk;
      case Chapter.night:
        return l10n.verseNight;
    }
  }

  String _weekdayChar(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.weekdayMon;
      case DateTime.tuesday:
        return l10n.weekdayTue;
      case DateTime.wednesday:
        return l10n.weekdayWed;
      case DateTime.thursday:
        return l10n.weekdayThu;
      case DateTime.friday:
        return l10n.weekdayFri;
      case DateTime.saturday:
        return l10n.weekdaySat;
      default:
        return l10n.weekdaySun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final Chapter chapter = ChapterTheme.of(context).chapter;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    final String dateLine =
        '${_now.month}${l10n.monthUnit}${_now.day}${l10n.dayUnit}'
        ' ${l10n.weekFull}${_weekdayChar(l10n, _now.weekday)}';

    final int displayHour =
        use24h ? _now.hour : ((_now.hour + 11) % 12 + 1);
    final String meridiem = _now.hour < 12 ? l10n.morning : l10n.afternoon;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (BuildContext context, _) {
        final List<WorldCity> cities = widget.store.cities;
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dateLine,
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: p.faded,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: <Widget>[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 26),
                            child: AnalogClock(time: _now),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 12,
                          child:
                              ChapterTag(text: _chapterName(l10n, chapter)),
                        ),
                      ],
                    ),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              if (!use24h)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    meridiem,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: p.faded,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              Text(
                                '${two(displayHour)}:${two(_now.minute)}',
                                style: TextStyle(
                                  fontSize: 62,
                                  height: 1,
                                  fontWeight: FontWeight.w200,
                                  letterSpacing: 2,
                                  color: p.ink,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  two(_now.second),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: p.accent,
                                    fontWeight: FontWeight.w400,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _verse(l10n, chapter),
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 1.5,
                              color: p.faded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.worldClock,
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CityPickerPage(store: widget.store),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child:
                                InkGlyph(Glyph.plus, size: 22, color: p.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemCount: cities.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Hairline(),
              ),
              itemBuilder: (BuildContext context, int index) {
                final WorldCity city = cities[index];
                return _CityRow(
                  city: city,
                  now: _now,
                  location: _locationOf(city.tzId),
                  use24h: use24h,
                  onRemove: () => widget.store.removeCity(city),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 30, bottom: 24),
                child: Center(child: Seal()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.now,
    required this.location,
    required this.use24h,
    required this.onRemove,
  });

  final WorldCity city;
  final DateTime now;
  final tz.Location? location;
  final bool use24h;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool traditional =
        Localizations.localeOf(context).scriptCode == 'Hant';

    final tz.Location? loc = location;
    if (loc == null) return const SizedBox.shrink();
    final tz.TZDateTime there = tz.TZDateTime.from(now, loc);

    final Duration offset =
        there.timeZoneOffset - now.timeZoneOffset;
    String dayLabel = l10n.sameDay;
    if (there.day != now.day) {
      final DateTime localDate = DateTime(now.year, now.month, now.day);
      final DateTime thereDate = DateTime(there.year, there.month, there.day);
      dayLabel =
          thereDate.isAfter(localDate) ? l10n.nextDay : l10n.prevDay;
    }
    final bool daylight = there.hour >= 6 && there.hour < 18;
    final int displayHour =
        use24h ? there.hour : ((there.hour + 11) % 12 + 1);
    final String meridiem =
        there.hour < 12 ? l10n.morning : l10n.afternoon;

    return Dismissible(
      key: ValueKey<String>('city-${city.tzId}-${city.latin}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: p.accent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Text(
          l10n.remove,
          style: TextStyle(color: p.paper, letterSpacing: 2, fontSize: 14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
        child: Row(
          children: <Widget>[
            InkGlyph(
              daylight ? Glyph.sun : Glyph.moon,
              size: 17,
              color: daylight ? p.accent : p.faded,
              strokeWidth: 1.4,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    city.nameFor(traditional),
                    style: TextStyle(
                      fontSize: 16.5,
                      color: p.ink,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dayLabel · ${describeOffset(l10n, offset)}',
                    style: TextStyle(fontSize: 12, color: p.faded),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                if (!use24h)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      meridiem,
                      style: TextStyle(fontSize: 11, color: p.faded),
                    ),
                  ),
                Text(
                  '${two(displayHour)}:${two(there.minute)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: p.ink,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
