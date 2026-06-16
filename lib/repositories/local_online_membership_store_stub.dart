import '../models/saved_online_room_membership.dart';
import 'local_online_membership_store_base.dart';

class _NoopLocalOnlineMembershipStore implements LocalOnlineMembershipStore {
  @override
  Future<void> clear() async {}

  @override
  Future<SavedOnlineRoomMembership?> load() async => null;

  @override
  Future<void> save(SavedOnlineRoomMembership membership) async {}
}

LocalOnlineMembershipStore createLocalOnlineMembershipStoreImpl() =>
    _NoopLocalOnlineMembershipStore();
