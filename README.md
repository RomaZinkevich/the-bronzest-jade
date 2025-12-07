# Guess who?

## Description

#### "Guess Who?" is a full-stack, cross-platform game implementation that delivers both local and online multiplayer experiences of the classic deductive guessing game.

![c856c1d6-4c42-49ab-b16a-b9a21d704e23](https://github.com/user-attachments/assets/9485c3dc-e743-414a-874a-303cc9193e62)
![3d54a20d-297f-481d-8813-5d250618a498](https://github.com/user-attachments/assets/77f03a03-844f-4a62-8a5d-4ae41b6fe01c)


## Team Members

#### Roman Zinkevich - Backend Developer
#### Vasu Swarup Bhatnagar - Backend Developer
#### Nguyen Cong Dang - Mobile App Developer
#### Prabesh Sharma - Mobile App Developer

## Setup Instructions
### Backend Setup

#### Requirements

Git installed</br>
Docker installed</br>

#### Run

```bash
git clone git@github.com:RomaZinkevich/the-bronzest-jade.git
cd the-bronzest-jade
```
Create .env file and populate it with required variables: </br>
POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, DB_PORT, JWT_SECRET, JWT_EXPIRATION </br>
FLYWAY_URL=jdbc:postgresql://postgres:${DB_PORT}/${POSTGRES_DB} </br>
FLYWAY_USER=${POSTGRES_USER} </br>
FLYWAY_PASSWORD=${POSTGRES_PASSWORD} </br>

Continue in bash:
```bash
cd backend
./dev.sh
```

### Frontend Setup

#### Requirements

Flutter SDK installed
Backend server running

#### Run

```bash
flutter pub get
flutter run
```

## Technology Stack
#### Spring Boot, PostgreSQL, Flutter, Docker

## Links
#### [Base backend URL](https://guesswho.190304.xyz)
#### [Project Board](https://id.atlassian.com/invite/p/jira-software?id=_z3N2uJfQjmVa_xaLobJKA)
#### [Wiki Documentation](https://github.com/RomaZinkevich/the-bronzest-jade/wiki/Guess-Who%3F-Wiki)

## Backend Endpoints

### REST API

#### Public Endpoints (No Authentication Required):

#### 1. Create profile

**POST** `/api/auth/register`

**Request:**

```java
public class RegisterRequest{
    String username;
    String email;
    String password;
}
```

**Response:**

```java
public class AuthResponse {
    String token;
    UUID userId;
    String username;
}
```

#### 2. Log in

**POST** `/api/auth/login`

**Request:**

```java
public class LoginRequest{
    String username;
    String password;
}
```

**Response:**

```java
public class AuthResponse {
    String token;
    UUID userId;
    String username;
}
```

#### 3. Log in as a guest

**POST** `/api/auth/guest`

**Request:** None

**Response:**

```java
public class AuthResponse {
    String token;
    UUID userId;
    String username;
}
```


#### Private Endpoints (Authentication Required):

#### 1. Create Room

**POST** `/api/rooms`

**Request:**

```java
public class CreateRoomRequest {
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

**Request:** None

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
    Set<CharacterDto> characters;
}

public class CharacterDto {
    UUID id;
    String name;
    String imageUrl;
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
    Set<CharacterDto> characters;
}

public class CharacterDto {
    UUID id;
    String name;
    String imageUrl;
}
```

#### 6. Create Character Set

**POST** `/api/character-sets`

**Request:** 

```java
public class CreateCharacterSetRequest {
    String name;
    Boolean isPublic;
    List<CreateCharacterRequest> characters;
}

public class CreateCharacterRequest {
    String name;
    String imageUrl;
}
```

**Response:**

```java
public class CharacterSetDto {
    UUID id;
    String name;
    String createdBy;
    Boolean isPublic;
    LocalDateTime createdAt;
    Set<CharacterDto> characters;
}

public class CharacterDto {
    UUID id;
    String name;
    String imageUrl;
}
```

#### 7. Upload image

**POST** `/api/images/uploads`

**Request:** 
```java
    MultipartFile image (accepted file extensions: .jpeg, .jpg, .png, .heic)
```

**Response:**

```java
    String uniqueFilename;
```

### WebSocket

**Connection Requirements:**

**Clients must provide:**

- Header:

  - UUID roomId

- Query Parameter:
  
  - token - a valid JWT used to authenticate the WebSocket connection

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
