class Member {
  final int id;
  final String fullName;
  final int age;
  final double weight;
  final double height;
  final String gender;

  Member({
    required this.id,
    required this.fullName,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      fullName: json['fullName'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      gender: json['gender'],
    );
  }
}
