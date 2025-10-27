import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  static const String baseUrl = "https://your-render-app.onrender.com/api/mpesa";

  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required int amount,
  }) async {
    final url = Uri.parse("$baseUrl/stkpush");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "amount": amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("M-Pesa payment failed: ${response.body}");
    }
  }
}
