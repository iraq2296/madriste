import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../models/models.dart';
import '../store/data_store.dart';
import '../store/preview_seed.dart';

/// Global data store. Seeded only in preview mode.
final dataStoreProvider = ChangeNotifierProvider<DataStore>((ref) {
  final store = DataStore();
  if (Env.isPreview) seedPreviewData(store);
  return store;
});

class SessionState {
  const SessionState({this.user, this.activeSchoolId, this.supportSessionId, this.ownerId});

  final AppUser? user;

  /// The school context currently selected (teachers can switch between
  /// schools; data is always scoped to this school).
  final String? activeSchoolId;

  /// When the owner uses Support Access, these are set and the UI renders the
  /// target user's interface with sensitive actions blocked.
  final String? supportSessionId;
  final String? ownerId;

  bool get isAuthenticated => user != null;
  bool get isSupportAccess => supportSessionId != null;

  SessionState copyWith({AppUser? user, String? activeSchoolId}) => SessionState(
        user: user ?? this.user,
        activeSchoolId: activeSchoolId ?? this.activeSchoolId,
        supportSessionId: supportSessionId,
        ownerId: ownerId,
      );
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._ref) : super(const SessionState());
  final Ref _ref;

  DataStore get _store => _ref.read(dataStoreProvider);

  /// Starts a session for [user] after successful OTP verification.
  void signIn(AppUser user) {
    final schools = _store.schoolsOf(user.id);
    state = SessionState(user: user, activeSchoolId: schools.isEmpty ? null : schools.first.id);
  }

  void switchSchool(String schoolId) => state = state.copyWith(activeSchoolId: schoolId);

  /// Owner enters [target]'s interface for troubleshooting. Audited.
  void startSupportAccess({required AppUser owner, required AppUser target, required String sessionId}) {
    final schools = _store.schoolsOf(target.id);
    state = SessionState(
      user: target,
      activeSchoolId: schools.isEmpty ? null : schools.first.id,
      supportSessionId: sessionId,
      ownerId: owner.id,
    );
  }

  /// Ends Support Access and returns to the owner account.
  void endSupportAccess() {
    final sid = state.supportSessionId;
    final owner = _store.userById(state.ownerId);
    if (sid != null) {
      for (final s in _store.supportSessions) {
        if (s.id == sid) s.endedAt = DateTime.now();
      }
      _store.commit();
    }
    state = owner == null ? const SessionState() : SessionState(user: owner);
  }

  void signOut() => state = const SessionState();
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) => SessionController(ref));

/// Current user (throws if used outside an authenticated area).
final currentUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(sessionProvider).user;
  if (user == null) throw StateError('No authenticated user');
  return user;
});

/// True when a paid account's subscription has ended → read-only mode.
final readOnlyProvider = Provider<bool>((ref) {
  final user = ref.watch(sessionProvider).user;
  if (user == null) return false;
  return ref.watch(dataStoreProvider).isReadOnly(user);
});

