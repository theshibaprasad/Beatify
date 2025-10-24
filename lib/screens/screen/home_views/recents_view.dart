// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloomee/blocs/history/cubit/history_cubit.dart';
import 'package:bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:bloomee/model/MediaPlaylistModel.dart';
import 'package:bloomee/screens/screen/home_views/setting_views/storage_setting.dart';
import 'package:bloomee/screens/widgets/more_bottom_sheet.dart';
import 'package:bloomee/screens/widgets/song_tile.dart';
import 'package:flutter/material.dart';
import 'package:bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                MingCute.settings_1_line,
                color: DefaultTheme.primaryColor1,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupSettings(),
                  ),
                );
              },
            ),
          ],
          title: Text(
            'History',
            style: const TextStyle(
                    color: DefaultTheme.primaryColor1,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)
                .merge(DefaultTheme.secondoryTextStyle),
          ),
        ),
        body: BlocProvider(
          create: (context) => HistoryCubit(),
          child: BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              return (state is HistoryInitial)
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: state.mediaPlaylist.mediaItems.length,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return SongCardWidget(
                          song: state.mediaPlaylist.mediaItems[index],
                          onTap: () {
                            context
                                .read<BloomeePlayerCubit>()
                                .bloomeePlayer
                                .loadPlaylist(
                                    MediaPlaylist(
                                        mediaItems:
                                            state.mediaPlaylist.mediaItems,
                                        playlistName:
                                            state.mediaPlaylist.playlistName),
                                    idx: index,
                                    doPlay: true);
                          },
                          onOptionsTap: () => showMoreBottomSheet(
                              context, state.mediaPlaylist.mediaItems[index]),
                        );
                      },
                    );
            },
          ),
        ),
      ),
    );
  }

  ListTile settingListTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        size: 30,
        color: DefaultTheme.primaryColor1,
      ),
      title: Text(
        title,
        style: const TextStyle(color: DefaultTheme.primaryColor1, fontSize: 17)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: DefaultTheme.primaryColor1.withOpacity(0.5),
                fontSize: 12.5)
            .merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
