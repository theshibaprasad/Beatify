// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/utils/imgurl_formator.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';

class SongInfoScreen extends StatelessWidget {
  final MediaItemModel song;
  const SongInfoScreen({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: LoadImageCached(
                  imageUrl:
                      formatImgURL(song.artUri.toString(), ImageQuality.high)),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoTile(
                  title: "Title",
                  subtitle: song.title,
                  icon: Icons.music_note,
                ),
                InfoTile(
                  icon: MingCute.microphone_fill,
                  title: "Artist",
                  subtitle: song.artist ?? 'Unknown',
                ),
                InfoTile(
                  title: "Album",
                  subtitle: song.album ?? 'Unknown',
                  icon: MingCute.album_fill,
                ),
                InfoTile(
                  icon: MingCute.time_fill,
                  title: "Duration",
                  subtitle: song.duration != null
                      ? '${song.duration?.inMinutes ?? '00'}:${song.duration!.inSeconds % 60}'
                      : "00:00",
                ),
                InfoTile(
                  title: "Language",
                  subtitle: song.extras!["language"] ?? "Unknown",
                  icon: Icons.language,
                ),
                InfoTile(
                  title: "Source",
                  subtitle: song.extras!["source"] != null
                      ? (song.extras!['source'] == "youtube"
                          ? "Youtube"
                          : "JioSaavn")
                      : "Unknown",
                  icon: MingCute.server_fill,
                ),
                InfoTile(
                    title: "MediaID",
                    subtitle: song.id,
                    icon: MingCute.IDcard_fill),
                Tooltip(
                  message: "Copy Link to Clipboard",
                  child: InfoTile(
                    title: "Original Source",
                    subtitle: song.extras!["perma_url"] ?? "Unknown",
                    icon: MingCute.link_3_fill,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: song.extras!["perma_url"]));
                      SnackbarService.showMessage("Link Copied to Clipboard.");
                    },
                  ),
                ),
              ],
            ),
          ])),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  const InfoTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(
        icon,
        color: Default_Theme.primaryColor1,
      ),
      title: Text(
        title,
        style: Default_Theme.secondoryTextStyle.merge(TextStyle(
            color: Default_Theme.primaryColor1.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.bold)),
      ),
      subtitle: Text(
        subtitle,
        style: Default_Theme.secondoryTextStyle.merge(const TextStyle(
            color: Default_Theme.primaryColor1,
            fontWeight: FontWeight.bold,
            fontSize: 16)),
      ),
    );
  }
}
