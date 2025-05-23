import 'package:flutter/material.dart';
import 'supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MirrorTimeChatApp());
}

class MirrorTimeChatApp extends StatelessWidget {
  const MirrorTimeChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror Time Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;
  final bool isWinner;

  ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
    this.isWinner = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final Set<String> _wonTimes = {};
  String _currentUsername = '';
  bool _isUsernameSet = false;
  DateTime _timeOffset = DateTime.now();
  bool _showTimeControls = false;
  bool _isLoading = false;

  final List<String> _mirrorTimes = [
    '00:00', '01:01', '02:02', '03:03', '04:04', '05:05',
    '06:06', '07:07', '08:08', '09:09', '10:10', '11:11',
    '12:12', '13:13', '14:14', '15:15', '16:16', '17:17',
    '18:18', '19:19', '20:20', '21:21', '22:22', '23:23'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final wonTimes = await SupabaseService.getWonTimes();
      setState(() {
        _wonTimes.addAll(wonTimes);
      });
      _subscribeToMessages();
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    SupabaseService.messagesStream().listen((data) {
      final messages = data.map((row) => ChatMessage(
        username: row['username'],
        message: row['message'],
        timestamp: DateTime.parse(row['timestamp']),
        isWinner: row['is_winner'] ?? false,
      )).toList();
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    });
  }

  void _setUsername() {
    if (_usernameController.text.trim().isNotEmpty) {
      setState(() {
        _currentUsername = _usernameController.text.trim();
        _isUsernameSet = true;
      });
    }
  }

  bool _isMirrorTime(String text) {
    return _mirrorTimes.contains(text.trim());
  }

  DateTime _getCurrentTime() {
    return _timeOffset;
  }

  bool _isTimeClose(String mirrorTime) {
    final now = _getCurrentTime();
    final parts = mirrorTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final mirrorDateTime = DateTime(now.year, now.month, now.day, hour, minute);
    final difference = now.difference(mirrorDateTime).abs();
    
    return difference.inMinutes <= 1;
  }

  void _adjustTime(int minutes) {
    setState(() {
      _timeOffset = _timeOffset.add(Duration(minutes: minutes));
    });
  }

  void _resetTime() {
    setState(() {
      _timeOffset = DateTime.now();
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = _getCurrentTime();
    bool isWinner = false;
    String mirrorTime = '';

    if (_isMirrorTime(text) && _isTimeClose(text)) {
      mirrorTime = text;
      isWinner = await SupabaseService.checkAndSetWinner(text, _currentUsername);
      if (isWinner) {
        setState(() {
          _wonTimes.add(text);
        });
      }
    }

    try {
      await SupabaseService.sendMessage(
        username: _currentUsername,
        message: text,
        timestamp: now,
        isWinner: isWinner,
        mirrorTime: mirrorTime,
      );
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUsernameSet) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mirror Time Chat'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Mirror Time Chat!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Be the first to type mirror times like 17:17, 08:08, etc. when the actual time is close!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your username',
                ),
                onSubmitted: (_) => _setUsername(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _setUsername,
                child: const Text('Join Chat'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mirror Time Chat - $_currentUsername'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showTimeControls ? Icons.schedule : Icons.access_time),
            onPressed: () {
              setState(() {
                _showTimeControls = !_showTimeControls;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                _formatTime(_getCurrentTime()),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showTimeControls)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _adjustTime(-10),
                    child: const Text('-10m'),
                  ),
                  ElevatedButton(
                    onPressed: () => _adjustTime(-1),
                    child: const Text('-1m'),
                  ),
                  ElevatedButton(
                    onPressed: _resetTime,
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () => _adjustTime(1),
                    child: const Text('+1m'),
                  ),
                  ElevatedButton(
                    onPressed: () => _adjustTime(10),
                    child: const Text('+10m'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: message.isWinner ? Colors.green.shade100 : null,
                  child: ListTile(
                    title: Text(
                      message.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: message.isWinner ? Colors.green.shade800 : null,
                      ),
                    ),
                    subtitle: Text(message.message),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatTime(message.timestamp)),
                        if (message.isWinner)
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a mirror time like 17:17...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}