class GroupSession {
  final String id;
  final String name;
  final String? pin;
  final DateTime createdAt;
  final bool isOwner;
  const GroupSession({
    required this.id, required this.name, required this.createdAt,
    this.pin, this.isOwner = false,
  });
}
