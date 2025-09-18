import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
    static const String baseUrl = "http://10.0.2.2:8000/api";

  // SAVE TOKEN
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // SAVE USER DATA
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_data", jsonEncode(user));
  }

  // GET USER DATA
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("user_data");
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
      String username, String email, String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "password_confirmation": confirmPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
      if (data['user'] != null) {
        await saveUser(data['user']);
      }
    }

    return data;
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String email, String password) async {
  final response = await http.post(
    Uri.parse("$baseUrl/login"),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "email": email,
      "password": password,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    final token = data['token'] ??
        data['data']?['token'] ??
        data['access_token'];

    if (token != null) {
      await saveToken(token);
    }

    if (data['user'] != null) {
      await saveUser(data['user']);
    }
  }

  return data;
}

  // GET TOKEN
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // LOGOUT
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // konsisten
    await prefs.remove('user_data');
  }

  // FETCH JURNAL
  static Future<List<Map<String, dynamic>>> fetchJournals() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/journals"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Gagal ambil data jurnal");
    }
  }

  // SUBMIT JURNAL
static Future<Map<String, dynamic>?> submitJournal(
    String title, String content) async {
  final token = await getToken();
  final body = jsonEncode({
    "title": title,
    "content": content,
  });

  print("📡 Kirim body: $body");

  final response = await http.post(
    Uri.parse("http://127.0.0.1:8000/api/journals"),
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: body,
  );

  print("📡 Status: ${response.statusCode}");
  print("📡 Response: ${response.body}");

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

  // UPDATE PROFILE
  static Future<Map<String, dynamic>?> updateUserProfile({
    required String username,
    required String email,
    File? photoFile,
  }) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/user/update"),
    );

    request.headers['Authorization'] = "Bearer $token";
    request.fields['username'] = username;
    request.fields['email'] = email;

    if (photoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("photo", photoFile.path),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      if (data['user'] != null) {
        await saveUser(data['user']);
      }
      return data['user'];
    } else {
      return null;
    }
  }
}