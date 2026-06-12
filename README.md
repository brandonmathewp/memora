# Memora - Private AI Memory Framework

An Android app that provides a multi-level memory system for AI companionship.  
Fully local storage, user-supplied API key, no cloud dependency.

## Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Flutter + WebView)     │
│  Chat (WebView) | Settings | Memory      │
└─────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Application Services (Dart)    │
│  ChatService | MemoryService | APIClient │
└─────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│              Memory Engine               │
│  Retriever | Updater | Consolidator      │
└─────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│        Data Storage (SQLite + FTS5)      │
│  world_bible | soul | messages           │
└─────────────────────────────────────────┘
                   │
                   └──────► Minimal Server (stats/announce/feedback)
```

## Features

- **Multi-level Memory**: World Bible, SOUL (personality), long-term memory, short-term context
- **Dynamic SOUL Generation**: AI analyzes conversations and suggests personality settings
- **WebView Chat**: Rich Markdown rendering with GitHub Flavored Markdown support
- **Local-First**: All data stored locally in SQLite with FTS5 full-text search
- **Bring Your Own Key**: Connect any OpenAI-compatible API
- **Privacy**: Zero conversation data leaves the device. Server only collects anonymous usage stats.

## Build

```bash
flutter pub get
flutter build apk --debug
```

CI builds via GitHub Actions on every push (see `.github/workflows/build.yml`).

## Server

Minimal Node.js server (`server/`) for:
- `POST /v1/stats` — anonymous startup reporting (IP + version)
- `GET /v1/announcement` — fetch latest announcement
- `POST /v1/feedback` — user feedback submission

```bash
cd server && npm install && npm start
```
