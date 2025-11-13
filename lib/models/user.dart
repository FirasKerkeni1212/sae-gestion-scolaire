// lib/models/user.dart
class User {
  final int? id;
  final String identifiant;
  final String password;
  final String nom;
  final String prenom;
  final String role;
  final int? classeId; // AJOUTÉ

  User({
    this.id,
    required this.identifiant,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.role,
    this.classeId, // AJOUTÉ
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identifiant': identifiant,
      'password': password,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'classe_id': classeId, // AJOUTÉ
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      identifiant: map['identifiant'] as String,
      password: map['password'] as String,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      role: map['role'] as String,
      classeId: map['classe_id'] as int?, // AJOUTÉ
    );
  }

  User copyWith({
    int? id,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      identifiant: identifiant,
      password: password ?? this.password,
      nom: nom,
      prenom: prenom,
      role: role,
      classeId: classeId,
    );
  }
}