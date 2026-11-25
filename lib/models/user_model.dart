class UserModel {
  final String name;
  final String email;
  final String passwordHash;
  final double strideLengthMeters;
  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String fitnessGoal;
  final bool biometricEnabled;
  final bool faceAuthEnabled;
  final bool acceptedPrivacyPolicy;

  const UserModel({
    required this.name,
    required this.email,
    required this.passwordHash,
    this.strideLengthMeters = 0.74,
    this.age = 20,
    this.weightKg = 70.0,
    this.heightCm = 170.0,
    this.gender = 'Masculino',
    this.fitnessGoal = 'Caminata saludable',
    this.biometricEnabled = false,
    this.faceAuthEnabled = false,
    this.acceptedPrivacyPolicy = true,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? passwordHash,
    double? strideLengthMeters,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    String? fitnessGoal,
    bool? biometricEnabled,
    bool? faceAuthEnabled,
    bool? acceptedPrivacyPolicy,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      strideLengthMeters: strideLengthMeters ?? this.strideLengthMeters,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      faceAuthEnabled: faceAuthEnabled ?? this.faceAuthEnabled,
      acceptedPrivacyPolicy:
      acceptedPrivacyPolicy ?? this.acceptedPrivacyPolicy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'strideLengthMeters': strideLengthMeters,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender,
      'fitnessGoal': fitnessGoal,
      'biometricEnabled': biometricEnabled,
      'faceAuthEnabled': faceAuthEnabled,
      'acceptedPrivacyPolicy': acceptedPrivacyPolicy,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: (json['name'] ?? 'Usuario NexPulse') as String,
      email: (json['email'] ?? '') as String,
      passwordHash: (json['passwordHash'] ?? '') as String,
      strideLengthMeters:
      ((json['strideLengthMeters'] ?? 0.74) as num).toDouble(),
      age: ((json['age'] ?? 20) as num).toInt(),
      weightKg: ((json['weightKg'] ?? 70.0) as num).toDouble(),
      heightCm: ((json['heightCm'] ?? 170.0) as num).toDouble(),
      gender: (json['gender'] ?? 'Masculino') as String,
      fitnessGoal: (json['fitnessGoal'] ?? 'Caminata saludable') as String,
      biometricEnabled: (json['biometricEnabled'] ?? false) as bool,
      faceAuthEnabled: (json['faceAuthEnabled'] ?? false) as bool,
      acceptedPrivacyPolicy: (json['acceptedPrivacyPolicy'] ?? true) as bool,
    );
  }
}