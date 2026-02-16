import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/variables/user.dart';

final newUser = User(userId: PrefData.userId);
final newPreferences = UserPreferences(userId: PrefData.userId);

final anonymousUser = User(
  userId: 'anonymous',
  name: 'Friend',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);