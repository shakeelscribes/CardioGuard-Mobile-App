import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.age,
    this.gender,
    this.height,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
    age: json['age'],
    gender: json['gender'],
    height: json['height']?.toDouble(),
    weight: json['weight']?.toDouble(),
  );
}

class PredictionRecord {
  final String id;
  final DateTime date;
  final int gender;
  final int ageYears;
  final int height;
  final double weight;
  final int apHi;
  final int apLo;
  final int cholesterol;
  final int gluc;
  final int smoke;
  final int alco;
  final int active;
  final bool prediction;
  final double probability;
  final String riskLevel;
  final String advice;
  final double bmi;
  final String bmiCategory;

  PredictionRecord({
    required this.id,
    required this.date,
    required this.gender,
    required this.ageYears,
    required this.height,
    required this.weight,
    required this.apHi,
    required this.apLo,
    required this.cholesterol,
    required this.gluc,
    required this.smoke,
    required this.alco,
    required this.active,
    required this.prediction,
    required this.probability,
    required this.riskLevel,
    required this.advice,
    required this.bmi,
    required this.bmiCategory,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'gender': gender,
    'age_years': ageYears,
    'height': height,
    'weight': weight,
    'ap_hi': apHi,
    'ap_lo': apLo,
    'cholesterol': cholesterol,
    'gluc': gluc,
    'smoke': smoke,
    'alco': alco,
    'active': active,
    'prediction': prediction,
    'probability': probability,
    'risk_level': riskLevel,
    'advice': advice,
    'bmi': bmi,
    'bmi_category': bmiCategory,
  };

  factory PredictionRecord.fromJson(Map<String, dynamic> json) => PredictionRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    gender: json['gender'],
    ageYears: json['age_years'],
    height: json['height'],
    weight: (json['weight'] as num).toDouble(),
    apHi: json['ap_hi'],
    apLo: json['ap_lo'],
    cholesterol: json['cholesterol'],
    gluc: json['gluc'],
    smoke: json['smoke'],
    alco: json['alco'],
    active: json['active'],
    prediction: json['prediction'],
    probability: (json['probability'] as num).toDouble(),
    riskLevel: json['risk_level'],
    advice: json['advice'],
    bmi: (json['bmi'] as num).toDouble(),
    bmiCategory: json['bmi_category'],
  );
}