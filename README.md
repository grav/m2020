# Mirror Time Chat

A real-time multiplayer Flutter chat app where players compete to be the first to type mirror times (17:17, 08:08, etc.) when the actual time is close.

## Features

- Real-time multiplayer chat using Supabase
- Mirror time detection and validation
- Winner tracking (first person to type the mirror time wins)
- Time adjustment controls for testing
- Cross-platform support (Web, iOS, Android)

## Setup Instructions

### 1. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Settings > API and copy your Project URL and anon public key
3. In the Supabase SQL Editor, run the schema from `supabase_schema.sql`
4. Update `lib/supabase_service.dart` with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 2. Flutter Setup

1. Make sure Flutter is installed
2. Get dependencies: `flutter pub get`
3. Run the app: `flutter run -d chrome` (for web)

## How to Play

1. Enter a username to join the chat
2. Wait for a mirror time (00:00, 01:01, 02:02, etc.)
3. Be the first to type the exact mirror time when it appears
4. Winners are highlighted in green with a star icon
5. Each mirror time can only be won once per day

## Testing

- Click the clock icon in the app bar to show time adjustment controls
- Use +/-1m and +/-10m buttons to test different times
- Reset button returns to real time

## Database Schema

- `messages`: Stores all chat messages with winner status
- `winners`: Tracks which mirror times have been claimed and by whom
