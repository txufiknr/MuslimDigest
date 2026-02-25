import 'package:flutter/cupertino.dart';

enum NotificationType {
  all,
  digest,
  none;

  String get label {
    switch (this) {
      case all: return "All notifications";
      case digest: return "Digest notifications";
      case none: return "No notifications";
    }
  }

  IconData get icon {
    switch (this) {
      case all: return CupertinoIcons.bell;
      case digest: return CupertinoIcons.app_badge;
      case none: return CupertinoIcons.bell_slash;
    }
  }

  static NotificationType fromString(String value) {
    return values.firstWhere((type) => type.name == value, orElse: () => all);
  }
}