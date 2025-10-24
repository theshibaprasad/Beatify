import 'dart:async';
import 'dart:io' as io;
import 'package:bloomee/blocs/downloader/cubit/downloader_cubit.dart';
import 'package:bloomee/blocs/global_events/global_events_cubit.dart';
import 'package:bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:bloomee/blocs/lastdotfm/lastdotfm_cubit.dart';
import 'package:bloomee/blocs/lyrics/lyrics_cubit.dart';
import 'package:bloomee/blocs/mini_player/mini_player_bloc.dart';
import 'package:bloomee/blocs/notification/notification_cubit.dart';
import 'package:bloomee/blocs/search_suggestions/search_suggestion_bloc.dart';
import 'package:bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:bloomee/blocs/timer/timer_bloc.dart';
import 'package:bloomee/repository/Youtube/youtube_api.dart';
import 'package:bloomee/screens/widgets/global_event_listener.dart';
import 'package:bloomee/screens/widgets/snackbar.dart';
import 'package:bloomee/services/db/bloomee_db_service.dart';
import 'package:bloomee/services/shortcuts_intents.dart';
import 'package:bloomee/theme_data/default.dart';
import 'package:bloomee/services/import_export_service.dart';
import 'package:bloomee/utils/external_list_importer.dart';
import 'package:bloomee/utils/ticker.dart';
import 'package:bloomee/utils/url_checker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloomee/blocs/add_to_playlist/cubit/add_to_playlist_cubit.dart';
import 'package:bloomee/blocs/library/cubit/library_items_cubit.dart';
import 'package:bloomee/blocs/search/fetch_search_results.dart';
import 'package:bloomee/routes_and_consts/routes.dart';
import 'package:bloomee/screens/screen/library_views/cubit/current_playlist_cubit.dart';
import 'package:bloomee/screens/screen/library_views/cubit/import_playlist_cubit.dart';
import 'package:bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:bloomee/services/discord_service.dart';
import 'package:bloomee/blocs/jam/jam_cubit.dart';
import 'package:bloomee/services/jam_service.dart';

void processIncomingIntent(SharedMedia sharedMedia) {
  // Check if there's text content that might be a URL
  if (sharedMedia.content != null && isUrl(sharedMedia.content!)) {
    final urlType = getUrlType(sharedMedia.content!);
    switch (urlType) {
      case UrlType.spotifyTrack:
        ExternalMediaImporter.sfyMediaImporter(sharedMedia.content!)
            .then((value) async {
          if (value != null) {
            await bloomeePlayerCubit.bloomeePlayer.addQueueItem(
              value,
            );
          }
        });
        break;
      case UrlType.spotifyPlaylist:
        SnackbarService.showMessage("Import Spotify Playlist from library!");
        break;
      case UrlType.youtubePlaylist:
        SnackbarService.showMessage("Import Youtube Playlist from library!");
        break;
      case UrlType.spotifyAlbum:
        SnackbarService.showMessage("Import Spotify Album from library!");
        break;
      case UrlType.youtubeVideo:
        ExternalMediaImporter.ytMediaImporter(sharedMedia.content!)
            .then((value) async {
          if (value != null) {
            await bloomeePlayerCubit.bloomeePlayer
                .updateQueue([value], doPlay: true);
          }
        });
        break;
      case UrlType.other:
        // Handle as file if it's a file URL
        if (sharedMedia.attachments != null &&
            sharedMedia.attachments!.isNotEmpty) {
          final attachment = sharedMedia.attachments!.first;
          SnackbarService.showMessage("Processing File...");
          importItems(attachment!.path);
        }
    }
  } else if (sharedMedia.attachments != null &&
      sharedMedia.attachments!.isNotEmpty) {
    // Handle attachments
    // todo: handle multiple attachments
  }
}

Future<void> importItems(String path) async {
  bool res = await ImportExportService.importMediaItem(path);
  if (res) {
    SnackbarService.showMessage("Media Item Imported");
  } else {
    res = await ImportExportService.importPlaylist(path);
    if (res) {
      SnackbarService.showMessage("Playlist Imported");
    } else {
      SnackbarService.showMessage("Invalid File Format");
    }
  }
}

Future<void> setHighRefreshRate() async {
  if (io.Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }
}

late BloomeePlayerCubit bloomeePlayerCubit;
void setupPlayerCubit() {
  bloomeePlayerCubit = BloomeePlayerCubit();
}

Future<void> initServices() async {
  String appDocPath = (await getApplicationDocumentsDirectory()).path;
  String appSuppPath = (await getApplicationSupportDirectory()).path;
  BloomeeDBService(appDocPath: appDocPath, appSuppPath: appSuppPath);
  YouTubeServices(appDocPath: appDocPath, appSuppPath: appSuppPath);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;
  if (io.Platform.isLinux || io.Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: true,
    );
  }
  await initServices();
  setHighRefreshRate();
  setupPlayerCubit();
  DiscordService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initialize the player
  // This widget is the root of your application.
  late StreamSubscription _intentSub;
  SharedMedia? sharedMedia;
  @override
  void initState() {
    super.initState();
    if (io.Platform.isAndroid) {
      initPlatformState();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    sharedMedia = await handler.getInitialSharedMedia();

    _intentSub = handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        sharedMedia = media;
      });
      if (sharedMedia != null) {
        processIncomingIntent(sharedMedia!);
      }
    });
    if (!mounted) return;

    setState(() {
      // If there's initial shared media, process it
      if (sharedMedia != null) {
        processIncomingIntent(sharedMedia!);
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    bloomeePlayerCubit.bloomeePlayer.audioPlayer.dispose();
    bloomeePlayerCubit.close();
    if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      DiscordService.clearPresence();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => bloomeePlayerCubit,
          lazy: false,
        ),
        BlocProvider(
            create: (context) =>
                MiniPlayerBloc(playerCubit: bloomeePlayerCubit),
            lazy: true),
        BlocProvider(
          create: (context) => BloomeeDBCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => SettingsCubit(),
          lazy: false,
        ),
        BlocProvider(create: (context) => NotificationCubit(), lazy: false),
        BlocProvider(
            create: (context) => TimerBloc(
                ticker: const Ticker(), bloomeePlayer: bloomeePlayerCubit)),
        BlocProvider(
          create: (context) => ConnectivityCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => CurrentPlaylistCubit(
              bloomeeDBCubit: context.read<BloomeeDBCubit>()),
          lazy: false,
        ),
        BlocProvider(
          create: (context) =>
              LibraryItemsCubit(bloomeeDBCubit: context.read<BloomeeDBCubit>()),
        ),
        BlocProvider(
          create: (context) => AddToPlaylistCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => ImportPlaylistCubit(),
        ),
        BlocProvider(
          create: (context) => FetchSearchResultsCubit(),
        ),
        BlocProvider(create: (context) => SearchSuggestionBloc()),
        BlocProvider(
          create: (context) => LyricsCubit(bloomeePlayerCubit),
        ),
        BlocProvider(
          create: (context) => LastdotfmCubit(playerCubit: bloomeePlayerCubit),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => DownloaderCubit(
            connectivityCubit: context.read<ConnectivityCubit>(),
            libraryItemsCubit: context.read<LibraryItemsCubit>(),
          ),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => GlobalEventsCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => JamCubit(
            jamService: JamService(),
            player: bloomeePlayerCubit.bloomeePlayer,
          ),
          lazy: false,
        ),
      ],
      child: BlocBuilder<BloomeePlayerCubit, BloomeePlayerState>(
        builder: (context, state) {
          if (state is BloomeePlayerInitial) {
            return const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return MaterialApp.router(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.space):
                    const PlayPauseIntent(),
                LogicalKeySet(LogicalKeyboardKey.mediaPlayPause):
                    const PlayPauseIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                    const PreviousIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowRight):
                    const NextIntent(),
                LogicalKeySet(LogicalKeyboardKey.keyR): const RepeatIntent(),
                LogicalKeySet(LogicalKeyboardKey.keyL): const LikeIntent(),
                LogicalKeySet(
                        LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.alt):
                    const NSecForwardIntent(),
                LogicalKeySet(
                        LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.alt):
                    const NSecBackwardIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowUp):
                    const VolumeUpIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowDown):
                    const VolumeDownIntent(),
              },
              actions: {
                PlayPauseIntent: CallbackAction(onInvoke: (intent) {
                  if (context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .audioPlayer
                      .playing) {
                    context
                        .read<BloomeePlayerCubit>()
                        .bloomeePlayer
                        .audioPlayer
                        .pause();
                  } else {
                    context
                        .read<BloomeePlayerCubit>()
                        .bloomeePlayer
                        .audioPlayer
                        .play();
                  }
                  return null;
                }),
                NextIntent: CallbackAction(onInvoke: (intent) {
                  context.read<BloomeePlayerCubit>().bloomeePlayer.skipToNext();
                  return null;
                }),
                PreviousIntent: CallbackAction(onInvoke: (intent) {
                  context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .skipToPrevious();
                  return null;
                }),
                NSecForwardIntent: CallbackAction(onInvoke: (intent) {
                  context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .seekNSecForward(const Duration(seconds: 5));
                  return null;
                }),
                NSecBackwardIntent: CallbackAction(onInvoke: (intent) {
                  context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .seekNSecBackward(const Duration(seconds: 5));
                  return null;
                }),
                VolumeUpIntent: CallbackAction(onInvoke: (intent) {
                  context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .audioPlayer
                      .setVolume((context
                                  .read<BloomeePlayerCubit>()
                                  .bloomeePlayer
                                  .audioPlayer
                                  .volume +
                              0.1)
                          .clamp(0.0, 1.0));
                  return null;
                }),
                VolumeDownIntent: CallbackAction(onInvoke: (intent) {
                  context
                      .read<BloomeePlayerCubit>()
                      .bloomeePlayer
                      .audioPlayer
                      .setVolume((context
                                  .read<BloomeePlayerCubit>()
                                  .bloomeePlayer
                                  .audioPlayer
                                  .volume -
                              0.1)
                          .clamp(0.0, 1.0));
                  return null;
                }),
              },
              builder: (context, child) => ResponsiveBreakpoints.builder(
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  const Breakpoint(
                      start: 1921, end: double.infinity, name: '4K'),
                ],
                child: GlobalEventListener(
                  child: child!,
                  navigatorKey: GlobalRoutes.globalRouterKey,
                ),
              ),
              scaffoldMessengerKey: SnackbarService.messengerKey,
              routerConfig: GlobalRoutes.globalRouter,
              theme: DefaultTheme().defaultThemeData,
              scrollBehavior: CustomScrollBehavior(),
              debugShowCheckedModeBanner: false,
            );
          }
        },
      ),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
