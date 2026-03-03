enum Role { civil, impostor }

class Player {
  final String name;
  final Role role;
  final bool alive;

  const Player({
    required this.name,
    required this.role,
    this.alive = true,
  });

  Player copyWith({String? name, Role? role, bool? alive}) {
    return Player(
      name: name ?? this.name,
      role: role ?? this.role,
      alive: alive ?? this.alive,
    );
  }
}
