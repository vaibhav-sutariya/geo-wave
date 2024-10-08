class Office {
  String id;
  String officeName;
  String officeLat;
  String officeLong;
  String range;

  Office({
    required this.id,
    required this.officeName,
    required this.officeLat,
    required this.officeLong,
    required this.range,
  });

  // Converts a Firestore document to an Office object
  factory Office.fromMap(Map<String, dynamic> data, String documentId) {
    return Office(
      id: documentId,
      officeName: data['officeName'],
      officeLat: data['officeLat'],
      officeLong: data['officeLong'],
      range: data['range'],
    );
  }

  // Converts an Office object to a map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'officeName': officeName,
      'officeLat': officeLat,
      'officeLong': officeLong,
      'range': range,
    };
  }
}
