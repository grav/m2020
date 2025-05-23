import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://jlvmxdpxcgxjusyyomzb.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impsdm14ZHB4Y2d4anVzeXlvbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgwMjI3MDEsImV4cCI6MjA2MzU5ODcwMX0.yczFGMz5XWzvNsboYkVOpXPuWrPm7fIi1S8qoFiotX8';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Messages table operations
  static Future<void> sendMessage({
    required String username,
    required String message,
    required DateTime timestamp,
    required bool isWinner,
    required String mirrorTime,
  }) async {
    await client.from('messages').insert({
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_winner': isWinner,
      'mirror_time': mirrorTime,
    });
  }
  
  static Future<List<Map<String, dynamic>>> getMessages() async {
    final response = await client
        .from('messages')
        .select()
        .order('timestamp', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Stream<List<Map<String, dynamic>>> messagesStream() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: true);
  }
  
  // Winners table operations
  static Future<bool> checkAndSetWinner(String mirrorTime, String username) async {
    try {
      // Try to insert a winner record
      await client.from('winners').insert({
        'mirror_time': mirrorTime,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true; // Successfully set as winner
    } catch (e) {
      // If insert fails due to unique constraint, someone else won
      return false;
    }
  }
  
  static Future<List<String>> getWonTimes() async {
    final response = await client
        .from('winners')
        .select('mirror_time');
    return List<String>.from(response.map((row) => row['mirror_time']));
  }
}