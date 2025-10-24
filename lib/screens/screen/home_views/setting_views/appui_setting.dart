import 'package:bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:bloomee/model/source_engines.dart';
import 'package:bloomee/repository/LastFM/lastfmapi.dart';
import 'package:bloomee/screens/screen/chart/show_charts.dart';
import 'package:bloomee/screens/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppUISettings extends StatefulWidget {
  const AppUISettings({super.key});

  @override
  State<AppUISettings> createState() => _AppUISettingsState();
}

class _AppUISettingsState extends State<AppUISettings> {
  List<bool> sourceEngineSwitches =
      SourceEngine.values.map((e) => true).toList();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'UI & Services Settings',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              SwitchListTile(
                  value: state.autoSlideCharts,
                  subtitle: Text(
                    "Slide charts automatically in home screen.",
                    style: TextStyle(
                            color: DefaultTheme.primaryColor1.withOpacity(0.5),
                            fontSize: 12)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Auto slide charts",
                    style: const TextStyle(
                            color: DefaultTheme.primaryColor1, fontSize: 16)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoSlideCharts(value);
                  }),
              SwitchListTile(
                  value: state.lFMPicks,
                  subtitle: Text(
                    "Suggestions from Last.FM will be shown in the home screen. (Login & Restart required)",
                    style: TextStyle(
                            color: DefaultTheme.primaryColor1.withOpacity(0.5),
                            fontSize: 12)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Last.FM Suggested Picks",
                    style: const TextStyle(
                            color: DefaultTheme.primaryColor1, fontSize: 16)
                        .merge(DefaultTheme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setLastFMExpore(value);
                    if (value && LastFmAPI.initialized == false) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        context.read<SettingsCubit>().setLastFMExpore(false);
                      });
                      SnackbarService.showMessage(
                          "Please login to Last.FM first.");
                    }
                  }),
              ExpansionTile(
                title: Text(
                  "Source Engines",
                  style: const TextStyle(
                          color: DefaultTheme.primaryColor1, fontSize: 16)
                      .merge(DefaultTheme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the source engines you want to use for Music search. (Restart required)",
                  style: TextStyle(
                          color: DefaultTheme.primaryColor1.withOpacity(0.5),
                          fontSize: 12)
                      .merge(DefaultTheme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: DefaultTheme.primaryColor1,
                children: SourceEngine.values.map((e) {
                  if (e == SourceEngine.eng_YTM) return Container();
                  return SwitchListTile(
                      value: state
                          .sourceEngineSwitches[SourceEngine.values.indexOf(e)],
                      title: Text(
                        e.value,
                        style: const TextStyle(
                                color: DefaultTheme.primaryColor1,
                                fontSize: 17)
                            .merge(DefaultTheme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setSourceEngineSwitches(
                            SourceEngine.values.indexOf(e), b);
                      });
                }).toList(),
              ),
              ExpansionTile(
                title: Text(
                  "Allowed Chart Sources",
                  style: const TextStyle(
                          color: DefaultTheme.primaryColor1, fontSize: 16)
                      .merge(DefaultTheme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the chart sources you want to see in the home screen.",
                  style: TextStyle(
                          color: DefaultTheme.primaryColor1.withOpacity(0.5),
                          fontSize: 12)
                      .merge(DefaultTheme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: DefaultTheme.primaryColor1,
                children: chartInfoList.map((e) {
                  return SwitchListTile(
                      value: state.chartMap[e.title] ?? true,
                      title: Text(
                        e.title,
                        style: const TextStyle(
                                color: DefaultTheme.primaryColor1,
                                fontSize: 17)
                            .merge(DefaultTheme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setChartShow(e.title, b);
                      });
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
