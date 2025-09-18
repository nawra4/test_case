import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/journal/journal_bloc.dart';
import '../blocs/journal/journal_event.dart';
import '../blocs/journal/journal_state.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'create_journal_page.dart';
import 'journal_detail_page.dart';
import 'edit_journal_page.dart';
import 'edit_profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String userEmail = "user@example.com";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Load jurnal otomatis
    context.read<JournalBloc>().add(LoadJournals());
  }

  Future<void> _loadUserData() async {
    final user = await ApiService.getUser();
    if (user != null) {
      setState(() {
        userName = user['name'] ?? userName;
        userEmail = user['email'] ?? userEmail;
      });
    }
  }

  Future<void> _logout() async {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _startWriting(BuildContext context) async {
    final newJournal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CreateJournalPage()),
    );
    if (newJournal != null) {
      context.read<JournalBloc>().add(CreateJournal(
            title: newJournal['title'],
            content: newJournal['content'],
          ));
      _showSnackBar("Jurnal berhasil dibuat!", Colors.green);
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              EditProfilePage(name: userName, email: userEmail, username: '')),
    );
    if (result != null) {
      setState(() {
        userName = result['name'] ?? userName;
        userEmail = result['email'] ?? userEmail;
      });
      await ApiService.saveUser({'name': userName, 'email': userEmail});
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 3)),
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
      if (result['deleted'] == true) {
        context.read<JournalBloc>().add(DeleteJournal(journal['id'], id: ''));
      } else {
        context.read<JournalBloc>().add(UpdateJournal(
              id: journal['id'],
              title: result['title'] ?? journal['title'],
              content: result['content'] ?? journal['content'],
            ));
      }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      journal['title'] ?? 'Untitled',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditJournalPage(
                            journalId: journal['id'].toString(),
                            journal: journal,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(journal['date'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(journal['time'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                journal['content'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JournalBloc(apiService: ApiService())..add(LoadJournals()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Jurnal Harian"),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          actions: [
            GestureDetector(
              onTap: _showProfileMenu,
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  context.read<JournalBloc>().add(SyncJournals()),
              tooltip: 'Sync dengan server',
            ),
          ],
        ),
        body: BlocBuilder<JournalBloc, JournalState>(
          builder: (context, state) {
            if (state is JournalLoaded) {
              final journals = state.journals;
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<JournalBloc>().add(SyncJournals());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selamat Datang!",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Bagaimana perasaan Anda hari ini?",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline,
                                      color: Colors.amber, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Prompt Harian",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Apa tiga hal yang paling Anda syukuri hari ini?",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    height: 1.4),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _startWriting(context),
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  label: const Text("Mulai Menulis",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
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
                            Text("Jurnal Terbaru",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700])),
                            Text("${journals.length} jurnal",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...journals.map(_buildLatestEntryCard).toList(),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              Icon(Icons.book_outlined,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text("Belum ada jurnal",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text("Mulai menulis jurnal pertama Anda!",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            } else if (state is JournalError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
