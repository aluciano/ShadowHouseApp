import 'dart:convert';
import 'dart:io';

import '../models/saved_online_room_membership.dart';
import 'local_online_membership_store_base.dart';

class _FileLocalOnlineMembershipStore implements LocalOnlineMembershipStore {
  static const _fileName = 'shadow_house_online_membership.json';

  File get _file => File('${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName');

  @override
  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  @override
  Future<SavedOnlineRoomMembership?> load() async {
    if (!await _file.exists()) {
      return null;
    }

    final content = await _file.readAsString();

    if (content.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return SavedOnlineRoomMembership.fromJson(decoded);
  }

  @override
  Future<void> save(SavedOnlineRoomMembership membership) async {
    await _file.writeAsString(jsonEncode(membership.toJson()));
  }
}

LocalOnlineMembershipStore createLocalOnlineMembershipStoreImpl() =>
    _FileLocalOnlineMembershipStore();
