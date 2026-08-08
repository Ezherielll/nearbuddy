/// Curated emoji catalog for the in-app emoji picker.
/// Offline-first: plain Unicode strings, no package, no assets.
/// [labelKey] maps to an `AppLocalizations` getter via a switch in the UI.
class EmojiCategory {
  final String labelKey;
  final List<String> emojis;

  const EmojiCategory(this.labelKey, this.emojis);
}

const List<EmojiCategory> emojiCatalog = [
  EmojiCategory('emojiCatSmileys', [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😉',
    '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋', '😛',
    '😜', '🤪', '😝', '🤗', '🤭', '🤫', '🤔', '🤨', '😐', '😑',
    '😶', '😏', '😒', '🙄', '😬', '😌', '😔', '😪', '🤤', '😴',
    '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '😵', '🤯',
  ]),
  EmojiCategory('emojiCatGestures', [
    '👍', '👎', '👌', '🤌', '✌️', '🤞', '🤟', '🤘', '🤙', '👈',
    '👉', '👆', '👇', '☝️', '✋', '🤚', '🖖', '👋', '🤝', '🙏',
    '💪',
  ]),
  EmojiCategory('emojiCatHearts', [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
  ]),
  EmojiCategory('emojiCatAnimals', [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🍕', '🍔',
    '🍟', '🌭', '🍿', '🍩', '🍎', '☕', '🍺',
  ]),
  EmojiCategory('emojiCatSymbols', [
    '⭐', '🌟', '✨', '🔥', '💯', '💢', '💤', '🎉', '🎊', '🚀',
    '⚽', '🎮', '🎵', '🎁', '✅', '❌', '⚠️', '🎯',
  ]),
];
