// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'definitions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Track _$TrackFromJson(Map<String, dynamic> json) => Track(
  id: json['id'] as String?,
  title: json['title'] as String?,
  duration: json['duration'] == null
      ? Duration.zero
      : Duration(microseconds: (json['duration'] as num).toInt()),
  album: json['album'] == null
      ? null
      : Album.fromJson(json['album'] as Map<String, dynamic>),
  playbackDetails: json['playbackDetails'] as List<dynamic>?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  artists: (json['artists'] as List<dynamic>?)
      ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
      .toList(),
  trackNumber: (json['trackNumber'] as num?)?.toInt(),
  offline: json['offline'] as bool?,
  lyrics: json['lyrics'] == null
      ? null
      : LyricsFull.fromJson(json['lyrics'] as Map<String, dynamic>),
  favorite: json['favorite'] as bool?,
  diskNumber: (json['diskNumber'] as num?)?.toInt(),
  explicit: json['explicit'] as bool?,
  addedDate: (json['addedDate'] as num?)?.toInt(),
  fallback: json['fallback'] == null
      ? null
      : Track.fromJson(json['fallback'] as Map<String, dynamic>),
  playbackDetailsFallback: json['playbackDetailsFallback'] as List<dynamic>?,
);

Map<String, dynamic> _$TrackToJson(Track instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'album': instance.album,
  'artists': instance.artists,
  'duration': instance.duration.inMicroseconds,
  'image': instance.image,
  'trackNumber': instance.trackNumber,
  'offline': instance.offline,
  'lyrics': instance.lyrics,
  'favorite': instance.favorite,
  'diskNumber': instance.diskNumber,
  'explicit': instance.explicit,
  'addedDate': instance.addedDate,
  'fallback': instance.fallback,
  'playbackDetails': instance.playbackDetails,
  'playbackDetailsFallback': instance.playbackDetailsFallback,
};

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
  id: json['id'] as String?,
  title: json['title'] as String?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  artists: (json['artists'] as List<dynamic>?)
      ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
      .toList(),
  tracks: (json['tracks'] as List<dynamic>?)
      ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList(),
  fans: (json['fans'] as num?)?.toInt(),
  offline: json['offline'] as bool?,
  library: json['library'] as bool?,
  type: $enumDecodeNullable(_$AlbumTypeEnumMap, json['type']),
  releaseDate: json['releaseDate'] as String?,
  favoriteDate: json['favoriteDate'] as String?,
);

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artists': instance.artists,
  'tracks': instance.tracks,
  'image': instance.image,
  'fans': instance.fans,
  'offline': instance.offline,
  'library': instance.library,
  'type': _$AlbumTypeEnumMap[instance.type],
  'releaseDate': instance.releaseDate,
  'favoriteDate': instance.favoriteDate,
};

const _$AlbumTypeEnumMap = {
  AlbumType.ALBUM: 'ALBUM',
  AlbumType.SINGLE: 'SINGLE',
  AlbumType.FEATURED: 'FEATURED',
  AlbumType.EP: 'EP',
};

ArtistHighlight _$ArtistHighlightFromJson(Map<String, dynamic> json) =>
    ArtistHighlight(
      data: json['data'],
      type: $enumDecodeNullable(_$ArtistHighlightTypeEnumMap, json['type']),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$ArtistHighlightToJson(ArtistHighlight instance) =>
    <String, dynamic>{
      'data': instance.data,
      'type': _$ArtistHighlightTypeEnumMap[instance.type],
      'title': instance.title,
    };

const _$ArtistHighlightTypeEnumMap = {ArtistHighlightType.ALBUM: 'ALBUM'};

Bio _$BioFromJson(Map<String, dynamic> json) => Bio(
  summary: json['summary'] as String?,
  full: json['full'] as String?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$BioToJson(Bio instance) => <String, dynamic>{
  'summary': instance.summary,
  'full': instance.full,
  'source': instance.source,
};

Artist _$ArtistFromJson(Map<String, dynamic> json) => Artist(
  id: json['id'] as String?,
  name: json['name'] as String?,
  albums:
      (json['albums'] as List<dynamic>?)
          ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  topTracks:
      (json['topTracks'] as List<dynamic>?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  fans: (json['fans'] as num?)?.toInt(),
  offline: json['offline'] as bool?,
  library: json['library'] as bool?,
  radio: json['radio'] as bool?,
  featuredIn: (json['featuredIn'] as List<dynamic>?)
      ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
      .toList(),
  relatedArtists: (json['relatedArtists'] as List<dynamic>?)
      ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
      .toList(),
  playlists: (json['playlists'] as List<dynamic>?)
      ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
      .toList(),
  biography: json['biography'] == null
      ? null
      : Bio.fromJson(json['biography'] as Map<String, dynamic>),
  favoriteDate: json['favoriteDate'] as String?,
  hasNextPage: json['hasNextPage'] as bool?,
  highlight: json['highlight'] == null
      ? null
      : ArtistHighlight.fromJson(json['highlight'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ArtistToJson(Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'albums': instance.albums,
  'topTracks': instance.topTracks,
  'featuredIn': instance.featuredIn,
  'playlists': instance.playlists,
  'relatedArtists': instance.relatedArtists,
  'biography': instance.biography,
  'image': instance.image,
  'fans': instance.fans,
  'offline': instance.offline,
  'library': instance.library,
  'radio': instance.radio,
  'favoriteDate': instance.favoriteDate,
  'highlight': instance.highlight,
  'hasNextPage': instance.hasNextPage,
};

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
  id: json['id'] as String?,
  title: json['title'] as String?,
  tracks: (json['tracks'] as List<dynamic>?)
      ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList(),
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  trackCount: (json['trackCount'] as num?)?.toInt(),
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  fans: (json['fans'] as num?)?.toInt(),
  library: json['library'] as bool?,
  description: json['description'] as String?,
  addedDate: json['addedDate'] as String? ?? '',
);

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'tracks': instance.tracks,
  'image': instance.image,
  'duration': instance.duration?.inMicroseconds,
  'trackCount': instance.trackCount,
  'user': instance.user,
  'fans': instance.fans,
  'library': instance.library,
  'description': instance.description,
  'addedDate': instance.addedDate,
};

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String?,
  name: json['name'] as String?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'image': instance.image,
};

ImageDetails _$ImageDetailsFromJson(Map<String, dynamic> json) => ImageDetails(
  fullUrl: json['fullUrl'] as String?,
  thumbUrl: json['thumbUrl'] as String?,
  type: json['type'] as String?,
  imageHash: json['imageHash'] as String?,
);

Map<String, dynamic> _$ImageDetailsToJson(ImageDetails instance) =>
    <String, dynamic>{
      'fullUrl': instance.fullUrl,
      'thumbUrl': instance.thumbUrl,
      'type': instance.type,
      'imageHash': instance.imageHash,
    };

LogoDetails _$LogoDetailsFromJson(Map<String, dynamic> json) => LogoDetails(
  fullUrl: json['fullUrl'] as String?,
  thumbUrl: json['thumbUrl'] as String?,
  type: json['type'] as String?,
  imageHash: json['imageHash'] as String?,
);

Map<String, dynamic> _$LogoDetailsToJson(LogoDetails instance) =>
    <String, dynamic>{
      'fullUrl': instance.fullUrl,
      'thumbUrl': instance.thumbUrl,
      'type': instance.type,
      'imageHash': instance.imageHash,
    };

Lyrics _$LyricsFromJson(Map<String, dynamic> json) => Lyrics(
  id: json['id'] as String?,
  writers: json['writers'] as String?,
  syncedLyrics: (json['syncedLyrics'] as List<dynamic>?)
      ?.map((e) => SynchronizedLyric.fromJson(e as Map<String, dynamic>))
      .toList(),
  unsyncedLyrics: json['unsyncedLyrics'] as String?,
  errorMessage: json['errorMessage'] as String?,
  isExplicit: json['isExplicit'] as bool?,
  copyright: json['copyright'] as String?,
  provider: $enumDecodeNullable(_$LyricsProviderEnumMap, json['provider']),
);

Map<String, dynamic> _$LyricsToJson(Lyrics instance) => <String, dynamic>{
  'id': instance.id,
  'writers': instance.writers,
  'syncedLyrics': instance.syncedLyrics,
  'errorMessage': instance.errorMessage,
  'unsyncedLyrics': instance.unsyncedLyrics,
  'isExplicit': instance.isExplicit,
  'copyright': instance.copyright,
  'provider': _$LyricsProviderEnumMap[instance.provider],
};

const _$LyricsProviderEnumMap = {
  LyricsProvider.DEEZER: 'DEEZER',
  LyricsProvider.LRCLIB: 'LRCLIB',
  LyricsProvider.LYRICFIND: 'LYRICFIND',
};

LyricsClassic _$LyricsClassicFromJson(Map<String, dynamic> json) =>
    LyricsClassic(
        id: json['id'] as String?,
        writers: json['writers'] as String?,
        syncedLyrics: (json['syncedLyrics'] as List<dynamic>?)
            ?.map((e) => SynchronizedLyric.fromJson(e as Map<String, dynamic>))
            .toList(),
        errorMessage: json['errorMessage'] as String?,
        unsyncedLyrics: json['unsyncedLyrics'] as String?,
      )
      ..isExplicit = json['isExplicit'] as bool?
      ..copyright = json['copyright'] as String?
      ..provider = $enumDecodeNullable(
        _$LyricsProviderEnumMap,
        json['provider'],
      );

Map<String, dynamic> _$LyricsClassicToJson(LyricsClassic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'writers': instance.writers,
      'syncedLyrics': instance.syncedLyrics,
      'errorMessage': instance.errorMessage,
      'unsyncedLyrics': instance.unsyncedLyrics,
      'isExplicit': instance.isExplicit,
      'copyright': instance.copyright,
      'provider': _$LyricsProviderEnumMap[instance.provider],
    };

LyricsFull _$LyricsFullFromJson(Map<String, dynamic> json) => LyricsFull(
  id: json['id'] as String?,
  writers: json['writers'] as String?,
  syncedLyrics: (json['syncedLyrics'] as List<dynamic>?)
      ?.map((e) => SynchronizedLyric.fromJson(e as Map<String, dynamic>))
      .toList(),
  errorMessage: json['errorMessage'] as String?,
  unsyncedLyrics: json['unsyncedLyrics'] as String?,
  isExplicit: json['isExplicit'] as bool?,
  copyright: json['copyright'] as String?,
  provider: $enumDecodeNullable(_$LyricsProviderEnumMap, json['provider']),
);

Map<String, dynamic> _$LyricsFullToJson(LyricsFull instance) =>
    <String, dynamic>{
      'id': instance.id,
      'writers': instance.writers,
      'syncedLyrics': instance.syncedLyrics,
      'errorMessage': instance.errorMessage,
      'unsyncedLyrics': instance.unsyncedLyrics,
      'isExplicit': instance.isExplicit,
      'copyright': instance.copyright,
      'provider': _$LyricsProviderEnumMap[instance.provider],
    };

SynchronizedLyric _$SynchronizedLyricFromJson(Map<String, dynamic> json) =>
    SynchronizedLyric(
      offset: json['offset'] == null
          ? null
          : Duration(microseconds: (json['offset'] as num).toInt()),
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      text: json['text'] as String?,
      lrcTimestamp: json['lrcTimestamp'] as String?,
    );

Map<String, dynamic> _$SynchronizedLyricToJson(SynchronizedLyric instance) =>
    <String, dynamic>{
      'offset': instance.offset?.inMicroseconds,
      'duration': instance.duration?.inMicroseconds,
      'text': instance.text,
      'lrcTimestamp': instance.lrcTimestamp,
    };

QueueSource _$QueueSourceFromJson(Map<String, dynamic> json) => QueueSource(
  id: json['id'] as String?,
  text: json['text'] as String?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$QueueSourceToJson(QueueSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'source': instance.source,
    };

SmartTrackList _$SmartTrackListFromJson(Map<String, dynamic> json) =>
    SmartTrackList(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      trackCount: (json['trackCount'] as num?)?.toInt(),
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
      image: json['image'] == null
          ? null
          : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
      subtitle: json['subtitle'] as String?,
      flowType: json['flowType'] as String?,
    );

Map<String, dynamic> _$SmartTrackListToJson(SmartTrackList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'trackCount': instance.trackCount,
      'tracks': instance.tracks,
      'image': instance.image,
      'flowType': instance.flowType,
    };

HomePage _$HomePageFromJson(Map<String, dynamic> json) => HomePage(
  flowSection: json['flowSection'] == null
      ? null
      : HomePageSection.fromJson(json['flowSection'] as Map<String, dynamic>),
  mainSection: json['mainSection'] == null
      ? null
      : HomePageSection.fromJson(json['mainSection'] as Map<String, dynamic>),
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => HomePageSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$HomePageToJson(HomePage instance) => <String, dynamic>{
  'flowSection': instance.flowSection,
  'mainSection': instance.mainSection,
  'sections': instance.sections,
};

HomePageSection _$HomePageSectionFromJson(Map<String, dynamic> json) =>
    HomePageSection(
      layout: $enumDecodeNullable(
        _$HomePageSectionLayoutEnumMap,
        json['layout'],
      ),
      type: $enumDecodeNullable(_$HomePageSectionTypeEnumMap, json['type']),
      source: json['source'] as String?,
      items: HomePageSection._homePageItemFromJson(json['items']),
      title: json['title'] as String?,
      pagePath: json['pagePath'] as String?,
      hasMore: json['hasMore'] as bool?,
    );

Map<String, dynamic> _$HomePageSectionToJson(HomePageSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'layout': _$HomePageSectionLayoutEnumMap[instance.layout],
      'type': _$HomePageSectionTypeEnumMap[instance.type],
      'source': instance.source,
      'pagePath': instance.pagePath,
      'hasMore': instance.hasMore,
      'items': HomePageSection._homePageItemToJson(instance.items),
    };

const _$HomePageSectionLayoutEnumMap = {
  HomePageSectionLayout.ROW: 'ROW',
  HomePageSectionLayout.GRID: 'GRID',
};

const _$HomePageSectionTypeEnumMap = {
  HomePageSectionType.FLOW: 'FLOW',
  HomePageSectionType.MAIN: 'MAIN',
  HomePageSectionType.OTHER: 'OTHER',
};

DeezerChannel _$DeezerChannelFromJson(Map<String, dynamic> json) =>
    DeezerChannel(
      id: json['id'] as String?,
      title: json['title'] as String?,
      backgroundColor: DeezerChannel._colorFromJson(
        (json['backgroundColor'] as num?)?.toInt(),
      ),
      target: json['target'] as String?,
      backgroundImage: json['backgroundImage'] == null
          ? null
          : ImageDetails.fromJson(
              json['backgroundImage'] as Map<String, dynamic>,
            ),
      logo: json['logo'] as String?,
      logoImage: json['logoImage'] == null
          ? null
          : LogoDetails.fromJson(json['logoImage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeezerChannelToJson(DeezerChannel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target': instance.target,
      'title': instance.title,
      'logo': instance.logo,
      'backgroundColor': DeezerChannel._colorToJson(instance.backgroundColor),
      'backgroundImage': instance.backgroundImage,
      'logoImage': instance.logoImage,
    };

DeezerFlow _$DeezerFlowFromJson(Map<String, dynamic> json) => DeezerFlow(
  id: json['id'] as String?,
  title: json['title'] as String?,
  target: json['target'] as String?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeezerFlowToJson(DeezerFlow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target': instance.target,
      'title': instance.title,
      'image': instance.image,
    };

Sorting _$SortingFromJson(Map<String, dynamic> json) => Sorting(
  type:
      $enumDecodeNullable(_$SortTypeEnumMap, json['type']) ?? SortType.DEFAULT,
  reverse: json['reverse'] as bool? ?? false,
  id: json['id'] as String?,
  sourceType: $enumDecodeNullable(_$SortSourceTypesEnumMap, json['sourceType']),
);

Map<String, dynamic> _$SortingToJson(Sorting instance) => <String, dynamic>{
  'type': _$SortTypeEnumMap[instance.type]!,
  'reverse': instance.reverse,
  'id': instance.id,
  'sourceType': _$SortSourceTypesEnumMap[instance.sourceType],
};

const _$SortTypeEnumMap = {
  SortType.DEFAULT: 'DEFAULT',
  SortType.ALPHABETIC: 'ALPHABETIC',
  SortType.ARTIST: 'ARTIST',
  SortType.ALBUM: 'ALBUM',
  SortType.RELEASE_DATE: 'RELEASE_DATE',
  SortType.POPULARITY: 'POPULARITY',
  SortType.USER: 'USER',
  SortType.TRACK_COUNT: 'TRACK_COUNT',
  SortType.DATE_ADDED: 'DATE_ADDED',
};

const _$SortSourceTypesEnumMap = {
  SortSourceTypes.TRACKS: 'TRACKS',
  SortSourceTypes.PLAYLISTS: 'PLAYLISTS',
  SortSourceTypes.ALBUMS: 'ALBUMS',
  SortSourceTypes.ARTISTS: 'ARTISTS',
  SortSourceTypes.PLAYLIST: 'PLAYLIST',
};

Show _$ShowFromJson(Map<String, dynamic> json) => Show(
  name: json['name'] as String?,
  authors: json['authors'] as String?,
  description: json['description'] as String?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  id: json['id'] as String?,
  fans: (json['fans'] as num?)?.toInt(),
  isExplicit: json['isExplicit'] as bool?,
  isLibrary: json['isLibrary'] as bool?,
  episodes: (json['episodes'] as List<dynamic>?)
      ?.map((e) => ShowEpisode.fromJson(e as Map<String, dynamic>))
      .toList(),
)..isSubscribed = json['isSubscribed'] as bool?;

Map<String, dynamic> _$ShowToJson(Show instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'authors': instance.authors,
  'image': instance.image,
  'id': instance.id,
  'fans': instance.fans,
  'isExplicit': instance.isExplicit,
  'isLibrary': instance.isLibrary,
  'isSubscribed': instance.isSubscribed,
  'episodes': instance.episodes,
};

ShowEpisode _$ShowEpisodeFromJson(Map<String, dynamic> json) => ShowEpisode(
  id: json['id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  url: json['url'] as String?,
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  publishedDate: json['publishedDate'] as String?,
  image: json['image'] == null
      ? null
      : ImageDetails.fromJson(json['image'] as Map<String, dynamic>),
  isExplicit: json['isExplicit'] as bool?,
  show: json['show'] == null
      ? null
      : Show.fromJson(json['show'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ShowEpisodeToJson(ShowEpisode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'url': instance.url,
      'duration': instance.duration?.inMicroseconds,
      'publishedDate': instance.publishedDate,
      'image': instance.image,
      'isExplicit': instance.isExplicit,
      'show': instance.show,
    };
