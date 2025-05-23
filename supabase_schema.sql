-- Mirror Time Chat Database Schema
-- Run this in your Supabase SQL editor

-- Messages table
CREATE TABLE messages (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_winner BOOLEAN DEFAULT FALSE,
  mirror_time TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Winners table (tracks which mirror times have been won)
CREATE TABLE winners (
  id BIGSERIAL PRIMARY KEY,
  mirror_time TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE winners ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read messages and winners
CREATE POLICY "Allow read access to messages" ON messages FOR SELECT USING (true);
CREATE POLICY "Allow read access to winners" ON winners FOR SELECT USING (true);

-- Allow anyone to insert messages and winners
CREATE POLICY "Allow insert access to messages" ON messages FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow insert access to winners" ON winners FOR INSERT WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX idx_messages_timestamp ON messages(timestamp);
CREATE INDEX idx_winners_mirror_time ON winners(mirror_time);

-- Enable realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;