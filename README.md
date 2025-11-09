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

## Sequence Diagram (Will be updated in process)
<img width="1209" height="1260" alt="image" src="https://github.com/user-attachments/assets/42c77830-a7cb-4a92-8c02-23f98e68a11f" />