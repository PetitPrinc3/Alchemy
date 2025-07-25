// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cache _$CacheFromJson(Map<String, dynamic> json) =>
    Cache(
        libraryTracks: (json['libraryTracks'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      )
      ..favoritesPlaylistId = json['favoritesPlaylistId'] as String? ?? ''
      ..topTracks =
          (json['topTracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..favoritePlaylists =
          (json['favoritePlaylists'] as List<dynamic>?)
              ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..favortirePlaylist = json['favortirePlaylist'] == null
          ? null
          : Playlist.fromJson(json['favortirePlaylist'] as Map<String, dynamic>)
      ..userName = json['userName'] as String? ?? ''
      ..userEmail = json['userEmail'] as String? ?? ''
      ..userSex = json['userSex'] as String? ?? ''
      ..userPicture = json['userPicture'] as Map<String, dynamic>? ?? {}
      ..userColor = (json['userColor'] as num?)?.toInt()
      ..recognitionHistory =
          (json['recognitionHistory'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..history =
          (json['history'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..sorts =
          (json['sorts'] as List<dynamic>?)
              ?.map((e) => Sorting.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..searchHistory = Cache._searchHistoryFromJson(
        json['searchHistory2'] as List?,
      )
      ..searchSections =
          (json['searchSections'] as List<dynamic>?)
              ?.map((e) => HomePageSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..threadsWarning = json['threadsWarning'] as bool? ?? false
      ..lastUpdateCheck = (json['lastUpdateCheck'] as num?)?.toInt() ?? 0;

Map<String, dynamic> _$CacheToJson(Cache instance) => <String, dynamic>{
  'favoritesPlaylistId': instance.favoritesPlaylistId,
  'topTracks': instance.topTracks,
  'favoritePlaylists': instance.favoritePlaylists,
  'favortirePlaylist': instance.favortirePlaylist,
  'userName': instance.userName,
  'userEmail': instance.userEmail,
  'userSex': instance.userSex,
  'userPicture': instance.userPicture,
  'userColor': instance.userColor,
  'libraryTracks': instance.libraryTracks,
  'recognitionHistory': instance.recognitionHistory,
  'history': instance.history,
  'sorts': instance.sorts,
  'searchHistory2': Cache._searchHistoryToJson(instance.searchHistory),
  'searchSections': instance.searchSections,
  'threadsWarning': instance.threadsWarning,
  'lastUpdateCheck': instance.lastUpdateCheck,
};

SearchHistoryItem _$SearchHistoryItemFromJson(Map<String, dynamic> json) =>
    SearchHistoryItem(
      json['data'],
      $enumDecode(_$SearchHistoryItemTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$SearchHistoryItemToJson(SearchHistoryItem instance) =>
    <String, dynamic>{
      'data': instance.data,
      'type': _$SearchHistoryItemTypeEnumMap[instance.type]!,
    };

const _$SearchHistoryItemTypeEnumMap = {
  SearchHistoryItemType.TRACK: 'TRACK',
  SearchHistoryItemType.ALBUM: 'ALBUM',
  SearchHistoryItemType.ARTIST: 'ARTIST',
  SearchHistoryItemType.PLAYLIST: 'PLAYLIST',
  SearchHistoryItemType.SHOW: 'SHOW',
  SearchHistoryItemType.EPISODE: 'EPISODE',
};
