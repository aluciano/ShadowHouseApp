// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import '../models/saved_online_room_membership.dart';
import 'local_online_membership_store_base.dart';

class _WebLocalOnlineMembershipStore implements LocalOnlineMembershipStore {
  static const _storageKey = 'shadow_house_online_membership';

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_storageKey);
  }

  @override
  Future<SavedOnlineRoomMembership?> load() async {
    final content = html.window.localStorage[_storageKey];

    if (content == null || content.trim().isEmpty) {
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
    html.window.localStorage[_storageKey] = jsonEncode(membership.toJson());
  }
}

LocalOnlineMembershipStore createLocalOnlineMembershipStoreImpl() =>
    _WebLocalOnlineMembershipStore();
