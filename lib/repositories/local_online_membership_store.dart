import 'local_online_membership_store_base.dart';
import 'local_online_membership_store_stub.dart'
    if (dart.library.io) 'local_online_membership_store_io.dart'
    if (dart.library.html) 'local_online_membership_store_web.dart';

LocalOnlineMembershipStore createLocalOnlineMembershipStore() =>
    createLocalOnlineMembershipStoreImpl();
