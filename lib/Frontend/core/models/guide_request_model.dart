import 'package:equatable/equatable.dart';

class GuideRequestModel extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime createdAt;

  const GuideRequestModel({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImage,
    required this.createdAt,
  });

  factory GuideRequestModel.fromJson(Map<String, dynamic> json) {
    return GuideRequestModel(
      userId: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, name, email, profileImage, createdAt];
}
