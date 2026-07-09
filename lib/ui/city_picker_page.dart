import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/world_city.dart';
import '../services/clock_store.dart';
import '../theme/chapter.dart';
import '../widgets/ink_glyphs.dart';
import '../widgets/ink_kit.dart';

/// 添加世界時鐘城市：搜尋（中文／拼音／英文），輕點即添加或移除。
class CityPickerPage extends StatefulWidget {
  const CityPickerPage({super.key, required this.store});

  final ClockStore store;

  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChapterPalette p = ChapterTheme.of(context).palette;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool traditional =
        Localizations.localeOf(context).scriptCode == 'Hant';

    return Scaffold(
      backgroundColor: p.paper,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (BuildContext context, _) {
            final List<WorldCity> matches = worldCityCatalog
                .where((WorldCity c) => c.matches(_query.text, traditional))
                .toList(growable: false);
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 28, 4),
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: InkGlyph(Glyph.chevronLeft,
                              size: 22, color: p.ink),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.addCity,
                          style: TextStyle(
                            fontSize: 17,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 16,
                      color: p.ink,
                      letterSpacing: 1,
                    ),
                    cursorColor: p.accent,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.searchCityHint,
                      hintStyle: TextStyle(color: p.faded, letterSpacing: 1),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: p.hairline),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: p.accent, width: 1.2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Hairline(),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final WorldCity city = matches[index];
                      final bool added = widget.store.hasCity(city);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (added) {
                            widget.store.removeCity(city);
                          } else {
                            widget.store.addCity(city);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 15),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      city.nameFor(traditional),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: added ? p.faded : p.ink,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      city.latin,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: p.faded,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (added)
                                InkGlyph(Glyph.check,
                                    size: 18, color: p.accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
