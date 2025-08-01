import 'dart:io';
import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/country_picker_dialog.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/web_symbols_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alchemy/api/definitions.dart';
import 'package:alchemy/api/download.dart';
import 'package:alchemy/ui/log_screen.dart';
import 'package:scrobblenaut/scrobblenaut.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:alchemy/fonts/alchemy_icons.dart';
import 'package:figma_squircle/figma_squircle.dart';

import '../api/importer.dart';
import '../ui/importer_screen.dart';
import '../api/cache.dart';
import '../api/deezer.dart';
import '../main.dart';
import '../utils/env.dart';
import '../service/audio_service.dart';
import '../settings.dart';
import '../translations.i18n.dart';
import '../ui/downloads_screen.dart';
import '../ui/elements.dart';
import '../ui/error.dart';
import '../ui/home_screen.dart';
import '../ui/updater.dart';
import '../utils/file_utils.dart';

String sanitize(String input) {
  RegExp sanitize = RegExp(r'[\/\\\?\%\*\:\|\"\<\>]');
  return input.replaceAll(sanitize, '');
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

String generateFilename(Track track) {
  String path = settings.downloadPath ?? '';

  if (settings.artistFolder) path = p.join(path, '%albumArtist%');

  //Album folder / with disk number
  if (settings.albumFolder) {
    if (settings.albumDiscFolder) {
      path = p.join(
          path, '%album%' + ' - Disk ' + (track.diskNumber ?? 1).toString());
    } else {
      path = p.join(path, '%album%');
    }
  }
  String original = p.join(path, settings.downloadFilename);
  original = original.replaceAll('%title%', sanitize(track.title ?? ''));
  original = original.replaceAll('%album%', sanitize(track.album?.title ?? ''));
  original =
      original.replaceAll('%artist%', sanitize(track.artists?[0].name ?? ''));
  // Album might not be available
  try {
    original = original.replaceAll(
        '%albumArtist%',
        sanitize(
            track.album?.artists?[0].name ?? track.artists?[0].name ?? ''));
  } catch (e) {
    original = original.replaceAll(
        '%albumArtist%', sanitize(track.artists?[0].name ?? ''));
  }

  //Artists
  String artists = '';
  String feats = '';
  for (int i = 0; i < (track.artists?.length ?? 0); i++) {
    String artist = track.artists?[i].name ?? '';
    if (!artists.contains(artist)) artists += ', ' + artist;
    if (i > 0 && !artists.contains(artist) && !feats.contains(artist)) {
      feats += ', ' + artist;
    }
  }
  original = original.replaceAll('%artists%', sanitize(artists).substring(2));
  if (feats.length >= 2) {
    original = original.replaceAll('%feats%', sanitize(feats).substring(2));
  }
  //Track number
  int trackNumber = track.trackNumber ?? 0;
  original = original.replaceAll('%trackNumber%', trackNumber.toString());

  //Remove leading dots
  original = original.replaceAll('/\\.+', '/');

  String header = File(original).openRead(0, 4).toString();

  if (header == 'fLaC') return original + '.flac';
  return original + '.mp3';
}

class _SettingsScreenState extends State<SettingsScreen> {
  ColorSwatch<dynamic> _swatch(int c) => ColorSwatch(c, {500: Color(c)});
  double _downloadThreads = settings.downloadThreads.toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar('Settings'.i18n),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'General'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
              title: Text(
                'Offline mode'.i18n,
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                'Will be overwritten on start.'.i18n,
                style: TextStyle(fontSize: 12),
              ),
              trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Switch(
                      value: settings.offlineMode,
                      onChanged: (bool v) {
                        if (v) {
                          setState(() => settings.offlineMode = true);
                          return;
                        }
                        showDialog(
                            context: context,
                            builder: (context) {
                              deezerAPI.authorize().then((v) async {
                                if (v) {
                                  setState(() => settings.offlineMode = false);
                                } else {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Error logging in, check your internet connections.'
                                              .i18n,
                                      gravity: ToastGravity.BOTTOM,
                                      toastLength: Toast.LENGTH_SHORT);
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                              return AlertDialog(
                                  title: Text('Logging in...'.i18n),
                                  content: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      CircularProgressIndicator()
                                    ],
                                  ));
                            });
                      },
                    ),
                  ]),
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.cloud_off_outlined),
                  ])),
          ListTile(
              title: Text(
                'Log out'.i18n,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.exit_to_app),
                  ]),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Log out'.i18n),
                        content: Text('Are you sure you want to log out?'.i18n),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'.i18n),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Continue'.i18n),
                            onPressed: () async {
                              await logOut();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      );
                    });
              }),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Appearance'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text(
              'Theme'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Currently'.i18n +
                  ': ${settings.theme.toString().split('.').last}',
              style: TextStyle(fontSize: 12),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.color_lens),
                ]),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  double screenWidth = MediaQuery.of(context).size.width;
                  double dialogWidth = screenWidth * 0.8;
                  double tileWidth = screenWidth * 0.2;

                  return AlertDialog(
                    // Use AlertDialog for more width control
                    contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 12),
                    content: SizedBox(
                      width: dialogWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize
                            .min, // Make column shrink to fit content
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(
                                20.0), // Add padding to title
                            child: Text('Select theme'.i18n,
                                style: TextStyle(fontSize: 20)),
                          ),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            childAspectRatio:
                                tileWidth / tileWidth, // Make tiles square
                            mainAxisSpacing:
                                10, // Adjust vertical spacing between rows
                            crossAxisSpacing:
                                10, // Adjust horizontal spacing between tiles
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 10.0), // Padding around the grid
                            children: Themes.values.map((theme) {
                              return ThemeTile(
                                theme: theme,
                                isSelected: settings.theme == theme,
                                onTap: () {
                                  setState(() => settings.theme = theme);
                                  settings.save();
                                  updateTheme();
                                },
                                tileSize:
                                    tileWidth, // Pass tileWidth to ThemeTile
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text(
              'Primary color'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.format_paint),
                ]),
            subtitle: Text(
              'Selected color'.i18n,
              style: TextStyle(color: settings.primaryColor, fontSize: 12),
            ),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Primary colors'.i18n),
                      content: SizedBox(
                        height: 240,
                        child: MaterialColorPicker(
                          colors: [
                            ...Colors.primaries,
                            //Logo colors
                            _swatch(0xFFFF3386),
                            _swatch(0xff4b2e7e),
                            _swatch(0xff384697),
                            _swatch(0xff0880b5),
                            _swatch(0xff00ff7f),
                            _swatch(0xFFA238FF),
                          ],
                          allowShades: false,
                          selectedColor: settings.primaryColor,
                          onMainColorChange: (ColorSwatch? color) {
                            setState(() {
                              settings.primaryColor = color!;
                            });
                            settings.save();
                            updateTheme();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  });
            },
          ),
          ListTile(
            title: Text(
              'Player gradient background'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.colorize),
                ]),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: settings.colorGradientBackground,
                    onChanged: (bool v) async {
                      setState(() => settings.colorGradientBackground = v);
                      await settings.save();
                    },
                  ),
                ]),
          ),
          ListTile(
            title: Text(
              'Blur player background'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Might have impact on performance'.i18n,
              style: TextStyle(fontSize: 12),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.blur_on),
                ]),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: settings.blurPlayerBackground,
                    onChanged: (bool v) async {
                      setState(() => settings.blurPlayerBackground = v);
                      await settings.save();
                    },
                  ),
                ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Deezer'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text('Quality'.i18n),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.high_quality),
                ]),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QualitySettings())),
          ),
          ListTile(
            title: Text('Content language'.i18n),
            subtitle: Text('Not app language, used in headers. Now'.i18n +
                ': ${settings.deezerLanguage}'),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.language),
                ]),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                        title: Text('Select language'.i18n),
                        children: List.generate(
                            ContentLanguage.all.length,
                            (i) => ListTile(
                                  title: Text(ContentLanguage.all[i].name),
                                  subtitle: Text(ContentLanguage.all[i].code),
                                  onTap: () async {
                                    setState(() => settings.deezerLanguage =
                                        ContentLanguage.all[i].code);
                                    await settings.save();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                )),
                      ));
            },
          ),
          ListTile(
            title: Text('Content country'.i18n),
            subtitle: Text('Country used in headers. Now'.i18n +
                ': ${settings.deezerCountry}'),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.vpn_lock),
                ]),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => CountryPickerDialog(
                        title: Text('Select country'.i18n),
                        titlePadding: const EdgeInsets.all(8.0),
                        isSearchable: true,
                        itemBuilder: (country) => Row(
                          children: <Widget>[
                            CountryPickerUtils.getDefaultFlagImage(country),
                            const SizedBox(
                              width: 8.0,
                            ),
                            Expanded(
                                child: Text(
                              '${country.name} (${country.isoCode})',
                            ))
                          ],
                        ),
                        onValuePicked: (Country country) {
                          setState(() =>
                              settings.deezerCountry = country.isoCode ?? 'us');
                          settings.save();
                        },
                      ));
            },
          ),
          ListTile(
            title: Text('Blind tests'.i18n),
            subtitle: Text(
                "Switch from Deezer official blind tests to Alchemy's.".i18n),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(AlchemyIcons.question),
                ]),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    BlindTestType blindTestType = settings.blindTestType;
                    return StatefulBuilder(builder: (context, setState) {
                      return AlertDialog(
                        title: Text('Choose blind test type'.i18n),
                        content: SizedBox(
                            // Wrap ListView with SizedBox to control its size
                            width: double
                                .maxFinite, // Set width to maximum to allow list to expand
                            child: ListView(
                              shrinkWrap:
                                  true, //  Important: set shrinkWrap to true for ListView in Dialog
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: blindTestType ==
                                              BlindTestType.DEEZER
                                          ? Theme.of(context)
                                                      .scaffoldBackgroundColor ==
                                                  Colors.white
                                              ? Colors.black.withAlpha(70)
                                              : Colors.white.withAlpha(70)
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: blindTestType ==
                                                  BlindTestType.DEEZER
                                              ? Theme.of(context)
                                                          .scaffoldBackgroundColor ==
                                                      Colors.white
                                                  ? Colors.black.withAlpha(150)
                                                  : Colors.white.withAlpha(150)
                                              : Colors.transparent,
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(15)),
                                  clipBehavior: Clip.hardEdge,
                                  child: ListTile(
                                    leading: Image.asset(
                                      'assets/deezer.png',
                                      width: 30,
                                      height: 30,
                                    ),
                                    title: Text(
                                      'Deezer'.i18n,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Official deezer blindtest (premium)',
                                      style: TextStyle(
                                        color: Settings.secondaryText,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          settings.blindTestType =
                                              BlindTestType.DEEZER;
                                          settings.save();
                                          blindTestType = BlindTestType.DEEZER;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      color: blindTestType ==
                                              BlindTestType.ALCHEMY
                                          ? Theme.of(context)
                                                      .scaffoldBackgroundColor ==
                                                  Colors.white
                                              ? Colors.black.withAlpha(70)
                                              : Colors.white.withAlpha(70)
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: blindTestType ==
                                                  BlindTestType.ALCHEMY
                                              ? Theme.of(context)
                                                          .scaffoldBackgroundColor ==
                                                      Colors.white
                                                  ? Colors.black.withAlpha(150)
                                                  : Colors.white.withAlpha(150)
                                              : Colors.transparent,
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(15)),
                                  clipBehavior: Clip.hardEdge,
                                  child: ListTile(
                                    leading: Image.asset(
                                      'assets/icon.png',
                                      width: 30,
                                      height: 30,
                                    ),
                                    title: Text(
                                      'Alchemy'.i18n,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Local blind test with extended features',
                                      style: TextStyle(
                                        color: Settings.secondaryText,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          settings.blindTestType =
                                              BlindTestType.ALCHEMY;
                                          settings.save();
                                          blindTestType = BlindTestType.ALCHEMY;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )),
                      );
                    });
                  });
            },
          ),
          ListTile(
            title: Text('Lyrics'.i18n),
            subtitle: Text('Choose your lyrics provider.'.i18n),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(AlchemyIcons.microphone_show),
                ]),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return AlertDialog(
                        title: Text('Choose providers prefered order :'.i18n),
                        content: SizedBox(
                            // Wrap ListView with SizedBox to control its size
                            width: double
                                .maxFinite, // Set width to maximum to allow list to expand
                            child: ReorderableListView(
                              shrinkWrap: true,
                              onReorder: (int oldIndex, int newIndex) async {
                                if (oldIndex == newIndex) return;
                                String provider =
                                    settings.lyricsProviders.removeAt(oldIndex);
                                if (newIndex > oldIndex) newIndex -= 1;
                                settings.lyricsProviders
                                    .insert(newIndex, provider);
                                setState(() {
                                  settings.lyricsProviders;
                                  settings.save();
                                });
                              },
                              children: List.generate(
                                  settings.lyricsProviders.length, (int i) {
                                String provider = settings.lyricsProviders[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(
                                      cornerRadius: 10,
                                      cornerSmoothing: 0.4,
                                    ),
                                  ),
                                  key: Key(provider),
                                  leading: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Image.asset(provider == 'DEEZER'
                                        ? 'assets/deezer.png'
                                        : provider == 'LRCLIB'
                                            ? 'assets/lrclib.png'
                                            : provider == 'LYRICFIND'
                                                ? 'assets/lyricfind.png'
                                                : ''),
                                  ),
                                  title: provider == 'DEEZER'
                                      ? Text('Deezer official API')
                                      : provider == 'LRCLIB'
                                          ? Text('LRCLIB, an OpenSource API')
                                          : provider == 'LYRICFIND'
                                              ? Text('The LyricFind API')
                                              : Text(''),
                                  subtitle: provider == 'DEEZER'
                                      ? Text('Works for premium users only.')
                                      : provider == 'LRCLIB'
                                          ? Text(
                                              'Mostly accurate results with synced and plain lyrics.')
                                          : provider == 'LYRICFIND'
                                              ? Text(
                                                  'Mother of all lyrics API. Requires a private key.')
                                              : Text(''),
                                  trailing: provider == 'DEEZER'
                                      ? Text('')
                                      : provider == 'LRCLIB'
                                          ? IconButton(
                                              onPressed: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                          builder: (context,
                                                              setState) {
                                                        return AlertDialog(
                                                          title: Text(
                                                              'Advanced LRCLib search'
                                                                  .i18n),
                                                          content: ListTile(
                                                            title: Text(
                                                                'Toggle advanced search'),
                                                            subtitle: Text(
                                                                'This will perform multiple api queries to try to get more accurate results.'),
                                                            trailing: Switch(
                                                              value: settings
                                                                  .advancedLRCLib,
                                                              onChanged: (bool
                                                                  v) async {
                                                                setState(() =>
                                                                    settings.advancedLRCLib =
                                                                        v);
                                                                await settings
                                                                    .save();
                                                                return;
                                                              },
                                                            ),
                                                          ),
                                                        );
                                                      });
                                                    });
                                              },
                                              icon: Icon(AlchemyIcons.settings))
                                          : provider == 'LYRICFIND'
                                              ? IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                      AlchemyIcons.settings))
                                              : Text(''),
                                  enabled: provider != 'LYRICFIND',
                                  onTap: () {
                                    setState(() {
                                      settings.lyricsProviders = [
                                        'DEEZER',
                                        'LRCLIB',
                                        'LYRICFIND'
                                      ];
                                    });
                                  },
                                );
                              }),
                            )),
                      );
                    });
                  });
            },
          ),
          ListTile(
            title: Text('Import'.i18n),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    AlchemyIcons.arrows_start_end,
                  ),
                ]),
            subtitle: Text('Import playlists & favorites'.i18n),
            onTap: () {
              //Show progress
              if (importer.done || importer.busy) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ImporterStatusScreen()));
                return;
              }

              //Pick importer dialog
              showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                        title: Text('Importer'.i18n),
                        children: [
                          ListTile(
                            leading: const Icon(FontAwesome5.spotify),
                            title: Text('Spotify v1'.i18n),
                            subtitle: Text(
                                'Import Spotify playlists up to 100 tracks without any login.'
                                    .i18n),
                            enabled:
                                false, // Spotify reworked embedded playlist. Source format is changed and data no longer contains ISRC.
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      const SpotifyImporterV1()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(FontAwesome5.spotify),
                            title: Text('Spotify v2'.i18n),
                            subtitle: Text(
                                'Import any Spotify playlist, import from own Spotify library. Requires free account.'
                                    .i18n),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      const SpotifyImporterV2()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(AlchemyIcons.link),
                            title: Text('Tunemymusic.com'.i18n),
                            subtitle: Text(
                                'Import playlists from another music service. (Spotify, Apple, Youtube and many more.)'
                                    .i18n),
                            onTap: () {
                              launchUrlString(
                                  'https://tunemymusic.com/transfer');
                            },
                          )
                        ],
                      ));
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Downloads'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text(
              'Concurent downloads'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.add_task),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayColor: settings.primaryColor.withAlpha(30),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: Slider(
                  min: 1,
                  max: 16,
                  divisions: 15,
                  value: _downloadThreads,
                  activeColor: settings.primaryColor,
                  secondaryActiveColor: settings.primaryColor.withAlpha(100),
                  label: _downloadThreads.round().toString(),
                  onChanged: (double v) => setState(() => _downloadThreads = v),
                  onChangeEnd: (double val) async {
                    _downloadThreads = val;
                    setState(() {
                      settings.downloadThreads = _downloadThreads.round();
                      _downloadThreads = settings.downloadThreads.toDouble();
                    });
                    await settings.save();

                    //Prevent null
                    if (val > 8 &&
                        cache.threadsWarning != true &&
                        context.mounted) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Warning'.i18n),
                              content: Text(
                                  'Using too many concurrent downloads on older/weaker devices might cause crashes!'
                                      .i18n),
                              actions: [
                                TextButton(
                                  child: Text('Dismiss'.i18n),
                                  onPressed: () => Navigator.of(context).pop(),
                                )
                              ],
                            );
                          });

                      cache.threadsWarning = true;
                      await cache.save();
                    }
                  }),
            ),
          ),
          ListTile(
            title: Text(
              'Export downloads'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Export downloads to local storage.'.i18n,
              style: TextStyle(fontSize: 12),
            ),
            leading: Transform.rotate(
                angle: -pi / 2,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(AlchemyIcons.import),
                    ])),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ExportsSettings())),
          ),
          ListTile(
            title: Text('Overwrite already downloaded files'.i18n),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: settings.overwriteDownload,
                    onChanged: (v) {
                      setState(() => settings.overwriteDownload = v);
                      settings.save();
                    },
                  ),
                ]),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.delete),
                ]),
          ),
          ListTile(
              title: Text('Save lyrics'.i18n),
              trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Switch(
                      value: settings.downloadLyrics,
                      onChanged: (v) {
                        setState(() => settings.downloadLyrics = v);
                        settings.save();
                      },
                    ),
                  ]),
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.subtitles),
                  ])),
          ListTile(
            title: Text('Save cover file for every track'.i18n),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: settings.trackCover,
                    onChanged: (v) {
                      setState(() => settings.trackCover = v);
                      settings.save();
                    },
                  ),
                ]),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[const Icon(Icons.image)]),
          ),
          ListTile(
            title: Text("Save artist's picture file for every track".i18n),
            subtitle: Text(
                'This is not recommended as it consumes significant bandwidth and disk space, and can be unreliable.'),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Switch(
                    value: settings.downloadArtistImages,
                    onChanged: (v) {
                      setState(() => settings.downloadArtistImages = v);
                      settings.save();
                    },
                  ),
                ]),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[const Icon(Icons.image)]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Miscellaneous'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text(
              'Advanced settings'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(AlchemyIcons.embed),
                ]),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdvancedSettings())),
          ),
          ListTile(
            title: Text('Updates'.i18n),
            leading: const Icon(AlchemyIcons.rocket),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const UpdaterScreen())),
          ),
          ListTile(
            title: Text(
              'About Alchemy'.i18n,
              style: TextStyle(fontSize: 16),
            ),
            leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(AlchemyIcons.alchemy),
                ]),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const CreditsScreen())),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 12, 0, 12),
                child: Text(
                  'App by @DjDoubleD, mod by @PetitPrince',
                  style: TextStyle(color: Settings.secondaryText),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          ListenableBuilder(
              listenable: playerBarState,
              builder: (BuildContext context, Widget? child) {
                return AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
                );
              }),
        ],
      ),
    );
  }
}

class AdvancedSettings extends StatefulWidget {
  const AdvancedSettings({super.key});

  @override
  _AdvancedSettingsState createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<AdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar('Advanced'.i18n),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Appearance'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
              title: Text('Use system theme'.i18n),
              trailing: Switch(
                value: settings.useSystemTheme,
                onChanged: (bool v) async {
                  setState(() {
                    settings.useSystemTheme = v;
                  });
                  updateTheme();
                  await settings.save();
                },
              ),
              leading: const Icon(Icons.android)),
          ListTile(
            title: Text('Font'.i18n),
            leading: const Icon(Icons.font_download),
            subtitle: Text(settings.font),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) =>
                      FontSelector(() => Navigator.of(context).pop()));
            },
          ),
          ListTile(
            title: Text('Visualizer'.i18n),
            subtitle: Text(
                'Show visualizers on lyrics page. WARNING: Requires microphone permission!'
                    .i18n),
            leading: const Icon(Icons.equalizer),
            trailing: Switch(
              value: settings.lyricsVisualizer,
              onChanged: (bool v) async {
                if (await Permission.microphone.request().isGranted) {
                  setState(() => settings.lyricsVisualizer = v);
                  await settings.save();
                  return;
                }
              },
            ),
            enabled: false,
          ),
          //Display mode
          ListTile(
            leading: const Icon(Icons.screen_lock_portrait),
            title: Text('Change display mode'.i18n),
            subtitle: Text('Enable high refresh rates'.i18n),
            onTap: () async {
              List modes = await FlutterDisplayMode.supported;
              if (!context.mounted) return;
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                        title: Text('Display mode'.i18n),
                        children: List.generate(
                            modes.length,
                            (i) => SimpleDialogOption(
                                  child: Text(modes[i].toString()),
                                  onPressed: () async {
                                    settings.displayMode = i;
                                    await settings.save();
                                    await FlutterDisplayMode.setPreferredMode(
                                        modes[i]);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                )));
                  });
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Deezer'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text('Log tracks'.i18n),
            subtitle: Text(
                'Send track listen logs to Deezer, enable it for features like Flow to work properly'
                    .i18n),
            trailing: Switch(
              value: settings.logListen,
              onChanged: (bool v) {
                setState(() => settings.logListen = v);
                settings.save();
              },
            ),
            leading: const Icon(Icons.history_toggle_off),
          ),
          ListTile(
            title: Text('Copy ARL'.i18n),
            subtitle:
                Text('Copy userToken/ARL Cookie for use in other apps.'.i18n),
            leading: const Icon(Icons.lock),
            onTap: () async {
              await FlutterClipboard.copy(settings.arl ?? '');
              await Fluttertoast.showToast(
                msg: 'Copied'.i18n,
              );
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Downloads'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text('Tags'.i18n),
            leading: const Icon(Icons.label),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const TagSelectionScreen())),
          ),
          ListTile(
              title: Text('Track cover resolution'.i18n),
              subtitle: Text(
                  "WARNING: Resolutions above 1200 aren't officially supported"
                      .i18n),
              leading: const Icon(Icons.image),
              trailing: SizedBox(
                  width: 75.0,
                  child: DropdownButton<int>(
                    value: settings.albumArtResolution,
                    items: [400, 800, 1000, 1200, 1400, 1600, 1800]
                        .map<DropdownMenuItem<int>>(
                            (int i) => DropdownMenuItem<int>(
                                  value: i,
                                  child: Text(i.toString()),
                                ))
                        .toList(),
                    onChanged: (int? n) async {
                      setState(() {
                        settings.albumArtResolution = n ?? 400;
                      });
                      await settings.save();
                    },
                  ))),

          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              12,
            ),
            child: Text(
              'Alchemy'.i18n,
              style: TextStyle(
                  color: settings.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          ListTile(
            title: Text('LastFM'.i18n),
            subtitle: Text((settings.lastFMUsername != null)
                ? 'Log out'.i18n
                : 'Login to enable scrobbling.'.i18n),
            leading: const Icon(FontAwesome5.lastfm),
            onTap: () async {
              if (settings.lastFMUsername != null) {
                //Log out
                settings.lastFMUsername = null;
                settings.lastFMPassword = null;
                await settings.save();
                await GetIt.I<AudioPlayerHandler>().disableLastFM();
                //await GetIt.I<AudioPlayerHandler>().customAction('disableLastFM', Map<String, dynamic>());
                setState(() {});
                Fluttertoast.showToast(msg: 'Logged out!'.i18n);
                return;
              } else {
                showDialog(
                  context: context,
                  builder: (context) => const LastFMLogin(),
                ).then((_) {
                  setState(() {});
                });
              }
            },
            //enabled: false,
          ),
          ListTile(
            title: Text('Ignore interruptions'.i18n),
            subtitle: Text('Requires app restart to apply!'.i18n),
            leading: const Icon(Icons.not_interested),
            trailing: Switch(
              value: settings.ignoreInterruptions,
              onChanged: (bool v) async {
                setState(() => settings.ignoreInterruptions = v);
                await settings.save();
              },
            ),
          ),
          ListTile(
            title: Text('Application Log'.i18n),
            leading: const Icon(Icons.sticky_note_2),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ApplicationLogViewer())),
          ),
          ListTile(
            title: Text('Download Log'.i18n),
            leading: const Icon(Icons.sticky_note_2),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const DownloadLogViewer())),
          ),
          ListenableBuilder(
              listenable: playerBarState,
              builder: (BuildContext context, Widget? child) {
                return AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
                );
              }),
        ],
      ),
    );
  }
}

class FontSelector extends StatefulWidget {
  final Function callback;

  const FontSelector(this.callback, {super.key});

  @override
  _FontSelectorState createState() => _FontSelectorState();
}

class _FontSelectorState extends State<FontSelector> {
  String query = '';
  List<String> get fonts {
    return settings.fonts
        .where((f) => f.toLowerCase().contains(query))
        .toList();
  }

  //Font selected
  void onTap(String font) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Warning'.i18n),
              content: Text(
                  "This app isn't made for supporting many fonts, it can break layouts and overflow. Use at your own risk!"
                      .i18n),
              actions: [
                TextButton(
                  onPressed: () async {
                    setState(() => settings.font = font);
                    await settings.save();
                    if (context.mounted) Navigator.of(context).pop();
                    widget.callback();
                    //Global setState
                    updateTheme();
                  },
                  child: Text('Apply'.i18n),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.callback();
                  },
                  child: const Text('Cancel'),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Select font'.i18n),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(hintText: 'Search'.i18n),
            onChanged: (q) => setState(() => query = q),
          ),
        ),
        ...List.generate(
            fonts.length,
            (i) => SimpleDialogOption(
                  child: Text(fonts[i]),
                  onPressed: () => onTap(fonts[i]),
                ))
      ],
    );
  }
}

class QualitySettings extends StatefulWidget {
  const QualitySettings({super.key});

  @override
  _QualitySettingsState createState() => _QualitySettingsState();
}

class _QualitySettingsState extends State<QualitySettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar('Quality'.i18n),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Mobile streaming'.i18n),
            leading: const Icon(Icons.network_cell),
          ),
          const QualityPicker('mobile'),
          const FreezerDivider(),
          ListTile(
            title: Text('Wifi streaming'.i18n),
            leading: const Icon(Icons.network_wifi),
          ),
          const QualityPicker('wifi'),
          const FreezerDivider(),
          ListTile(
            title: Text('Offline'.i18n),
            leading: const Icon(Icons.offline_pin),
          ),
          const QualityPicker('offline'),
          const FreezerDivider(),
          ListTile(
            title: Text('External downloads'.i18n),
            leading: const Icon(Icons.file_download),
          ),
          const QualityPicker('download'),
          ListenableBuilder(
              listenable: playerBarState,
              builder: (BuildContext context, Widget? child) {
                return AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
                );
              }),
        ],
      ),
    );
  }
}

class QualityPicker extends StatefulWidget {
  final String field;
  const QualityPicker(this.field, {super.key});

  @override
  _QualityPickerState createState() => _QualityPickerState();
}

class _QualityPickerState extends State<QualityPicker> {
  late AudioQuality _quality;

  @override
  void initState() {
    _getQuality();
    super.initState();
  }

  //Get current quality
  void _getQuality() {
    switch (widget.field) {
      case 'mobile':
        _quality = settings.mobileQuality;
        break;
      case 'wifi':
        _quality = settings.wifiQuality;
        break;
      case 'download':
        _quality = settings.downloadQuality;
        break;
      case 'offline':
        _quality = settings.offlineQuality;
        break;
    }
  }

  //Update quality in settings
  void _updateQuality(AudioQuality q) async {
    setState(() {
      _quality = q;
    });
    switch (widget.field) {
      case 'mobile':
        settings.mobileQuality = _quality;
        settings.updateAudioServiceQuality();
        break;
      case 'wifi':
        settings.wifiQuality = _quality;
        settings.updateAudioServiceQuality();
        break;
      case 'download':
        settings.downloadQuality = _quality;
        break;
      case 'offline':
        settings.offlineQuality = _quality;
        break;
    }
    await settings.save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text('MP3 128kbps'),
          leading: Radio(
            groupValue: _quality,
            value: AudioQuality.MP3_128,
            onChanged: (q) => _updateQuality(q!),
          ),
        ),
        ListTile(
          title: const Text('MP3 320kbps'),
          leading: Radio(
            groupValue: _quality,
            value: AudioQuality.MP3_320,
            onChanged: (q) => _updateQuality(q!),
          ),
        ),
        ListTile(
          title: const Text('FLAC'),
          leading: Radio(
            groupValue: _quality,
            value: AudioQuality.FLAC,
            onChanged: (q) => _updateQuality(q!),
          ),
        ),
        if (widget.field == 'download')
          ListTile(
              title: Text('Ask before downloading'.i18n),
              leading: Radio(
                groupValue: _quality,
                value: AudioQuality.ASK,
                onChanged: (q) => _updateQuality(q!),
              ))
      ],
    );
  }
}

class ContentLanguage {
  String code;
  String name;
  ContentLanguage(this.code, this.name);

  static List<ContentLanguage> get all => [
        ContentLanguage('cs', 'Čeština'),
        ContentLanguage('da', 'Dansk'),
        ContentLanguage('de', 'Deutsch'),
        ContentLanguage('en', 'English'),
        ContentLanguage('us', 'English (us)'),
        ContentLanguage('es', 'Español'),
        ContentLanguage('mx', 'Español (latam)'),
        ContentLanguage('fr', 'Français'),
        ContentLanguage('hr', 'Hrvatski'),
        ContentLanguage('id', 'Indonesia'),
        ContentLanguage('it', 'Italiano'),
        ContentLanguage('hu', 'Magyar'),
        ContentLanguage('ms', 'Melayu'),
        ContentLanguage('nl', 'Nederlands'),
        ContentLanguage('no', 'Norsk'),
        ContentLanguage('pl', 'Polski'),
        ContentLanguage('br', 'Português (br)'),
        ContentLanguage('pt', 'Português (pt)'),
        ContentLanguage('ro', 'Română'),
        ContentLanguage('sk', 'Slovenčina'),
        ContentLanguage('sl', 'Slovenščina'),
        ContentLanguage('sq', 'Shqip'),
        ContentLanguage('sr', 'Srpski'),
        ContentLanguage('fi', 'Suomi'),
        ContentLanguage('sv', 'Svenska'),
        ContentLanguage('tr', 'Türkçe'),
        ContentLanguage('bg', 'Български'),
        ContentLanguage('ru', 'Pусский'),
        ContentLanguage('uk', 'Українська'),
        ContentLanguage('he', 'עִברִית'),
        ContentLanguage('ar', 'العربیة'),
        ContentLanguage('cn', '中文'),
        ContentLanguage('ja', '日本語'),
        ContentLanguage('ko', '한국어'),
        ContentLanguage('th', 'ภาษาไทย'),
      ];
}

//Reimplement proxy
//          ListTile(
//            title: Text('Proxy'.i18n),
//            leading: Icon(Icons.vpn_key),
//            subtitle: Text(settings.proxyAddress??'Not set'.i18n),
//            onTap: () {
//              String _new;
//              showDialog(
//                context: context,
//                builder: (BuildContext context) {
//                  return AlertDialog(
//                    title: Text('Proxy'.i18n),
//                    content: TextField(
//                      onChanged: (String v) => _new = v,
//                      decoration: InputDecoration(
//                        hintText: 'IP:PORT'
//                      ),
//                    ),
//                    actions: [
//                      TextButton(
//                        child: Text('Cancel'.i18n),
//                        onPressed: () => Navigator.of(context).pop(),
//                      ),
//                      TextButton(
//                        child: Text('Reset'.i18n),
//                        onPressed: () async {
//                          setState(() {
//                            settings.proxyAddress = null;
//                          });
//                          await settings.save();
//                          Navigator.of(context).pop();
//                        },
//                      ),
//                      TextButton(
//                        child: Text('Save'.i18n),
//                        onPressed: () async {
//                          setState(() {
//                            settings.proxyAddress = _new;
//                          });
//                          await settings.save();
//                          Navigator.of(context).pop();
//                        },
//                      )
//                    ],
//                  );
//                }
//              );
//            },
//          )

class FilenameTemplateDialog extends StatefulWidget {
  final String initial;
  final Function onSave;
  const FilenameTemplateDialog(this.initial, this.onSave, {super.key});

  @override
  _FilenameTemplateDialogState createState() => _FilenameTemplateDialogState();
}

class _FilenameTemplateDialogState extends State<FilenameTemplateDialog> {
  late TextEditingController _controller;
  late String _new;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initial);
    _new = _controller.value.text;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Dialog with filename format
    return AlertDialog(
      title: Text('Downloaded tracks filename'.i18n),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            onChanged: (String s) => _new = s,
          ),
          Container(height: 8.0),
          Text(
            'Valid variables are'.i18n +
                ': %artists%, %artist%, %title%, %album%, %trackNumber%, %0trackNumber%, %feats%, %playlistTrackNumber%, %0playlistTrackNumber%, %year%, %date%\n\n' +
                "If you want to use custom directory naming - use '/' as directory separator."
                    .i18n,
            style: const TextStyle(
              fontSize: 12.0,
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'.i18n),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Reset'.i18n),
          onPressed: () {
            _controller.value =
                _controller.value.copyWith(text: '%artist% - %title%');
            _new = '%artist% - %title%';
          },
        ),
        TextButton(
          child: Text('Clear'.i18n),
          onPressed: () => _controller.clear(),
        ),
        TextButton(
          child: Text('Save'.i18n),
          onPressed: () async {
            widget.onSave(_new);
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}

class ExportsSettings extends StatefulWidget {
  const ExportsSettings({super.key});

  @override
  _ExportsSettingsState createState() => _ExportsSettingsState();
}

class _ExportsSettingsState extends State<ExportsSettings> {
  final TextEditingController _artistSeparatorController =
      TextEditingController(text: settings.artistSeparator);
  double? _trackProgress;
  double? _showProgress;
  bool _trackErrors = false;
  bool _showErrors = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FreezerAppBar('Export Settings'.i18n),
        body: ListView(children: [
          ListTile(
              title: Text('Exports tracks'.i18n),
              subtitle: Text('Export all tracks to internal storage.'.i18n),
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      AlchemyIcons.double_note,
                    ),
                  ]),
              onTap: () async {
                List<Track> allTracks =
                    await downloadManager.allOfflineTracks();
                String dirPath = p.join(
                    (await getExternalStorageDirectory())?.path ?? '',
                    'offline/');
                for (Track track in allTracks) {
                  try {
                    String destinationPath = generateFilename(track);
                    if (!(await Directory(p.dirname(destinationPath))
                        .exists())) {
                      await Directory(p.dirname(destinationPath))
                          .create(recursive: true);
                    }
                    if (await File(p.join(dirPath, track.id)).exists()) {
                      await File(p.join(dirPath, track.id))
                          .copy(destinationPath);
                    }
                  } catch (e) {
                    setState(() {
                      _trackErrors = true;
                    });
                  }
                  setState(() {
                    _trackProgress =
                        (allTracks.indexOf(track) + 1) / allTracks.length;
                  });
                }
                Fluttertoast.showToast(
                    msg:
                        _trackErrors ? 'Done. Some errors occured.' : 'Done !');
              }),
          if (_trackProgress != null)
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  color: _trackErrors
                      ? Colors.red.shade600
                      : Colors.greenAccent.shade400,
                  value: _trackProgress,
                )),
          ListTile(
              title: Text('Exports podcasts'.i18n),
              subtitle: Text('Export all podcasts to internal storage.'.i18n),
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      AlchemyIcons.podcast,
                    ),
                  ]),
              onTap: () async {
                List<ShowEpisode> allEpisodes =
                    await downloadManager.getAllOfflineEpisodes();
                String dirPath = p.join(
                    (await getExternalStorageDirectory())?.path ?? '',
                    'offline/');
                for (ShowEpisode episode in allEpisodes) {
                  try {
                    String fileName = (episode.title ?? '') + '.mp3';
                    String destinationPath =
                        p.join(settings.downloadPath ?? '', fileName);
                    if (!(await Directory(p.dirname(destinationPath))
                        .exists())) {
                      await Directory(p.dirname(destinationPath))
                          .create(recursive: true);
                    }
                    if (await File(p.join(dirPath, episode.id)).exists()) {
                      await File(p.join(dirPath, episode.id))
                          .copy(destinationPath);
                    }
                  } catch (e) {
                    setState(() {
                      _showErrors = true;
                    });
                  }
                  setState(() {
                    _showProgress =
                        (allEpisodes.indexOf(episode) + 1) / allEpisodes.length;
                  });
                }
                Fluttertoast.showToast(
                    msg: _showErrors ? 'Done. Some errors occured.' : 'Done !');
              }),
          if (_showProgress != null)
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  color: _showErrors
                      ? Colors.red.shade600
                      : Colors.greenAccent.shade400,
                  value: _showProgress,
                )),
          const FreezerDivider(),
          ListTile(
            title: Text('Download path'.i18n),
            leading: const Icon(Icons.folder),
            subtitle: Text(settings.downloadPath ?? 'Not set'.i18n),
            onTap: () async {
              //Check permissions
              //if (!(await Permission.storage.request().isGranted)) return;
              if (await FileUtils.checkStoragePermission()) {
                //Navigate
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DirectoryPicker(
                            settings.downloadPath ?? '',
                            onSelect: (String p) async {
                              setState(() => settings.downloadPath = p);
                              await settings.save();
                            },
                          )));
                }
              } else {
                Fluttertoast.showToast(
                    msg: 'Storage permission denied!'.i18n,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM);
                return;
              }
            },
          ),
          ListTile(
            title: Text('Exports naming'.i18n),
            subtitle: Text('Currently'.i18n + ': ${settings.downloadFilename}'),
            leading: const Icon(Icons.text_format),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return FilenameTemplateDialog(settings.downloadFilename,
                        (f) async {
                      setState(() => settings.downloadFilename = f);
                      await settings.save();
                    });
                  });
            },
          ),
          ListTile(
            title: Text('Create folders for artist'.i18n),
            trailing: Switch(
              value: settings.artistFolder,
              onChanged: (v) {
                setState(() => settings.artistFolder = v);
                settings.save();
              },
            ),
            leading: const Icon(Icons.folder),
          ),
          ListTile(
              title: Text('Create folders for albums'.i18n),
              trailing: Switch(
                value: settings.albumFolder,
                onChanged: (v) {
                  setState(() => settings.albumFolder = v);
                  settings.save();
                },
              ),
              leading: const Icon(Icons.folder)),
          ListTile(
            title: Text('Artist separator'.i18n),
            leading: const Icon(WebSymbols.tag),
            trailing: SizedBox(
              width: 75.0,
              child: TextField(
                controller: _artistSeparatorController,
                onChanged: (s) async {
                  settings.artistSeparator = s;
                  await settings.save();
                },
              ),
            ),
          ),
          ListenableBuilder(
              listenable: playerBarState,
              builder: (BuildContext context, Widget? child) {
                return AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
                );
              }),
        ]));
  }
}

class TagOption {
  String title;
  String value;
  TagOption(this.title, this.value);
}

class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({super.key});

  @override
  _TagSelectionScreenState createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  List<TagOption> tags = [
    TagOption('Title'.i18n, 'title'),
    TagOption('Album'.i18n, 'album'),
    TagOption('Artist'.i18n, 'artist'),
    TagOption('Track number'.i18n, 'track'),
    TagOption('Disc number'.i18n, 'disc'),
    TagOption('Album artist'.i18n, 'albumArtist'),
    TagOption('Date/Year'.i18n, 'date'),
    TagOption('Label'.i18n, 'label'),
    TagOption('ISRC'.i18n, 'isrc'),
    TagOption('UPC'.i18n, 'upc'),
    TagOption('Track total'.i18n, 'trackTotal'),
    TagOption('BPM'.i18n, 'bpm'),
    TagOption('Unsynchronized lyrics'.i18n, 'lyrics'),
    TagOption('Genre'.i18n, 'genre'),
    TagOption('Contributors'.i18n, 'contributors'),
    TagOption('Album art'.i18n, 'art')
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar('Tags'.i18n),
      body: ListenableBuilder(
          listenable: playerBarState,
          builder: (BuildContext context, Widget? child) {
            return AnimatedPadding(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
              child: ListView(
                children: List.generate(
                    tags.length,
                    (i) => ListTile(
                          title: Text(tags[i].title),
                          leading: Switch(
                            value: settings.tags.contains(tags[i].value),
                            onChanged: (v) async {
                              //Update
                              if (v) {
                                settings.tags.add(tags[i].value);
                              } else {
                                settings.tags.remove(tags[i].value);
                              }
                              setState(() {});
                              await settings.save();
                            },
                          ),
                        )),
              ),
            );
          }),
    );
  }
}

class LastFMLogin extends StatefulWidget {
  const LastFMLogin({super.key});

  @override
  _LastFMLoginState createState() => _LastFMLoginState();
}

class _LastFMLoginState extends State<LastFMLogin> {
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Login to LastFM'.i18n),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(hintText: 'Username'.i18n),
            onChanged: (v) => _username = v,
          ),
          Container(height: 8.0),
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: 'Password'.i18n),
            onChanged: (v) => _password = v,
          )
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'.i18n),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Login'.i18n),
          onPressed: () async {
            LastFM last;
            try {
              last = await LastFM.authenticate(
                  apiKey: Env.lastFmApiKey,
                  apiSecret: Env.lastFmApiSecret,
                  username: _username,
                  password: _password);
            } catch (e) {
              Logger.root.severe('Error authorizing LastFM: $e');
              Fluttertoast.showToast(msg: 'Authorization error!'.i18n);
              return;
            }
            //Save
            settings.lastFMUsername = last.username;
            settings.lastFMPassword = last.passwordHash;
            await settings.save();
            await GetIt.I<AudioPlayerHandler>().authorizeLastFM();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class StorageInfo {
  final String rootDir;
  final String appFilesDir;

  StorageInfo({
    required this.rootDir,
    required this.appFilesDir,
  });
}

Future<List<StorageInfo>> getStorageInfo() async {
  final externalDirectories =
      await ExternalPath.getExternalStorageDirectories();

  List<StorageInfo> storageInfoList = [];

  if (externalDirectories.isNotEmpty) {
    for (var dir in externalDirectories) {
      storageInfoList.add(
        StorageInfo(
          rootDir: dir,
          appFilesDir: dir,
        ),
      );
    }
  }

  return storageInfoList;
}

class DirectoryPicker extends StatefulWidget {
  final String initialPath;
  final Function onSelect;
  const DirectoryPicker(this.initialPath, {required this.onSelect, super.key});

  @override
  _DirectoryPickerState createState() => _DirectoryPickerState();
}

class _DirectoryPickerState extends State<DirectoryPicker> {
  late String _path;
  String? _previous;
  String? _root;

  // Alternative Native file picker, not skinned
  // DirectoryLocation? _pickedDirectory;
  // Future<bool> _isPickDirectorySupported = FlutterFileDialog.isPickDirectorySupported();

  @override
  void initState() {
    _path = widget.initialPath;
    super.initState();
  }

  Future _resetPath() async {
    final appFilesDir = await getApplicationDocumentsDirectory();
    setState(() => _path = appFilesDir.path);
  }

  /*Future<void> _pickDirectory() async {
    _pickedDirectory = (await FlutterFileDialog.pickDirectory());
    setState(() {});
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar(
        'Pick-a-Path'.i18n,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.sd_card,
                semanticLabel: 'Select storage'.i18n,
              ),
              onPressed: () {
                //_pickDirectory();
                //Chose storage
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Select storage'.i18n),
                        content: FutureBuilder(
                          //future: PathProviderEx.getStorageInfo(),
                          future: getStorageInfo(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) return const ErrorScreen();
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircularProgressIndicator()
                                  ],
                                ),
                              );
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ...List.generate(snapshot.data?.length ?? 0,
                                    (i) {
                                  StorageInfo si = snapshot.data![i];
                                  return ListTile(
                                    title: Text(si.rootDir),
                                    leading: const Icon(Icons.sd_card),
                                    onTap: () {
                                      setState(() {
                                        _path = si.appFilesDir;
                                        _root = si.rootDir;
                                        if (i != 0) _root = si.appFilesDir;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                })
                              ],
                            );
                          },
                        ),
                      );
                    });
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done),
        onPressed: () {
          //When folder confirmed
          widget.onSelect(_path);
          Navigator.of(context).pop();
        },
      ),
      body: FutureBuilder(
        future: Directory(_path).list().toList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          //On error go to last good path
          if (snapshot.hasError) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (_previous == null) {
                _resetPath();
                return;
              }
              setState(() => _path = _previous!);
            });
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          List<FileSystemEntity> data = snapshot.data;
          return ListView(
            children: <Widget>[
              ListTile(
                title: Text(_path),
              ),
              ListTile(
                title: Text('Go up'.i18n),
                leading: const Icon(Icons.arrow_upward),
                onTap: () {
                  setState(() {
                    if (_root == _path) {
                      Fluttertoast.showToast(
                          msg: 'Permission denied'.i18n,
                          gravity: ToastGravity.BOTTOM);
                      return;
                    }
                    _previous = _path;
                    _path = Directory(_path).parent.path;
                  });
                },
              ),
              ...List.generate(data.length, (i) {
                FileSystemEntity f = data[i];
                if (f is Directory) {
                  return ListTile(
                    title: Text(f.path.split('/').last),
                    leading: const Icon(Icons.folder),
                    onTap: () {
                      setState(() {
                        _previous = _path;
                        _path = f.path;
                      });
                    },
                  );
                }
                return const SizedBox(
                  height: 0,
                  width: 0,
                );
              })
            ],
          );
        },
      ),
    );
  }
}

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  _CreditsScreenState createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  String _version = '';

  static final List<List<String>> translators = [
    ['Andrea', 'Resident Polyglot, Italian and just about everything else <3'],
    ['ovosimpatico', 'Portuguese & Spanish'],
    ['PanChi', 'German'],
  ];

  static final List<List<String>> freezerTranslators = [
    ['Xandar Null', 'Arabic'],
    ['Markus', 'German'],
    ['Andrea', 'Italian'],
    ['Diego Hiro', 'Portuguese'],
    ['Orfej', 'Russian'],
    ['Chino Pacia', 'Filipino'],
    ['ArcherDelta & PetFix', 'Spanish'],
    ['Shazzaam', 'Croatian'],
    ['VIRGIN_KLM', 'Greek'],
    ['koreezzz', 'Korean'],
    ['Fwwwwwwwwwweze', 'French'],
    ['kobyrevah', 'Hebrew'],
    ['HoScHaKaL', 'Turkish'],
    ['MicroMihai', 'Romanian'],
    ['LenteraMalam', 'Indonesian'],
    ['RTWO2', 'Persian']
  ];

  @override
  void initState() {
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _version = 'v${info.version}';
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar('About'.i18n),
      body: ListView(
        children: [
          const FreezerTitle(),
          Text(
            _version,
            textAlign: TextAlign.center,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const FreezerDivider(),
          ListTile(
            title: Text('PetitPrince'.i18n),
            subtitle: Text('Alchemy developer, tester, maintainer, ...'.i18n),
            leading:
                Image.asset('assets/PetitPrince.png', width: 36, height: 36),
            onTap: () {
              launchUrlString('https://github.com/PetitPrinc3');
            },
          ),
          const FreezerDivider(),
          ListTile(
            title: Text('DJDoubleD'.i18n),
            subtitle: Text(
                'Original ReFreezer developer, tester and maintainer, ...'
                    .i18n),
            leading: Image.asset('assets/DJDoubleD.jpg', width: 36, height: 36),
            onTap: () {
              launchUrlString('https://github.com/DJDoubleD');
            },
          ),
          const FreezerDivider(),
          /*ListTile(
            title: Text('Telegram Channel'.i18n),
            subtitle: Text('To get latest releases'.i18n),
            leading: const Icon(FontAwesome5.telegram, color: Color(0xFF27A2DF), size: 36.0),
            onTap: () {
              launchUrlString('https://t.me/joinchat/Se4zLEBvjS1NCiY9');
            },
          ),
          ListTile(
            title: Text('Telegram Group'.i18n),
            subtitle: Text('Official chat'.i18n),
            leading: const Icon(FontAwesome5.telegram, color: Colors.cyan, size: 36.0),
            onTap: () {
              launchUrlString('https://t.me/freezerandroid');
            },
          ),
          ListTile(
            title: Text('Discord'.i18n),
            subtitle: Text('Official Discord server'.i18n),
            leading: const Icon(FontAwesome5.discord, color: Color(0xff7289da), size: 36.0),
            onTap: () {
              launchUrlString('https://discord.gg/qwJpa3r4dQ');
            },
          ),*/
          ListTile(
            title: Text('Repository'.i18n),
            subtitle: Text('Source code, report issues there.'.i18n),
            leading:
                const Icon(AlchemyIcons.embed, color: Colors.green, size: 36.0),
            onTap: () {
              launchUrlString(
                  'https://github.com/PetitPrinc3/DefinitelyNotDeezer');
            },
          ),
          ListTile(
            title: Text('Crowdin'.i18n),
            subtitle: Text('Help translating this app on Crowdin!'.i18n),
            leading: const Icon(AlchemyIcons.arrow_diagonal,
                color: Color(0xffbdc1c6), size: 36.0),
            onTap: () {
              launchUrlString('https://crowdin.com/project/refreezer');
            },
          ),
          ListTile(
            isThreeLine: true,
            title: Text('Donate'.i18n),
            subtitle: Text(
                'You should rather support your favorite artists, instead of this app!'
                    .i18n),
            leading:
                const Icon(FontAwesome5.paypal, color: Colors.blue, size: 36.0),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Donate'.i18n),
                      content: Text(
                          'No really, go support your favorite artists instead ;)'
                              .i18n),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });
              // launchUrlString('https://paypal.me/exttex');
            },
          ),
          const FreezerDivider(),
          ...List.generate(
              translators.length,
              (i) => ListTile(
                    title: Text(translators[i][0]),
                    subtitle: Text(translators[i][1]),
                  )),
          const Padding(padding: EdgeInsets.all(8.0)),
          const FreezerDivider(),
          ExpansionTile(
            title: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset('assets/icon_legacy.png',
                            width: 24, height: 24),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'The original freezer development team'.i18n,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        Image.asset('assets/icon_legacy.png',
                            width: 24, height: 24),
                      ],
                    ),
                  ],
                );
              },
            ),
            textColor: Theme.of(context).primaryColor,
            iconColor: Theme.of(context).primaryColor,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: const Border(),
            children: [
              const FreezerDivider(),
              const ListTile(
                title: Text('exttex'),
                subtitle: Text('Developer'),
              ),
              const ListTile(
                title: Text('Bas Curtiz'),
                subtitle:
                    Text('Icon, logo, banner, design suggestions, tester'),
              ),
              const ListTile(
                title: Text('Tobs'),
                subtitle: Text('Alpha testers'),
              ),
              const ListTile(
                title: Text('Deemix'),
                subtitle: Text('Better app <3'),
              ),
              const ListTile(
                title: Text('Xandar Null'),
                subtitle: Text('Tester, translations help'),
              ),
              ListTile(
                title: const Text('Francesco'),
                subtitle: const Text('Tester'),
                onTap: () {
                  setState(() {
                    settings.primaryColor = const Color(0xff333333);
                  });
                  updateTheme();
                  settings.save();
                },
              ),
              const ListTile(
                title: Text('Annexhack'),
                subtitle: Text('Android Auto help'),
              ),
              const FreezerDivider(),
              ...List.generate(
                  freezerTranslators.length,
                  (i) => ListTile(
                        title: Text(freezerTranslators[i][0]),
                        subtitle: Text(freezerTranslators[i][1]),
                      )),
            ],
          ),
          const FreezerDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: Text(
              'Huge thanks to all the contributors! <3'.i18n,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          ListenableBuilder(
              listenable: playerBarState,
              builder: (BuildContext context, Widget? child) {
                return AnimatedPadding(
                  duration: Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.only(bottom: playerBarState.state ? 80 : 0),
                );
              })
        ],
      ),
    );
  }
}

class ThemeTile extends StatelessWidget {
  final Themes theme;
  final bool isSelected;
  final VoidCallback onTap;
  final double tileSize; // Add tileSize parameter

  const ThemeTile({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
    required this.tileSize, // Receive tileSize
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = settings.themeDataFor(theme);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).scaffoldBackgroundColor == Colors.white
                ? Colors.black.withAlpha(70)
                : Colors.white.withAlpha(70)
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).scaffoldBackgroundColor == Colors.white
                  ? Colors.black.withAlpha(150)
                  : Colors.white.withAlpha(150)
              : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: tileSize * 0.35, // Circle radius relative to tile size
              child: Container(
                //clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: themeData.primaryColor,
                          width: 3.0,
                        )
                      : null,
                ),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: LiquidLinearProgressIndicator(
                    value: 0.2, // You can adjust this value or make it dynamic
                    backgroundColor: themeData.scaffoldBackgroundColor,
                    valueColor: AlwaysStoppedAnimation(
                        themeData.highlightColor.toARGB32().toRadixString(16) !=
                                '0'
                            ? themeData.highlightColor
                            : settings.primaryColor),
                    waveLength: 0.4,
                    direction: Axis.vertical,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getThemeName(theme).i18n,
              style: TextStyle(fontSize: 14),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(Themes theme) {
    switch (theme) {
      case Themes.Light:
        return 'Light';
      case Themes.Alchemy:
        return 'Alchemy';
      case Themes.Deezer:
        return 'Deezer';
      case Themes.Black:
        return 'Black (AMOLED)';
      case Themes.Spotify:
        return 'Spotify';
    }
  }
}
