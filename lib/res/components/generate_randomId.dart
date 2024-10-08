// Function to generate a random string of alphabets and digits
import 'dart:math';

String generateRandomId(String officeName) {
  final random = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  String randomString =
      List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  return officeName.replaceAll(' ', '') +
      randomString; // Remove spaces from office name
}
