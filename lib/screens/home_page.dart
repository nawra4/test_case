import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/journal_service.dart';
import 'login_page.dart';
import 'create_journal_page.dart';
import 'journal_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalEntri = 0;
  double targetBulanan = 0;
  bool isLoading = true;
  bool isRefreshing = false;
  List<Map<String, dynamic>> journals = [];
  String userName = "User";
  String userEmail = "user@example.com";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final data = Map<String, dynamic>.from(jsonDecode(userData));
      setState(() {
        userName = data['name'] ?? userName;
        userEmail = data['email'] ?? userEmail;
      });
    }
  }

  Future<void> _initializeData() async {
    await _loadLocalJournals();
    await _syncWithServer();
  }

  Future<void> _loadLocalJournals() async {
    try {
      final localJournals = await JournalService.loadLocalJournals();
      if (mounted) {
        setState(() {
          journals = localJournals;
          totalEntri = journals.length;
          targetBulanan = totalEntri > 0 ? (totalEntri / 30) * 100 : 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading local journals: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _syncWithServer() async {
    if (isRefreshing) return;
    setState(() => isRefreshing = true);

    try {
      final syncedJournals = await JournalService.fetchAndSyncJournals();
      setState(() {
        journals = syncedJournals;
        totalEntri = journals.length;
        targetBulanan = totalEntri > 0 ? (totalEntri / 30) * 100 : 0;
      });
      await JournalService.retrySyncUnsyncedJournals();
      await _loadLocalJournals();
    } catch (e) {
      print('Error syncing with server: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal sync dengan server. Data lokal tetap aman."),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => isRefreshing = false);
    }
  }

  Future<void> _startWriting() async {
  final newJournal = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(builder: (_) => const CreateJournalPage()),
  );
    if (newJournal != null) {
    setState(() {
      journals.insert(0, newJournal); // langsung masukin ke list
      totalEntri = journals.length;
      targetBulanan = totalEntri > 0 ? (totalEntri / 30) * 100 : 0;
    });
    _showSnackBar("Jurnal berhasil dibuat!", Colors.green);
  }
}

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _editProfile() async {
  final result = await Navigator.push<Map<String, String>>(
    context,
    MaterialPageRoute(builder: (_) => EditProfilePage(name: userName, email: userEmail)),
  );
  if (result != null) {
    setState(() {
      userName = result['name'] ?? userName;
      userEmail = result['email'] ?? userEmail;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode({'name': userName, 'email': userEmail}));
  }
}

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
      );
    }
  }

  void _openJournalDetail(Map<String, dynamic> journal) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalDetailPage(
          journalId: journal['id'],
          title: journal['title'],
          content: journal['content'],
          date: journal['date'],
          time: journal['time'],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['deleted'] == true) {
          journals.removeWhere((j) => j['id'] == journal['id']);
        } else {
          final index = journals.indexWhere((j) => j['id'] == journal['id']);
          if (index != -1) {
            journals[index] = {
              ...journals[index],
              'title': result['title'] ?? journals[index]['title'],
              'content': result['content'] ?? journals[index]['content'],
              'synced': true,
            };
          }
        }
        totalEntri = journals.length;
        targetBulanan = totalEntri > 0 ? (totalEntri / 30) * 100 : 0;
      });
    }
  }

  Widget _buildLatestEntryCard(Map<String, dynamic> journal) {
    return GestureDetector(
      onTap: () => _openJournalDetail(journal),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(journal['title'] ?? 'Untitled', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(journal['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(journal['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Text(journal['content'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Jurnal Harian"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
  onTap: () => _showProfileMenu(),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: CircleAvatar(
      backgroundColor: Colors.teal[700],
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : "U",
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
),
          isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _syncWithServer,
                  tooltip: 'Sync dengan server',
                ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _syncWithServer,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Selamat Datang!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Bagaimana perasaan Anda hari ini?", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  "Prompt Harian",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Apa tiga hal yang paling Anda syukuri hari ini?",
                              style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _startWriting,
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text("Mulai Menulis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (journals.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Jurnal Terbaru", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[700])),
                          Text("${journals.length} jurnal", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...journals.map(_buildLatestEntryCard).toList(),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 50),
                            Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text("Belum ada jurnal", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text("Mulai menulis jurnal pertama Anda!", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Profile"),
              onTap: () {
                Navigator.pop(context);
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String name;
  final String email;
  const EditProfilePage({super.key, required this.name, required this.email});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    Navigator.pop(context, {'name': _nameController.text, 'email': _emailController.text});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama")),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              child: const Text("Simpan", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
