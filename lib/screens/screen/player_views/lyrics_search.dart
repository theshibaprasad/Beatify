import 'package:bloomee/blocs/lyrics/lyrics_cubit.dart';
import 'package:bloomee/model/lyrics_models.dart';
import 'package:bloomee/repository/Lyrics/lyrics.dart';
import 'package:bloomee/screens/widgets/sign_board_widget.dart';
import 'package:bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class LyricsSearchDelegate extends SearchDelegate {
  final String mediaID;
  @override
  String? get searchFieldLabel => "Lyrics title...";

  List<Lyrics> lyrics = [];

  LyricsSearchDelegate(
      {super.searchFieldLabel,
      super.searchFieldStyle,
      super.searchFieldDecorationTheme,
      super.keyboardType,
      super.textInputAction,
      required this.mediaID});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        backgroundColor: Color.fromARGB(255, 19, 19, 19),
        iconTheme: IconThemeData(color: DefaultTheme.primaryColor1),
      ),
      textTheme: TextTheme(
        titleLarge: const TextStyle(
          color: DefaultTheme.primaryColor1,
        ).merge(DefaultTheme.secondoryTextStyleMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: DefaultTheme.primaryColor2.withOpacity(0.3),
        ).merge(DefaultTheme.secondoryTextStyle),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(MingCute.close_fill))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(MingCute.arrow_left_fill),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: LyricsRepository.searchLyrics(query, ""),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
              child: CircularProgressIndicator(
            color: DefaultTheme.accentColor2,
          ));
        } else if (snapshot.data!.isEmpty) {
          return const Center(
            child: SignBoardWidget(
                message: "No Results found!", icon: MingCute.look_up_line),
          );
        } else {
          lyrics = snapshot.data as List<Lyrics>;

          return ListView.builder(
            itemCount: lyrics.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  lyrics[index].title,
                  style:
                      const TextStyle(color: DefaultTheme.primaryColor1).merge(
                    DefaultTheme.secondoryTextStyleMedium,
                  ),
                ),
                subtitle: Text(
                  lyrics[index].artist,
                  style: TextStyle(
                          color: DefaultTheme.primaryColor1.withOpacity(0.7))
                      .merge(
                    DefaultTheme.secondoryTextStyle,
                  ),
                ),
                trailing: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lyrics[index].title,
                                    style: DefaultTheme
                                        .secondoryTextStyleMedium
                                        .copyWith(
                                      color: DefaultTheme.primaryColor1
                                          .withOpacity(0.8),
                                    )),
                                Text(lyrics[index].artist,
                                    style: TextStyle(
                                      color: DefaultTheme.primaryColor1
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ).merge(
                                      DefaultTheme.secondoryTextStyle,
                                    )),
                                Text(
                                    "Synced: ${lyrics[index].lyricsSynced == null ? "No" : "Yes"}",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                              255, 139, 255, 191)
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ).merge(
                                      DefaultTheme.secondoryTextStyleMedium,
                                    )),
                              ],
                            ),
                            content: SingleChildScrollView(
                                child: Text(
                              lyrics[index].lyricsPlain,
                              style: DefaultTheme.secondoryTextStyleMedium
                                  .copyWith(
                                color: DefaultTheme.primaryColor1
                                    .withOpacity(0.7),
                              ),
                            )),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text("View Lyrics")),
                onTap: () {
                  context
                      .read<LyricsCubit>()
                      .setLyricsToDB(lyrics[index], mediaID);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: LyricsRepository.searchLyrics(query, ""),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
              child: CircularProgressIndicator(
            color: DefaultTheme.accentColor2,
          ));
        } else if (snapshot.data!.isEmpty) {
          return const Center(
            child: SignBoardWidget(
                message: "No Suggestions found!", icon: MingCute.look_up_line),
          );
        } else {
          lyrics = snapshot.data as List<Lyrics>;

          return ListView.builder(
            itemCount: lyrics.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  lyrics[index].title,
                  style:
                      const TextStyle(color: DefaultTheme.primaryColor1).merge(
                    DefaultTheme.secondoryTextStyleMedium,
                  ),
                ),
                subtitle: Text(
                  lyrics[index].artist,
                  style: TextStyle(
                          color: DefaultTheme.primaryColor1.withOpacity(0.7))
                      .merge(
                    DefaultTheme.secondoryTextStyle,
                  ),
                ),
                trailing: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lyrics[index].title,
                                    style: DefaultTheme
                                        .secondoryTextStyleMedium
                                        .copyWith(
                                      color: DefaultTheme.primaryColor1
                                          .withOpacity(0.8),
                                    )),
                                Text(lyrics[index].artist,
                                    style: TextStyle(
                                      color: DefaultTheme.primaryColor1
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ).merge(
                                      DefaultTheme.secondoryTextStyle,
                                    )),
                                Text(
                                    "Synced: ${lyrics[index].lyricsSynced == null ? "No" : "Yes"}",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                              255, 139, 255, 191)
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ).merge(
                                      DefaultTheme.secondoryTextStyleMedium,
                                    )),
                              ],
                            ),
                            content: SingleChildScrollView(
                                child: Text(
                              lyrics[index].lyricsPlain,
                              style: DefaultTheme.secondoryTextStyleMedium
                                  .copyWith(
                                color: DefaultTheme.primaryColor1
                                    .withOpacity(0.7),
                              ),
                            )),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text("View Lyrics")),
                onTap: () {
                  context
                      .read<LyricsCubit>()
                      .setLyricsToDB(lyrics[index], mediaID);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }
      },
    );
  }
}
