// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NearBuddy';

  @override
  String get disclaimerTitle => 'Important Notice';

  @override
  String get disclaimerBody =>
      'NearBuddy is a community communication tool, not a substitute for official emergency services. Do not rely on this app as your sole tool in emergency situations.';

  @override
  String get disclaimerAccept => 'I Understand';

  @override
  String get nicknameTitle => 'What is your name?';

  @override
  String get nicknameHint => 'Enter nickname (3-20 characters)';

  @override
  String get nicknameError => 'Nickname must be 3-20 characters';

  @override
  String get continueLabel => 'Continue';

  @override
  String get createGroup => 'Create Group';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupPin => 'Group PIN (optional)';

  @override
  String get nearbyGroups => 'Nearby Groups';

  @override
  String get noNearbyGroups => 'No groups found. Create one or wait.';

  @override
  String get send => 'Send';

  @override
  String get sendLocation => 'Send My Location';

  @override
  String get sendLocationConfirm => 'Send your current coordinates now?';

  @override
  String get locationPingLabel => 'Location';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String memberCount(int count) {
    return '$count member(s)';
  }

  @override
  String get messageSent => 'Sent';

  @override
  String get messageDelivered => 'Delivered';

  @override
  String get lowBatteryMode => 'Power Saver Active';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionExplanation =>
      'NearBuddy needs Bluetooth and Location permissions to discover nearby devices.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get nicknameInUse => 'Nickname already taken. Please choose another.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get members => 'Members';

  @override
  String get verifyTitle => 'Verify Device';

  @override
  String get verifyBody => 'Both devices must show the same number:';

  @override
  String get verifyMatch => 'Numbers Match';

  @override
  String get verifyMismatch => 'Mismatch';

  @override
  String get groupCode => 'Group Code';

  @override
  String get pinError => 'PIN must be at least 4 digits';

  @override
  String get groupCodeHint => 'Enter the group code to join';

  @override
  String get dmSessions => 'Private Messages';

  @override
  String get dmNew => 'New Conversation';

  @override
  String get dmEmpty =>
      'No conversations yet. Start from the member list or enter a device ID.';

  @override
  String get dmPeerDeviceId => 'Device ID';

  @override
  String get dmPeerNickname => 'Contact Name';

  @override
  String get dmKeyMissing =>
      'Device key missing — try again after group verification';

  @override
  String get decryptFailed => 'Cannot decrypt this message';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get permissionDenied =>
      'Bluetooth/Location permission is required to discover nearby devices.';

  @override
  String get sessionStartFailed =>
      'Failed to start session — check Bluetooth/WiFi and try again.';

  @override
  String get nicknameSaved => 'Nickname updated';

  @override
  String get tagline => 'Chat without internet, without servers.';

  @override
  String get readyStatus => 'Ready for direct connection';

  @override
  String get readyStatusDesc =>
      'All messages are encrypted and stay on this device.';

  @override
  String get createGroupDesc => 'Create a new room, with optional PIN';

  @override
  String get joinGroupDesc => 'Join a group with a code';

  @override
  String get dmSessionsDesc => 'End-to-end encrypted 1:1 conversations';

  @override
  String get homeEmptyTitle => 'Start your first conversation';

  @override
  String get homeEmptyDesc =>
      'Create a group or join with a code — no data leaves your device.';

  @override
  String get disclaimerBullet1 => 'Works without internet or cellular signal';

  @override
  String get disclaimerBullet2 => 'All messages are end-to-end encrypted';

  @override
  String get disclaimerBullet3 =>
      'Not a substitute for official emergency services';

  @override
  String get encryptedLabel => 'Encrypted';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get copyCode => 'Copy';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get sendMessageTooltip => 'Send message';

  @override
  String get sendLocationTooltip => 'Send location';

  @override
  String get groupSection => 'General';

  @override
  String get identitySection => 'Identity';

  @override
  String get securitySection => 'Security';

  @override
  String get verifiedDevice => 'Verified device';

  @override
  String get verifyCopyHint =>
      'Both devices must show the same number. Compare before continuing.';

  @override
  String get connConnected => 'Connected directly';

  @override
  String get connSearching => 'Searching for devices…';

  @override
  String get connOutOfRange =>
      'Out of range — messages send automatically when connected';

  @override
  String get connRadioOff => 'Bluetooth/Wi-Fi off — enable to connect';

  @override
  String devicesFound(int count) {
    return '$count devices nearby';
  }

  @override
  String get devicesEmpty =>
      'No devices detected nearby. Make sure Bluetooth/Wi-Fi is on.';

  @override
  String get devicesNearbySection => 'Nearby Devices';

  @override
  String get deviceDetected => 'detected';

  @override
  String get pinWrong => 'Wrong PIN — try again';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get retryLabel => 'Retry';

  @override
  String get typingIndicator => 'is typing…';

  @override
  String get leaveConfirmTitle => 'Leave group?';

  @override
  String get leaveConfirmBody => 'Old messages stay on this device.';

  @override
  String get leaveLabel => 'Leave';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deviceIdHelp =>
      'Share this ID to start a 1:1 conversation, or use it for technical support.';

  @override
  String get securityDesc =>
      'X25519 + AES-GCM end-to-end — relays cannot read messages.';

  @override
  String get messagePending => 'Waiting for device';

  @override
  String get messageFailed => 'Failed — tap to resend';
}
