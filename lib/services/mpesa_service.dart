import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
// ✅ Your current ngrok tunnel URL
  static const String baseUrl = "https://cephalometric-discernably-yahir.ngrok-free.dev";

  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required int amount,
  }) async {
    final url = Uri.parse("$baseUrl/stkpush");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phone, "amount": amount}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("M-Pesa payment failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error connecting to backend: $e");
    }
  }
}
