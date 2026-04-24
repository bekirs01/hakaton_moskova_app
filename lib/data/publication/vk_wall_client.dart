import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// VK [wall.post] sonucu: oluşan duvar kaydı id’si.
@immutable
class VkPublishResult {
  const VkPublishResult({this.postId});

  final int? postId;
}

/// [wall.getById] ile alınan özet metrikler.
@immutable
class VkPostStats {
  const VkPostStats({
    required this.views,
    this.likes,
    this.reposts,
    this.comments,
  });

  final int views;
  final int? likes;
  final int? reposts;
  final int? comments;
}

/// VK API: grup (community) duvarına [wall.post] ile yayın.
class VkWallClient {
  VkWallClient._();
  static final instance = VkWallClient._();

  static const _v = '5.199';
  static const _getTimeout = Duration(seconds: 60);
  static const _uploadTimeout = Duration(minutes: 6);

  void _throwIfError(Map<String, dynamic> m) {
    if (!m.containsKey('error')) {
      return;
    }
    final e = m['error'];
    if (e is! Map) {
      throw StateError('VK: unknown error');
    }
    final em = (e['error_msg'] as String?)?.trim() ?? 'vk_error';
    throw StateError(em);
  }

  String _formBody(Map<String, String> p) {
    return p.entries
        .map(
          (a) =>
              '${Uri.encodeQueryComponent(a.key)}=${Uri.encodeQueryComponent(a.value)}',
        )
        .join('&');
  }

  Future<Map<String, dynamic>> _get(
    String method,
    Map<String, String> p,
  ) async {
    final q = {
      ...p,
      'access_token': AppEnv.vkApiAccessToken,
      'v': _v,
    };
    final u = Uri.https('api.vk.com', 'method/$method', q);
    final r = await http.get(u).timeout(_getTimeout);
    final m = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    _throwIfError(m);
    return m;
  }

  /// Uzun metin/photo dizesi (saveWallPhoto) için POST; `response` döner.
  Future<dynamic> _postFormResponse(String method, Map<String, String> p) async {
    final body = {
      ...p,
      'access_token': AppEnv.vkApiAccessToken,
      'v': _v,
    };
    final u = Uri.https('api.vk.com', 'method/$method');
    final r = await http
        .post(
          u,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          },
          body: _formBody(body),
        )
        .timeout(_getTimeout);
    final m = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    _throwIfError(m);
    return m['response'];
  }

  static int? _parseWallPostId(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is int) {
      return response;
    }
    if (response is num) {
      return response.toInt();
    }
    if (response is String) {
      return int.tryParse(response.trim());
    }
    if (response is Map) {
      final m = Map<dynamic, dynamic>.from(response);
      for (final key in <String>['post_id', 'id']) {
        final o = m[key];
        if (o is int) {
          return o;
        }
        if (o is num) {
          return o.toInt();
        }
        if (o is String) {
          final p = int.tryParse(o.trim());
          if (p != null) {
            return p;
          }
        }
      }
    }
    if (kDebugMode) {
      debugPrint('VK wall.post: unexpected response shape: $response');
    }
    return null;
  }

  int get _gId {
    final s = AppEnv.vkGroupId;
    if (s.isEmpty) {
      return 0;
    }
    return int.tryParse(s) ?? 0;
  }

  String _msg(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    var t = raw.trim();
    if (t.length > 3000) {
      t = t.substring(0, 3000);
    }
    return t;
  }

  static MediaType _imageType(String path) {
    final n = path.toLowerCase();
    if (n.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (n.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (n.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  /// [photos.saveWallPhoto] → [wall.post]
  Future<VkPublishResult> publishPhotoToGroupWall(
    File file, {
    String? message,
  }) async {
    final g = _gId;
    if (g == 0) {
      throw StateError('VK_GROUP_ID');
    }
    final m1 = await _get('photos.getWallUploadServer', {'group_id': '$g'});
    final up = (m1['response'] as Map)['upload_url'] as String;
    final req = http.MultipartRequest('POST', Uri.parse(up));
    req.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        file.path,
        contentType: _imageType(file.path),
      ),
    );
    final upRes = await req.send().timeout(_uploadTimeout);
    if (upRes.statusCode < 200 || upRes.statusCode >= 300) {
      throw StateError('upload HTTP ${upRes.statusCode}');
    }
    final upText = utf8.decode(await upRes.stream.toBytes());
    final upJson = jsonDecode(upText) as Map<String, dynamic>;
    if (upJson['photo'] == null) {
      throw StateError('photo_upload: $upText');
    }
    final server = (upJson['server'] is int)
        ? (upJson['server'] as int)
        : int.parse('${upJson['server']}');
    final photo = upJson['photo'] as String;
    final hash = upJson['hash'] as String;

    final mSave = <String, String>{
      'group_id': '$g',
      'server': '$server',
      'photo': photo,
      'hash': hash,
      'access_token': AppEnv.vkApiAccessToken,
      'v': _v,
    };
    final uSave = Uri.https('api.vk.com', 'method/photos.saveWallPhoto');
    final rSave = await http
        .post(
          uSave,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          },
          body: _formBody(mSave),
        )
        .timeout(_getTimeout);
    final mJson = jsonDecode(utf8.decode(rSave.bodyBytes)) as Map<String, dynamic>;
    _throwIfError(mJson);
    final arr = mJson['response'] as List<dynamic>?;
    if (arr == null || arr.isEmpty) {
      throw StateError('saveWallPhoto: empty');
    }
    final ph = arr.first as Map<dynamic, dynamic>;
    final oid = (ph['owner_id'] as num).toInt();
    final pid = (ph['id'] as num).toInt();
    final att = 'photo${oid}_$pid';
    final wallRes = await _postFormResponse('wall.post', {
      'owner_id': '-$g',
      'from_group': '1',
      'message': _msg(message),
      'attachments': att,
    });
    final postId = _parseWallPostId(wallRes);
    if (postId == null) {
      if (kDebugMode) {
        debugPrint('VK wall.post (photo) raw: $wallRes');
      }
      throw StateError('wall.post: no post_id in response');
    }
    return VkPublishResult(postId: postId);
  }

  /// video.save → yük (video_file) → wall.post
  Future<VkPublishResult> publishVideoToGroupWall(
    File file, {
    String? message,
  }) async {
    final g = _gId;
    if (g == 0) {
      throw StateError('VK_GROUP_ID');
    }
    final m0 = await _get('video.save', {
      'group_id': '$g',
      'name': 'meme',
      'wallpost': '0',
    });
    final r0 = m0['response'] as Map<dynamic, dynamic>;
    final uploadUrl = r0['upload_url'] as String;
    final req = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    req.files.add(
      await http.MultipartFile.fromPath(
        'video_file',
        file.path,
        contentType: MediaType('video', 'mp4'),
      ),
    );
    final upRes = await req.send().timeout(_uploadTimeout);
    if (upRes.statusCode < 200 || upRes.statusCode >= 300) {
      throw StateError('upload HTTP ${upRes.statusCode}');
    }
    final upText = utf8.decode(await upRes.stream.toBytes());
    final upJson = jsonDecode(upText) as Map<String, dynamic>;
    if (upJson['error'] != null) {
      _throwIfError(upJson);
    }
    var ownerId = (upJson['owner_id'] as num?)?.toInt();
    var videoId = (upJson['video_id'] as num?)?.toInt();
    if (ownerId == null || videoId == null) {
      ownerId = (r0['owner_id'] as num?)?.toInt();
      videoId = (r0['video_id'] as num?)?.toInt();
    }
    if (ownerId == null || videoId == null) {
      debugPrint('VK video up: $upText');
      throw StateError('video_upload ids');
    }
    final att = 'video${ownerId}_$videoId';
    final wallRes = await _postFormResponse('wall.post', {
      'owner_id': '-$g',
      'from_group': '1',
      'message': _msg(message),
      'attachments': att,
    });
    final postId = _parseWallPostId(wallRes);
    if (postId == null) {
      if (kDebugMode) {
        debugPrint('VK wall.post (video) raw: $wallRes');
      }
      throw StateError('wall.post: no post_id in response');
    }
    return VkPublishResult(postId: postId);
  }

  Future<VkPublishResult> publishFile(
    File file, {
    required bool isVideo,
    String? message,
  }) async {
    if (isVideo) {
      return publishVideoToGroupWall(file, message: message);
    } else {
      return publishPhotoToGroupWall(file, message: message);
    }
  }

  /// Grup duvarı gönderisi: [posts] = -{groupId}_{postId}
  Future<VkPostStats?> fetchWallPostStats({
    required int groupId,
    required int postId,
  }) async {
    if (AppEnv.vkApiAccessToken.isEmpty) {
      return null;
    }
    final id = '-${groupId}_$postId';
    final m = await _get('wall.getById', {'posts': id});
    final arr = m['response'] as List<dynamic>?;
    if (arr == null || arr.isEmpty) {
      return null;
    }
    final post = arr.first;
    if (post is! Map) {
      return null;
    }
    final p = Map<dynamic, dynamic>.from(post);
    int? views;
    final v = p['views'];
    if (v is Map) {
      views = (v['count'] as num?)?.toInt();
    } else if (v is num) {
      views = v.toInt();
    }
    views ??= 0;
    int? likes;
    final lk = p['likes'];
    if (lk is Map) {
      likes = (lk['count'] as num?)?.toInt();
    }
    int? reposts;
    final rp = p['reposts'];
    if (rp is Map) {
      reposts = (rp['count'] as num?)?.toInt();
    }
    int? comments;
    final cm = p['comments'];
    if (cm is Map) {
      comments = (cm['count'] as num?)?.toInt();
    }
    return VkPostStats(
      views: views,
      likes: likes,
      reposts: reposts,
      comments: comments,
    );
  }

  /// [groups.getById] — topluluk üye sayısı (mümkünse).
  Future<int?> fetchGroupMembersCount(int groupId) async {
    if (AppEnv.vkApiAccessToken.isEmpty) {
      return null;
    }
    try {
      final m = await _get('groups.getById', {
        'group_id': groupId.toString(),
        'fields': 'members_count',
      });
      final arr = m['response'] as List<dynamic>?;
      if (arr == null || arr.isEmpty) {
        return null;
      }
      final g = arr.first;
      if (g is! Map) {
        return null;
      }
      return (g['members_count'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }
}
