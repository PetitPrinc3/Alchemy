import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:alchemy/fonts/alchemy_icons.dart';
import 'package:alchemy/main.dart';
import 'package:alchemy/utils/connectivity.dart';

import '../api/cache.dart';
import '../api/deezer.dart';
import '../api/definitions.dart';
import '../api/download.dart';
import '../service/audio_service.dart';
import '../settings.dart';
import '../translations.i18n.dart';
import '../ui/details_screens.dart';
import '../ui/elements.dart';
import '../ui/error.dart';
import '../ui/tiles.dart';
import 'menu.dart';

class LibraryTracks extends StatefulWidget {
  const LibraryTracks({super.key});

  @override
  _LibraryTracksState createState() => _LibraryTracksState();
}

class _LibraryTracksState extends State<LibraryTracks> {
  bool _isLoading = false;
  bool _isLoadingTracks = false;
  final ScrollController _scrollController = ScrollController();
  List<Track> tracks = [];
  List<Track> allTracks = [];
  int? trackCount;
  Sorting _sort = Sorting(sourceType: SortSourceTypes.TRACKS);

  List<Track> get _sorted {
    List<Track> tcopy = List.from(tracks);
    tcopy.sort((a, b) => a.addedDate!.compareTo(b.addedDate!));
    switch (_sort.type) {
      case SortType.ALPHABETIC:
        tcopy.sort((a, b) => a.title!.compareTo(b.title!));
        break;
      case SortType.ARTIST:
        tcopy.sort((a, b) => a.artists![0].name!
            .toLowerCase()
            .compareTo(b.artists![0].name!.toLowerCase()));
        break;
      case SortType.DEFAULT:
      default:
        break;
    }
    //Reverse
    if (_sort.reverse) return tcopy.reversed.toList();
    return tcopy;
  }

  Future _reverse() async {
    if (mounted) setState(() => _sort.reverse = !_sort.reverse);
    //Save sorting in cache
    int? index = Sorting.index(SortSourceTypes.TRACKS);
    if (index != null) {
      cache.sorts[index] = _sort;
    } else {
      cache.sorts.add(_sort);
    }
    await cache.save();

    //Preload for sorting
    if (tracks.length < (trackCount ?? 0)) _loadFull();
  }

  Future _load() async {
    //Already loaded
    if (trackCount != null && (tracks.length >= (trackCount ?? 0))) {
      //Update favorite tracks cache when fully loaded
      if (cache.libraryTracks?.length != trackCount) {
        if (mounted) {
          setState(() {
            cache.libraryTracks = tracks.map((t) => t.id!).toList();
          });
          await cache.save();
        }
      }
      return;
    }

    if (await isConnected()) {
      int pos = tracks.length;

      if (tracks.isEmpty) {
        //Load tracks as a playlist
        Playlist? favPlaylist;
        try {
          favPlaylist = await deezerAPI.playlist(cache.favoritesPlaylistId);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
        //Error loading
        if (favPlaylist == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        //Update
        if (mounted) {
          setState(() {
            trackCount = favPlaylist!.trackCount;
            if (tracks.isEmpty) tracks = favPlaylist.tracks!;
            _makeFavorite();
            _isLoading = false;
          });
        }
        return;
      }

      //Load another page of tracks from deezer
      if (_isLoadingTracks) return;
      _isLoadingTracks = true;

      List<Track>? t;
      try {
        t = await deezerAPI.playlistTracksPage(cache.favoritesPlaylistId, pos);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
      //On error load offline
      if (t == null) {
        t = await downloadManager.allOfflineTracks();
        if (mounted) {
          setState(() {
            tracks = t ?? [];
            _isLoading = false;
            _isLoadingTracks = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          tracks.addAll(t!);
          _makeFavorite();
          _isLoading = false;
          _isLoadingTracks = false;
        });
      }
    } else {
      List<Track> t = await downloadManager.allOfflineTracks();
      if (mounted) {
        setState(() {
          tracks = t;
          _isLoading = false;
          _isLoadingTracks = false;
        });
      }
    }
  }

  //Load all tracks
  Future _loadFull() async {
    if (tracks.isEmpty || tracks.length < (trackCount ?? 0)) {
      late Playlist p;
      try {
        p = await deezerAPI.fullPlaylist(cache.favoritesPlaylistId);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
      if (mounted) {
        setState(() {
          tracks = p.tracks!;
          trackCount = p.trackCount;
          _sort = _sort;
        });
      }
    }
  }

  //Update tracks with favorite true
  void _makeFavorite() {
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].favorite = true;
    }
  }

  @override
  void initState() {
    if (mounted) setState(() => _isLoading = true);

    _scrollController.addListener(() {
      //Load more tracks on scroll
      double off = _scrollController.position.maxScrollExtent * 0.90;
      if (_scrollController.position.pixels > off) _load();
    });

    _load();

    //Load sorting
    int? index = Sorting.index(SortSourceTypes.TRACKS);
    if (index != null) {
      if (mounted) setState(() => _sort = cache.sorts[index]);
    }

    if (_sort.type != SortType.DEFAULT || _sort.reverse) _loadFull();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        /*floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: ListenableBuilder(
            listenable: playerBarState,
            builder: (BuildContext context, Widget? child) {
              return AnimatedPadding(
                duration: Duration(milliseconds: 200),
                padding:
                    EdgeInsets.only(bottom: playerBarState.state ? 80 : 20),
                child: FloatingActionButton(
                    backgroundColor: Theme.of(context).primaryColor,
                    onPressed: () async {
                      //Add to offline
                      if (_playlist.user?.id != deezerAPI.userId) {
                        await deezerAPI.addPlaylist(_playlist.id!);
                      }
                      downloadManager.addOfflinePlaylist(_playlist,
                          private: true);
                      MenuSheet().showDownloadStartedToast();
                    },
                    child: Icon(
                      AlchemyIcons.download,
                      size: 25,
                    )),
              );
            }),*/
        appBar: FreezerAppBar(
          'Tracks'.i18n,
          actions: [
            IconButton(
                icon: Icon(
                  _sort.reverse
                      ? FontAwesome5.sort_alpha_up
                      : FontAwesome5.sort_alpha_down,
                  semanticLabel: _sort.reverse
                      ? 'Sort descending'.i18n
                      : 'Sort ascending'.i18n,
                ),
                onPressed: () async {
                  await _reverse();
                }),
            PopupMenuButton(
              color: Theme.of(context).scaffoldBackgroundColor,
              onSelected: (SortType s) async {
                //Preload for sorting
                if (tracks.length < (trackCount ?? 0)) await _loadFull();

                setState(() => _sort.type = s);
                //Save sorting in cache
                int? index = Sorting.index(SortSourceTypes.TRACKS);
                if (index != null) {
                  cache.sorts[index] = _sort;
                } else {
                  cache.sorts.add(_sort);
                }
                await cache.save();
              },
              itemBuilder: (context) => <PopupMenuEntry<SortType>>[
                PopupMenuItem(
                  value: SortType.DEFAULT,
                  child: Text('Default'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ALPHABETIC,
                  child: Text('Alphabetic'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ARTIST,
                  child: Text('Artist'.i18n, style: popupMenuTextStyle()),
                ),
              ],
              child: Icon(
                AlchemyIcons.sort,
                size: 32.0,
                semanticLabel: 'Sort'.i18n,
              ),
            ),
            Container(width: 8.0),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor))
            : DraggableScrollbar.rrect(
                controller: _scrollController,
                backgroundColor: Theme.of(context).primaryColor,
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[
                    //Loved tracks
                    ...List.generate(tracks.length, (i) {
                      Track t = (tracks.length == (trackCount ?? 0))
                          ? _sorted[i]
                          : tracks[i];
                      return TrackTile(
                        t,
                        onTap: () {
                          GetIt.I<AudioPlayerHandler>().playFromTrackList(
                              (tracks.length == (trackCount ?? 0))
                                  ? _sorted
                                  : tracks,
                              t.id!,
                              QueueSource(
                                  id: cache.favoritesPlaylistId,
                                  text: 'Favorites'.i18n,
                                  source: 'playlist'));
                        },
                        onHold: () {
                          MenuSheet m = MenuSheet();
                          m.defaultTrackMenu(t, context: context, onRemove: () {
                            setState(() {
                              tracks.removeWhere((track) => t.id == track.id);
                            });
                          });
                        },
                      );
                    }),
                    if (_isLoadingTracks)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 2.0),
                            child: CircularProgressIndicator(),
                          )
                        ],
                      ),
                    ListenableBuilder(
                        listenable: playerBarState,
                        builder: (BuildContext context, Widget? child) {
                          return AnimatedPadding(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.only(
                                bottom: playerBarState.state ? 80 : 0),
                          );
                        }),
                  ],
                )));
  }
}

class LibraryAlbums extends StatefulWidget {
  const LibraryAlbums({super.key});

  @override
  _LibraryAlbumsState createState() => _LibraryAlbumsState();
}

class _LibraryAlbumsState extends State<LibraryAlbums> {
  Sorting _sort = Sorting(sourceType: SortSourceTypes.ALBUMS);
  final ScrollController _scrollController = ScrollController();

  Future<List<Album>> _loadAlbums() async {
    List<Album> offlineAlbums = await downloadManager.getOfflineAlbums();
    if (await isConnected()) {
      List<Album> onlineAlbums = await deezerAPI.getAlbums();
      for (int i = 0; i < onlineAlbums.length; i++) {
        if (onlineAlbums[i].isIn(offlineAlbums)) {
          onlineAlbums[i].offline = true;
        }
      }
      return onlineAlbums;
    } else {
      return offlineAlbums;
    }
  }

  Future _reverse() async {
    setState(() => _sort.reverse = !_sort.reverse);
    //Save sorting in cache
    int? index = Sorting.index(SortSourceTypes.ALBUMS);
    if (index != null) {
      cache.sorts[index] = _sort;
    } else {
      cache.sorts.add(_sort);
    }
    await cache.save();
  }

  @override
  void initState() {
    super.initState();
    //Load sorting
    int? index = Sorting.index(SortSourceTypes.ALBUMS);
    if (index != null) {
      _sort = cache.sorts[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FreezerAppBar(
          'Albums'.i18n,
          actions: [
            IconButton(
              icon: Icon(
                _sort.reverse
                    ? FontAwesome5.sort_alpha_up
                    : FontAwesome5.sort_alpha_down,
                semanticLabel: _sort.reverse
                    ? 'Sort descending'.i18n
                    : 'Sort ascending'.i18n,
              ),
              onPressed: () => _reverse(),
            ),
            PopupMenuButton(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(AlchemyIcons.sort, size: 32.0),
              onSelected: (SortType s) async {
                setState(() => _sort.type = s);
                //Save to cache
                int? index = Sorting.index(SortSourceTypes.ALBUMS);
                if (index == null) {
                  cache.sorts.add(_sort);
                } else {
                  cache.sorts[index] = _sort;
                }
                await cache.save();
              },
              itemBuilder: (context) => <PopupMenuEntry<SortType>>[
                PopupMenuItem(
                  value: SortType.DEFAULT,
                  child: Text('Default'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ALPHABETIC,
                  child: Text('Alphabetic'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ARTIST,
                  child: Text('Artist'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.RELEASE_DATE,
                  child: Text('Release date'.i18n, style: popupMenuTextStyle()),
                ),
              ],
            ),
            Container(width: 8.0),
          ],
        ),
        body: DraggableScrollbar.rrect(
          controller: _scrollController,
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              Container(height: 8.0),
              AlbumList(
                loadAlbums: _loadAlbums,
                sort: _sort,
              ),
              ListenableBuilder(
                  listenable: playerBarState,
                  builder: (BuildContext context, Widget? child) {
                    return AnimatedPadding(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                          bottom: playerBarState.state ? 80 : 0),
                    );
                  }),
            ],
          ),
        ));
  }
}

class AlbumList extends StatefulWidget {
  final Future<List<Album>> Function() loadAlbums;
  final Sorting sort;
  final bool offline;
  const AlbumList({
    super.key,
    required this.loadAlbums,
    required this.sort,
    this.offline = false,
  });
  @override
  _AlbumListState createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  List<Album> _albums = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    try {
      _albums = await widget.loadAlbums();
    } catch (e) {
      Logger.root.severe('Error loading albums: $e', StackTrace.current);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Album> get _sortedAlbums => _sortAlbums(_albums);
  List<Album> _sortAlbums(List<Album> albums) {
    List<Album> sortedAlbums = List.from(albums);
    if (sortedAlbums.isNotEmpty) {
      sortedAlbums
          .sort((a, b) => _compareDates(a.favoriteDate, b.favoriteDate));
      switch (widget.sort.type) {
        case SortType.DEFAULT:
          break;
        case SortType.ALPHABETIC:
          sortedAlbums.sort((a, b) => (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase()));
          break;
        case SortType.ARTIST:
          sortedAlbums.sort((a, b) => (a.artists?.firstOrNull?.name ?? '')
              .toLowerCase()
              .compareTo((b.artists?.firstOrNull?.name ?? '').toLowerCase()));
          break;
        case SortType.RELEASE_DATE:
          sortedAlbums
              .sort((a, b) => _compareDates(a.releaseDate, b.releaseDate));
          break;
        default:
          break;
      }
    }
    return widget.sort.reverse ? sortedAlbums.reversed.toList() : sortedAlbums;
  }

  int _compareDates(String? dateA, String? dateB) {
    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return DateTime.parse(dateA).compareTo(DateTime.parse(dateB));
  }

  @override
  void didUpdateWidget(covariant AlbumList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      );
    }
    return Column(
      children: [
        if (widget.offline && _albums.isNotEmpty) ...[
          const FreezerDivider(),
          Text(
            'Offline albums'.i18n,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
          ),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sortedAlbums.length,
          itemBuilder: (context, index) {
            Album album = _sortedAlbums[index];
            return AlbumTile(
              album,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AlbumDetails(album)));
              },
              onHold: () {
                MenuSheet m = MenuSheet();
                m.defaultAlbumMenu(album, context: context, onRemove: () {
                  setState(() {
                    _albums.remove(album);
                  });
                });
              },
              trailing: (album.offline ?? false)
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        Octicons.primitive_dot,
                        color: Colors.green,
                        size: 12.0,
                      ),
                    )
                  : SizedBox(),
            );
          },
        ),
      ],
    );
  }
}

class LibraryShows extends StatefulWidget {
  const LibraryShows({super.key});

  @override
  _LibraryShowsState createState() => _LibraryShowsState();
}

class _LibraryShowsState extends State<LibraryShows> {
  final ScrollController _scrollController = ScrollController();
  List<Show> libraryShows = [];

  void _loadShows() async {
    //List<Show> offlineShows = await downloadManager.getOfflineShows();
    if (await isConnected()) {
      List<Show> onlineShows = await deezerAPI.getUserShows();
      if (mounted) {
        setState(() {
          libraryShows.addAll(onlineShows);
        });
      }
    } else {
      List<Show> offlineShows = await downloadManager.getOfflineShows();
      if (mounted) {
        setState(() {
          libraryShows.addAll(offlineShows);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadShows();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FreezerAppBar(
          'Podcasts'.i18n,
        ),
        body: DraggableScrollbar.rrect(
          controller: _scrollController,
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              Container(height: 8.0),
              ...List.generate(
                  libraryShows.length,
                  (int i) => ShowTile(
                        libraryShows[i],
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  ShowScreen(libraryShows[i])));
                        },
                      )),
              ListenableBuilder(
                  listenable: playerBarState,
                  builder: (BuildContext context, Widget? child) {
                    return AnimatedPadding(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                          bottom: playerBarState.state ? 80 : 0),
                    );
                  }),
            ],
          ),
        ));
  }
}

class LibraryArtists extends StatefulWidget {
  const LibraryArtists({super.key});

  @override
  _LibraryArtistsState createState() => _LibraryArtistsState();
}

class _LibraryArtistsState extends State<LibraryArtists> {
  List<Artist> _artists = [];
  Sorting _sort = Sorting(sourceType: SortSourceTypes.ARTISTS);
  bool _loading = true;
  bool _error = false;
  final ScrollController _scrollController = ScrollController();

  //Load data
  Future _load() async {
    if (mounted) setState(() => _loading = true);
    //Fetch
    List<Artist>? data;
    try {
      data = await deezerAPI.getArtists();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    //Update UI
    if (mounted) {
      setState(() {
        if (data != null) {
          _artists = data;
        } else {
          _error = true;
        }
        _loading = false;
      });
    }
  }

  Future _reverse() async {
    setState(() => _sort.reverse = !_sort.reverse);
    //Save sorting in cache
    int? index = Sorting.index(SortSourceTypes.ARTISTS);
    if (index != null) {
      cache.sorts[index] = _sort;
    } else {
      cache.sorts.add(_sort);
    }
    await cache.save();
  }

  @override
  void initState() {
    //Restore sort
    int? index = Sorting.index(SortSourceTypes.ARTISTS);
    if (index != null) {
      _sort = cache.sorts[index];
    }

    _load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FreezerAppBar(
          'Artists'.i18n,
          actions: [
            IconButton(
              icon: Icon(
                _sort.reverse
                    ? FontAwesome5.sort_alpha_up
                    : FontAwesome5.sort_alpha_down,
                semanticLabel: _sort.reverse
                    ? 'Sort descending'.i18n
                    : 'Sort ascending'.i18n,
              ),
              onPressed: () => _reverse(),
            ),
            PopupMenuButton(
              color: Theme.of(context).scaffoldBackgroundColor,
              onSelected: (SortType s) async {
                setState(() => _sort.type = s);
                //Save
                int? index = Sorting.index(SortSourceTypes.ARTISTS);
                if (index == null) {
                  cache.sorts.add(_sort);
                } else {
                  cache.sorts[index] = _sort;
                }
                await cache.save();
              },
              itemBuilder: (context) => <PopupMenuEntry<SortType>>[
                PopupMenuItem(
                  value: SortType.DEFAULT,
                  child: Text('Default'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ALPHABETIC,
                  child: Text('Alphabetic'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.POPULARITY,
                  child: Text('Popularity'.i18n, style: popupMenuTextStyle()),
                ),
              ],
              child: const Icon(AlchemyIcons.sort, size: 32.0),
            ),
            Container(width: 8.0),
          ],
        ),
        body: DraggableScrollbar.rrect(
          controller: _scrollController,
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()],
                  ),
                ),
              if (_error) const Center(child: ErrorScreen()),
              if (!_loading && !_error)
                ...List.generate(_artists.length, (i) {
                  Artist a = _artists[i];
                  return ArtistHorizontalTile(
                    a,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ArtistDetails(a)));
                    },
                    onHold: () {
                      MenuSheet m = MenuSheet();
                      m.defaultArtistMenu(a, context: context, onRemove: () {
                        setState(() {
                          _artists.remove(a);
                        });
                      });
                    },
                  );
                }),
              ListenableBuilder(
                  listenable: playerBarState,
                  builder: (BuildContext context, Widget? child) {
                    return AnimatedPadding(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                          bottom: playerBarState.state ? 80 : 0),
                    );
                  }),
            ],
          ),
        ));
  }
}

class LibraryPlaylists extends StatefulWidget {
  const LibraryPlaylists({super.key});

  @override
  _LibraryPlaylistsState createState() => _LibraryPlaylistsState();
}

class _LibraryPlaylistsState extends State<LibraryPlaylists> {
  List<Playlist>? _playlists;
  Sorting _sort = Sorting(sourceType: SortSourceTypes.PLAYLISTS);
  final ScrollController _scrollController = ScrollController();
  String _filter = '';

  List<Playlist> get _sorted {
    List<Playlist> playlists = List.from(_playlists!
        .where((p) => p.title!.toLowerCase().contains(_filter.toLowerCase())));
    switch (_sort.type) {
      case SortType.DEFAULT:
        break;
      case SortType.USER:
        playlists.sort((a, b) => (a.user?.id ?? deezerAPI.userId!)
            .toLowerCase()
            .compareTo((b.user?.id ?? deezerAPI.userId!).toLowerCase()));
        break;
      case SortType.TRACK_COUNT:
        playlists.sort((a, b) => b.trackCount! - a.trackCount!);
        break;
      case SortType.ALPHABETIC:
        playlists.sort(
            (a, b) => a.title!.toLowerCase().compareTo(b.title!.toLowerCase()));
        break;
      default:
        break;
    }
    if (_sort.reverse) return playlists.reversed.toList();
    return playlists;
  }

  Future _load() async {
    List<Playlist> offlinePlaylists =
        await downloadManager.getOfflinePlaylists();
    if (mounted) setState(() => _playlists = offlinePlaylists);

    if (await isConnected()) {
      try {
        List<Playlist> playlists = await deezerAPI.getPlaylists();
        if (mounted) setState(() => _playlists = playlists);
      } catch (e) {
        Logger.root.severe('Error loading playlists: $e');
      }
    }
  }

  Future _reverse() async {
    setState(() => _sort.reverse = !_sort.reverse);
    //Save sorting in cache
    int? index = Sorting.index(SortSourceTypes.PLAYLISTS);
    if (index != null) {
      cache.sorts[index] = _sort;
    } else {
      cache.sorts.add(_sort);
    }
    await cache.save();
  }

  @override
  void initState() {
    //Restore sort
    int? index = Sorting.index(SortSourceTypes.PLAYLISTS);
    if (index != null) {
      _sort = cache.sorts[index];
    }

    _load();
    super.initState();
  }

  Playlist get favoritesPlaylist => Playlist(
      id: cache.favoritesPlaylistId,
      title: 'Favorites'.i18n,
      user: User(name: cache.userName),
      image: ImageDetails(thumbUrl: 'assets/favorites_thumb.jpg'),
      tracks: [],
      trackCount: 1,
      duration: const Duration(seconds: 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FreezerAppBar(
          'Playlists'.i18n,
          actions: [
            IconButton(
              icon: Icon(
                _sort.reverse
                    ? FontAwesome5.sort_alpha_up
                    : FontAwesome5.sort_alpha_down,
                semanticLabel: _sort.reverse
                    ? 'Sort descending'.i18n
                    : 'Sort ascending'.i18n,
              ),
              onPressed: () => _reverse(),
            ),
            PopupMenuButton(
              color: Theme.of(context).scaffoldBackgroundColor,
              onSelected: (SortType s) async {
                setState(() => _sort.type = s);
                //Save to cache
                int? index = Sorting.index(SortSourceTypes.PLAYLISTS);
                if (index == null) {
                  cache.sorts.add(_sort);
                } else {
                  cache.sorts[index] = _sort;
                }

                await cache.save();
              },
              itemBuilder: (context) => <PopupMenuEntry<SortType>>[
                PopupMenuItem(
                  value: SortType.DEFAULT,
                  child: Text('Default'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.USER,
                  child: Text('User'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.TRACK_COUNT,
                  child: Text('Track count'.i18n, style: popupMenuTextStyle()),
                ),
                PopupMenuItem(
                  value: SortType.ALPHABETIC,
                  child: Text('Alphabetic'.i18n, style: popupMenuTextStyle()),
                ),
              ],
              child: const Icon(AlchemyIcons.sort, size: 32.0),
            ),
            Container(width: 8.0),
          ],
        ),
        body: DraggableScrollbar.rrect(
          controller: _scrollController,
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              //Search
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                    onChanged: (String s) => setState(() => _filter = s),
                    decoration: InputDecoration(
                      labelText: 'Search'.i18n,
                      fillColor: Theme.of(context).bottomAppBarTheme.color,
                      filled: true,
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                    )),
              ),
              ListTile(
                title: Text('Create new playlist'.i18n),
                leading: const LeadingIcon(Icons.playlist_add,
                    color: Color(0xff009a85)),
                onTap: () async {
                  if (!(await isConnected())) {
                    Fluttertoast.showToast(
                        msg: 'Cannot create playlists in offline mode'.i18n,
                        gravity: ToastGravity.BOTTOM);
                    return;
                  }
                  MenuSheet m = MenuSheet();
                  if (mounted) {
                    await m.createPlaylist(context);
                  }
                  await _load();
                },
              ),
              const FreezerDivider(),

              if (!settings.offlineMode && _playlists == null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                  ],
                ),

              if (_playlists != null)
                ...List.generate(_sorted.length, (int i) {
                  Playlist p = (_sorted)[i];
                  return PlaylistTile(
                    p,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PlaylistDetails(p))),
                    onHold: () {
                      MenuSheet m = MenuSheet();
                      m.defaultPlaylistMenu(p, context: context, onRemove: () {
                        setState(() => _playlists!.remove(p));
                      }, onUpdate: () {
                        _load();
                      });
                    },
                  );
                }),
              ListenableBuilder(
                  listenable: playerBarState,
                  builder: (BuildContext context, Widget? child) {
                    return AnimatedPadding(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                          bottom: playerBarState.state ? 80 : 0),
                    );
                  }),
            ],
          ),
        ));
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreezerAppBar(
        'History'.i18n,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep,
              semanticLabel: 'Clear all'.i18n,
            ),
            onPressed: () {
              setState(() => cache.history = []);
              cache.save();
            },
          )
        ],
      ),
      body: DraggableScrollbar.rrect(
          controller: _scrollController,
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: (cache.history).length,
            itemBuilder: (BuildContext context, int i) {
              Track t = cache.history[cache.history.length - i - 1];
              return TrackTile(
                t,
                onTap: () {
                  GetIt.I<AudioPlayerHandler>().playFromTrackList(
                      cache.history.reversed.toList(),
                      t.id!,
                      QueueSource(
                          id: null, text: 'History'.i18n, source: 'history'));
                },
                onHold: () {
                  MenuSheet m = MenuSheet();
                  m.defaultTrackMenu(t, context: context);
                },
              );
            },
          )),
    );
  }
}
