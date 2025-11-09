# Guess who?

## Backend Endpoints

### REST API

#### 1. Create Room

**POST** `/api/rooms`

**Request:**

```java
public class CreateRoomRequest {
    UUID hostId;
    UUID characterSetId;
}
```

**Response:**

```java
public class RoomDto {
    UUID id;
    String roomCode;
    UUID hostId;
    RoomStatus status;
    int maxPlayers;
    CharacterSetDto characterSet;
    LocalDateTime createdAt;
    LocalDateTime startedAt;
    LocalDateTime finishedAt;
}
```

#### 2. Join Room

**POST** `/api/rooms/join/{roomCode}`

**Request:**

```java
UUID playerId;
```

**Response:**

```java
public class RoomDto {
    UUID id;
    String roomCode;
    UUID hostId;
    RoomStatus status;
    int maxPlayers;
    CharacterSetDto characterSet;
    LocalDateTime createdAt;
    LocalDateTime startedAt;
    LocalDateTime finishedAt;
}
```

#### 3. Select Character

**POST** `/api/rooms/{id}/select-character`

**Request:**

```java
public class SelectCharacterRequest {
    UUID playerId;
    UUID characterId;
}
```

**Response:**

```java
public class RoomPlayerDto {
    UUID id;
    UUID userId;
    boolean isHost;
    boolean isReady;
    CharacterDto characterToGuess;
    LocalDateTime joinedAt;
}
```

#### 4. Get All Character Sets

**GET** `/api/character-sets`

**Request:** None

**Response:**

```java
Set<CharacterSetDto>

public class CharacterSetDto {
    UUID id;
    String name;
    String createdBy;
    Boolean isPublic;
    LocalDateTime createdAt;
    Set<CharacterDto> characters = new HashSet<>();
}
```

#### 5. Get Character Set

**GET** `/api/character-sets/{id}`

**Request:** None

**Response:**

```java
public class CharacterSetDto {
    UUID id;
    String name;
    String createdBy;
    Boolean isPublic;
    LocalDateTime createdAt;
    Set<CharacterDto> characters = new HashSet<>();
}
```

### WebSocket

**Connection Requirements:**

Headers must include:

- `UUID playerId`
- `UUID roomId`

**Subscribe to:**

- `/user/queue/errors` - To receive error messages
- `/topic/room.{roomId}` - To receive room updates

**Send to:**

#### `/join`

**Response:**

```java
public class MessageDto {
    String message;
}
```

#### `/ready`

**Response:**

```java
public class MessageDto {
    String message;
}
```

#### `/start`

**Response:**

```java
public class StartGameResponse {
    String message;
    RoomPlayerDto turnPlayer;
}

public class RoomPlayerDto {
    UUID id;
    UUID userId;
    boolean isHost;
    boolean isReady;
    CharacterDto characterToGuess;
    LocalDateTime joinedAt;
}
```

#### `/question`

**Request:**

```java
String message
```

**Response:**

```java
public class MessageDto {
    String message;
}
```

#### `/answer`

**Request:**

```java
String message
```

**Response:**

```java
public class MessageDto {
    String message;
}
```

#### `/guess`

**Request:**

```java
String characterId // UUID format
```

**Response:**

```java
public class GuessCharacterResponse {
    boolean correct;
    UUID guessedCharacterId;
    String guessedCharacterName;
    UUID actualCharacterId;
    String actualCharacterName;
    boolean gameEnded;
    UUID winnerId;
    String message;
}
```

## FRONTEND

### Overview

The frontend is built with Flutter and provides both local gameplay and online multiplayer experiences. It connects to the backend via REST API and WebSocket for real-time communication.

### Key Responsibilities

Displaying game UI and character boards
Managing game state (turns, questions, answers, guesses)
Handling player input (asking, answering, making guesses)
Connecting to backend for:
Room creation & joining
Character selection
Real-time game events (questions, answers, turn changes, game end)

### Architecture

Layer Purpose
Screens Different views (menu, local game, online lobby, online game)
Widgets Reusable UI components (buttons, cards, game board, dialogs)
Services API & WebSocket communication
Models Data structures shared with backend
State Manager Controls game logic & turn flow

### Core Frontend Workflow

#### Online Game Flow

Player selects Online Game
Create room or join room using code
Select character from character set
Wait until both players are ready
Game starts
Players alternate:
Sending questions
Sending answers
Making guesses
Backend validates guess → returns winner result
Game ends and UI displays result

#### Local Game Flow

Player selects Local Game
Each player selects character
Players pass device between turns
Ask → Answer → Guess (similar logic but offline)

### Communication

#### REST Usage Summary

Purpose Endpoint
Create room POST /api/rooms
Join room POST /api/rooms/join/{roomCode}
Select character POST /api/rooms/{id}/select-character
Get character sets GET /api/character-sets

#### WebSocket Usage Summary

Action Channel
Subscribe room events /topic/room.{roomId}
Subscribe errors /user/queue/errors
Join room /join
Set ready /ready
Start game /start
Send question /question
Send answer /answer
Send guess /guess

### Frontend Setup

#### Requirements

Flutter SDK installed
Backend server running

#### Run

(bash)
flutter pub get
flutter run

#### UI Elements

Retro-style buttons
Custom app bar
Character grid board
Question/Answer message log
Dialog for guesses
Player turn display

#### State Management

Custom state logic in game_state_manager.dart:

Tracks whose turn it is
Manages question and answer flow
Sends/receives WebSocket events
Updates UI in real-time
