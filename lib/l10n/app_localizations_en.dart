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
  String get disclaimerAccept => 'I understand';

  @override
  String get nicknameTitle => 'What\'s your name?';

  @override
  String get nicknameHint => 'Enter a name (3-20 characters)';

  @override
  String get nicknameError => 'Name must be 3-20 characters';

  @override
  String get continueLabel => 'Continue';

  @override
  String get createGroup => 'Create group';

  @override
  String get joinGroup => 'Join group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupPin => 'Group PIN (optional)';

  @override
  String get nearbyGroups => 'Nearby groups';

  @override
  String get noNearbyGroups => 'No groups yet. Create one or wait.';

  @override
  String get send => 'Send';

  @override
  String get sendLocation => 'Send location';

  @override
  String get sendLocationConfirm => 'Send your location now?';

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
  String get lowBatteryMode => 'Power saver on';

  @override
  String get permissionRequired => 'Permission needed';

  @override
  String get permissionExplanation =>
      'NearBuddy needs Bluetooth and location access to find devices near you.';

  @override
  String get grantPermission => 'Allow';

  @override
  String get nicknameInUse =>
      'This name is already taken by another member. Choose another.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeNickname => 'Change name';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get members => 'Members';

  @override
  String get verifyTitle => 'Verify device';

  @override
  String get verifyBody => 'Both devices must show the same number:';

  @override
  String get verifyMatch => 'Numbers match';

  @override
  String get verifyMismatch => 'Don\'t match';

  @override
  String get groupCode => 'Group code';

  @override
  String get pinError => 'PIN must be at least 4 digits';

  @override
  String get groupCodeHint => 'Enter code';

  @override
  String get dmSessions => 'Private messages';

  @override
  String get dmNew => 'New conversation';

  @override
  String get dmEmpty =>
      'No conversations yet. Start from the member list or enter a device ID.';

  @override
  String get dmPeerDeviceId => 'Device ID';

  @override
  String get dmPeerNickname => 'Contact name';

  @override
  String get dmKeyMissing =>
      'Device key missing — try again after group verification';

  @override
  String get decryptFailed => 'This message can\'t be read';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get permissionDenied =>
      'Bluetooth and location permission is needed to find nearby devices.';

  @override
  String get sessionStartFailed =>
      'Couldn\'t start the session — check Bluetooth/Wi-Fi and try again.';

  @override
  String get nicknameSaved => 'Name updated';

  @override
  String get tagline => 'Chat without internet, without servers.';

  @override
  String get readyStatus => 'Ready for direct connection';

  @override
  String get readyStatusDesc =>
      'All messages are encrypted and stay only on this device.';

  @override
  String get createGroupDesc => 'Create a space to talk without internet.';

  @override
  String get joinGroupDesc => 'Enter a group code to join.';

  @override
  String get dmSessionsDesc => 'Chat directly with nearby devices.';

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
  String get codeCopied => 'Code copied.';

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
  String get connOutOfRange => 'Out of range — resend when connected';

  @override
  String get connRadioOff => 'Bluetooth/Wi-Fi is off — enable it to connect';

  @override
  String devicesFound(int count) {
    return '$count devices nearby';
  }

  @override
  String get devicesEmpty =>
      'No devices nearby. Make sure Bluetooth/Wi-Fi is on.';

  @override
  String get devicesNearbySection => 'Nearby devices';

  @override
  String get deviceDetected => 'detected';

  @override
  String get pinWrong => 'Wrong PIN — try again';

  @override
  String get nicknameTaken => 'Name already taken in this group';

  @override
  String get groupFull => 'Group is full';

  @override
  String get joinRejected => 'Join rejected by a member';

  @override
  String get sessionEndedTitle => 'Group session ended';

  @override
  String get sessionEndedHint =>
      'The group key is gone after a restart — rejoin to keep chatting.';

  @override
  String get rejoinLabel => 'Rejoin';

  @override
  String get retryHint => 'Tap to resend';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get retryLabel => 'Try again';

  @override
  String get typingIndicator => 'is typing…';

  @override
  String get leaveConfirmTitle => 'Leave group?';

  @override
  String get leaveConfirmBody =>
      'You\'ll stop receiving messages from this group.';

  @override
  String get leaveLabel => 'Leave';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deviceIdHelp =>
      'Used to identify this device on the local network.';

  @override
  String get securityDesc => 'Messages are encrypted in transit.';

  @override
  String get messagePending => 'Waiting for connection';

  @override
  String get messageFailed => 'Failed — tap to resend';

  @override
  String get connConnecting => 'Connecting…';

  @override
  String get connDisconnected => 'Not connected';

  @override
  String get devicesAvailable => 'Available';

  @override
  String get devicesConnected => 'Connected';

  @override
  String get devicesEmptyTitle => 'No devices nearby yet';

  @override
  String get devicesEmptyHint =>
      'Make sure NearBuddy is open on your friend\'s device.';

  @override
  String get searchAgain => 'Search again';

  @override
  String get seeAllDevices => 'See all devices';

  @override
  String get communicationSection => 'Communication';

  @override
  String get myGroupsSection => 'My groups';

  @override
  String get inviteDevices => 'Invite devices';

  @override
  String get inviteDevicesHint =>
      'Selected devices will connect automatically when they join.';

  @override
  String get startChat => 'Start chat';

  @override
  String connectingTo(String name) {
    return 'Connecting to $name…';
  }

  @override
  String get creatingGroup => 'Creating group…';

  @override
  String get groupNotFound => 'Can\'t find the group';

  @override
  String get groupNotFoundHint =>
      'Make sure the code is correct and the group owner is active.';

  @override
  String connectionLost(String name) {
    return 'Connection with $name lost';
  }

  @override
  String get messageWillWait =>
      'Messages will be marked as waiting — tap the message to resend.';

  @override
  String get deviceIdCopied => 'Device ID copied.';

  @override
  String get securityTitle => 'Message security';

  @override
  String get securityBody =>
      'Messages are encrypted when sent and stored only on this device.';

  @override
  String get learnSecurity => 'Learn how security works';

  @override
  String get securityDialogTitle => 'How security works';

  @override
  String get securityDialogBody =>
      'NearBuddy uses a per-device X25519 key, 6-digit verification, and AES-GCM encryption. Relay devices only forward messages — they can\'t read them.';

  @override
  String get pendingConnectionLabel => 'Waiting for connection';

  @override
  String get chatEmptyTitle => 'Start a conversation';

  @override
  String chatEmptyBody(String name) {
    return 'Send your first message to $name.';
  }

  @override
  String get settingsProfileHint => 'Name visible to other devices';

  @override
  String get settingsChangeNickname => 'Change name';

  @override
  String get aboutSection => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutNearBuddy => 'About NearBuddy';

  @override
  String get encryptionRow => 'Encryption';

  @override
  String get encryptionRowSubtitle => 'Messages are encrypted in transit';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System default';

  @override
  String get menuDisconnect => 'Disconnect';

  @override
  String get menuEncryptedInfo => 'End-to-end encrypted · direct connection';

  @override
  String get connError => 'Connection failed';

  @override
  String get emojiPickerTitle => 'Emoji';

  @override
  String get emojiCatSmileys => 'Smileys & Expressions';

  @override
  String get emojiCatGestures => 'Gestures & Hands';

  @override
  String get emojiCatHearts => 'Hearts';

  @override
  String get emojiCatAnimals => 'Animals & Food';

  @override
  String get emojiCatSymbols => 'Symbols';

  @override
  String get languageDialogSubtitle => 'Choose the interface language';

  @override
  String get themeSheetSubtitle => 'Choose how the app looks';

  @override
  String get themeLightDesc => 'Bright and clean';

  @override
  String get themeDarkDesc => 'Easy on the eyes in low light';

  @override
  String get themeSystemDesc => 'Follows your device setting';

  @override
  String get applyLabel => 'Apply';

  @override
  String get messageHint => 'Type a message…';

  @override
  String get secureDirectTagline => 'Secure. Private. Direct.';

  @override
  String get aboutBody =>
      'NearBuddy is a peer-to-peer messaging app that works without internet or cellular signal. Messages are encrypted and stored only on your device.';
}
