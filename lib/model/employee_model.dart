class Employee {
  String id;
  String name;
  String position;
  String email;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.email,
  });

  // Converts a Firestore document to an Employee object
  factory Employee.fromMap(Map<String, dynamic> data, String documentId) {
    return Employee(
      id: documentId,
      name: data['name'],
      position: data['position'],
      email: data['email'],
    );
  }

  // Converts an Employee object to a map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'email': email,
    };
  }
}
