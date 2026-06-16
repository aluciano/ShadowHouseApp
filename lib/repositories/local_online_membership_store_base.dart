import '../models/saved_online_room_membership.dart';

abstract class LocalOnlineMembershipStore {
  Future<SavedOnlineRoomMembership?> load();

  Future<void> save(SavedOnlineRoomMembership membership);

  Future<void> clear();
}
