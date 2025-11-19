package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import com.bronzejade.game.domain.dtos.GuessCharacterResponse;
import com.bronzejade.game.domain.dtos.MessageDto;
import com.bronzejade.game.domain.dtos.RoomPlayerDto;
import com.bronzejade.game.domain.dtos.StartGameResponse;
import com.bronzejade.game.domain.entities.*;
import com.bronzejade.game.domain.entities.Character;
import com.bronzejade.game.repositories.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.messaging.converter.SimpleMessageConverter;
import org.springframework.messaging.converter.StringMessageConverter;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.StompFrameHandler;
import org.springframework.messaging.simp.stomp.StompHeaders;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.messaging.simp.stomp.StompSessionHandlerAdapter;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;
import org.springframework.web.socket.sockjs.client.SockJsClient;
import org.springframework.web.socket.sockjs.client.WebSocketTransport;
import java.lang.reflect.Type;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import static java.util.concurrent.TimeUnit.SECONDS;
import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class RoomWsControllerIntegrationTest {

    @LocalServerPort
    private Integer port;

    private WebSocketStompClient webSocketStompClient;
    @Autowired
    private RoomRepository roomRepository;
    @Autowired
    private CharacterSetRepository characterSetRepository;
    @Autowired
    private RoomPlayerRepository roomPlayerRepository;
    @Autowired
    private CharacterRepository characterRepository;
    @Autowired
    private GameStateRepository gameStateRepository;
    @Autowired
    private GameActionRepository gameActionRepository;

    private String getWsPath() {
        return String.format("ws://localhost:%d/ws", port);
    }

    private CharacterSet createCharacterSet() {
        Character character = new Character();
        character.setName("bob");
        character.setImageUrl("bob.png");

        Character character2 = new Character();
        character2.setName("charlie");
        character2.setImageUrl("char.png");

        CharacterSet characterSet = new CharacterSet();
        characterSet.setName("test set");
        characterSet.getCharacters().add(character);
        characterSet.getCharacters().add(character2);

        return characterSetRepository.save(characterSet);
    }

    private Room createRoom() {
        Room room = new Room();
        room.setHostId(UUID.randomUUID());
        room.setStatus(RoomStatus.WAITING);
        room.setMaxPlayers(2);
        room.setCharacterSet(createCharacterSet());
        return roomRepository.save(room);
    }

    private void createGameState(Room room) {
        GameState gameState = new GameState();
        gameState.setRoom(room);
        gameState.setTurnPhase(TurnPhase.ASKING);
        GameState savedGameState = gameStateRepository.save(gameState);

        createGameAction(savedGameState);
    }

    private void createGameAction(GameState gameState) {
        GameAction gameAction = new GameAction();
        gameAction.setGameState(gameState);
        gameAction.setQuestion("Are they young?");
        gameActionRepository.save(gameAction);
    }

    private void createRoomPlayers() {
        Room room = createRoom();
        createGameState(room);

        Character character = characterRepository.findByName("bob");

        RoomPlayer roomPlayer = new RoomPlayer();
        roomPlayer.setRoom(room);
        roomPlayer.setUserId(UUID.randomUUID());
        roomPlayer.setHost(true);
        roomPlayer.setReady(false);
        roomPlayer.setCharacterToGuess(character);

        RoomPlayer roomPlayer2 = new RoomPlayer();
        roomPlayer2.setRoom(room);
        roomPlayer2.setUserId(UUID.randomUUID());
        roomPlayer2.setHost(false);
        roomPlayer2.setReady(false);
        roomPlayer2.setCharacterToGuess(character);

        roomPlayerRepository.save(roomPlayer);
        roomPlayerRepository.save(roomPlayer2);
    }

    @BeforeEach
    void setup() {
        roomPlayerRepository.deleteAll();
        roomRepository.deleteAll();
        characterSetRepository.deleteAll();
        characterRepository.deleteAll();
        gameStateRepository.deleteAll();
        gameActionRepository.deleteAll();

        createRoomPlayers();
        this.webSocketStompClient = new WebSocketStompClient(new SockJsClient(
                List.of(new WebSocketTransport(new StandardWebSocketClient()))));
    }

    @Test
    void joinRoom() throws Exception {
        RoomPlayer player = roomPlayerRepository.findAll().get(0);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return MessageDto.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                MessageDto messageDto = (MessageDto) payload;
                blockingQueue.add(messageDto.getMessage());
            }
        });

        session.send("/app/join", "");

        String expectedPrefix = "guest-player-" + player.getUserId().toString().substring(0, 6);
        String expectedMessage = expectedPrefix + " has joined room";

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    @Test
    void toggleReady() throws Exception {
        RoomPlayer player = roomPlayerRepository.findAll().get(0);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return MessageDto.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                MessageDto messageDto = (MessageDto) payload;
                blockingQueue.add(messageDto.getMessage());
            }
        });

        session.send("/app/ready", "");

        String expectedPrefix = "guest-player-" + player.getUserId().toString().substring(0, 6);
        String expectedMessage = expectedPrefix + " is ready";

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    @Test
    void toggleNotReady() throws Exception {
        RoomPlayer player = roomPlayerRepository.findAll().get(0);
        player.setReady(true);
        roomPlayerRepository.save(player);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return MessageDto.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                MessageDto messageDto = (MessageDto) payload;
                blockingQueue.add(messageDto.getMessage());
            }
        });

        session.send("/app/ready", "");

        String expectedPrefix = "guest-player-" + player.getUserId().toString().substring(0, 6);
        String expectedMessage = expectedPrefix + " is not ready";

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    @Test
    void start() throws Exception {
        final RoomPlayerDto[] turnPlayer = new RoomPlayerDto[1];
        RoomPlayer host = roomPlayerRepository.findByHost(true);
        RoomPlayer player = roomPlayerRepository.findByHost(false);
        host.setReady(true);
        player.setReady(true);
        roomPlayerRepository.save(host);
        roomPlayerRepository.save(player);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setObjectMapper(mapper);

        webSocketStompClient.setMessageConverter(converter);

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(host.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(host.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + host.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return StartGameResponse.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                StartGameResponse response = (StartGameResponse) payload;
                blockingQueue.add(response.getMessage());
                turnPlayer[0] = response.getTurnPlayer();
            }
        });

        session.send("/app/start", "");

        String expectedMessage ="The game has been started";

        await()
                .atMost(5, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
        assertNotNull(turnPlayer[0]);
    }

    @Test
    void askQuestion() throws Exception {
        Room room = roomRepository.findAll().get(0);
        room.setStatus(RoomStatus.IN_PROGRESS);
        roomRepository.save(room);

        RoomPlayer player = roomPlayerRepository.findAll().get(0);

        GameState gameState = gameStateRepository.findAll().get(0);
        gameState.setTurnPlayer(player);
        gameStateRepository.save(gameState);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return MessageDto.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                MessageDto messageDto = (MessageDto) payload;
                blockingQueue.add(messageDto.getMessage());
            }
        });

        String question = "Are they young?";
        session.send("/app/question", question);

        String expectedPrefix = "guest-player-" + player.getUserId().toString().substring(0, 6);
        String expectedMessage = expectedPrefix + ": " + question;

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    @Test
    void answerQuestion() throws Exception {
        Room room = roomRepository.findAll().get(0);
        room.setStatus(RoomStatus.IN_PROGRESS);
        roomRepository.save(room);

        RoomPlayer player = roomPlayerRepository.findAll().get(0);
        RoomPlayer player2 = roomPlayerRepository.findAll().get(1);

        GameState gameState = gameStateRepository.findAll().get(0);
        gameState.setTurnPlayer(player2);
        gameState.setTurnPhase(TurnPhase.ANSWERING);
        gameStateRepository.save(gameState);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return MessageDto.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                MessageDto messageDto = (MessageDto) payload;
                blockingQueue.add(messageDto.getMessage());
            }
        });

        String answer = "No";
        session.send("/app/answer", answer);

        String expectedPrefix = "guest-player-" + player.getUserId().toString().substring(0, 6);
        String expectedMessage = expectedPrefix + ": " + answer;

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    @Test
    void guessCorrectCharacter() throws Exception {
        final GuessCharacterResponse[] response = new GuessCharacterResponse[1];
        Character character = characterRepository.findByName("bob");

        Room room = roomRepository.findAll().get(0);
        room.setStatus(RoomStatus.IN_PROGRESS);
        roomRepository.save(room);

        RoomPlayer player = roomPlayerRepository.findAll().get(0);
        GameState gameState = gameStateRepository.findAll().get(0);
        gameState.setTurnPlayer(player);
        gameState.setTurnPhase(TurnPhase.ASKING);
        gameStateRepository.save(gameState);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return GuessCharacterResponse.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                GuessCharacterResponse guessResponse = (GuessCharacterResponse) payload;
                blockingQueue.add(guessResponse.getMessage());
                response[0] = guessResponse;
            }
        });

        String guess = String.valueOf(character.getId());
        session.send("/app/guess", guess);

        String expectedMessage = "Correct! You've won the game!";
        GuessCharacterResponse expectedResponse = getGuessCharacterResponse(expectedMessage, character, character, player);

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
        assertEquals(response[0], expectedResponse);
    }

    @Test
    void guessWrongCharacter() throws Exception {
        final GuessCharacterResponse[] response = new GuessCharacterResponse[1];
        Character correctCharacter = characterRepository.findByName("bob");
        Character wrongCharacter = characterRepository.findByName("charlie");

        Room room = roomRepository.findAll().get(0);
        room.setStatus(RoomStatus.IN_PROGRESS);
        roomRepository.save(room);

        RoomPlayer player = roomPlayerRepository.findAll().get(0);
        GameState gameState = gameStateRepository.findAll().get(0);
        gameState.setTurnPlayer(player);
        gameState.setTurnPhase(TurnPhase.ASKING);
        gameStateRepository.save(gameState);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new MappingJackson2MessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/topic/room." + player.getRoom().getId(), new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return GuessCharacterResponse.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                GuessCharacterResponse guessResponse = (GuessCharacterResponse) payload;
                blockingQueue.add(guessResponse.getMessage());
                response[0] = guessResponse;
            }
        });

        String guess = String.valueOf(wrongCharacter.getId());
        session.send("/app/guess", guess);

        String expectedMessage = "Wrong guess! Turn passes to opponent.";
        GuessCharacterResponse expectedResponse = getGuessCharacterResponse(expectedMessage, correctCharacter, wrongCharacter, player);

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
        assertEquals(response[0], expectedResponse);
    }

    @Test
    void handleErrors() throws Exception {
        Room room = roomRepository.findAll().get(0);
        room.setStatus(RoomStatus.IN_PROGRESS);
        roomRepository.save(room);

        RoomPlayer player = roomPlayerRepository.findAll().get(0);

        GameState gameState = gameStateRepository.findAll().get(0);
        gameState.setTurnPlayer(player);
        gameState.setTurnPhase(TurnPhase.ANSWERING);
        gameStateRepository.save(gameState);

        BlockingQueue<String> blockingQueue = new ArrayBlockingQueue<>(1);

        webSocketStompClient.setMessageConverter(new StringMessageConverter());

        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("roomId", String.valueOf(player.getRoom().getId()));
        connectHeaders.add("playerId", String.valueOf(player.getUserId()));

        StompSession session = webSocketStompClient
                .connectAsync(
                        getWsPath(),
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new StompSessionHandlerAdapter() {}
                )
                .get(1, SECONDS);

        session.subscribe("/user/queue/errors", new StompFrameHandler() {

            @Override
            public Type getPayloadType(StompHeaders headers) {
                return String.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                System.out.println("Message: "+ payload);
                blockingQueue.add((String) payload);
            }
        });

        String answer = "No";
        session.send("/app/answer", answer);

        String expectedMessage = "Not user's turn to answer";

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    private static GuessCharacterResponse getGuessCharacterResponse(String expectedMessage, Character correctCharacter, Character guessedCharacter, RoomPlayer player) {
        GuessCharacterResponse expectedResponse = new GuessCharacterResponse();
        expectedResponse.setMessage(expectedMessage);
        expectedResponse.setCorrect(correctCharacter == guessedCharacter);
        expectedResponse.setGuessedCharacterId(guessedCharacter.getId());
        expectedResponse.setGuessedCharacterName(guessedCharacter.getName());
        expectedResponse.setActualCharacterId(correctCharacter.getId());
        expectedResponse.setActualCharacterName(correctCharacter.getName());
        expectedResponse.setGameEnded(correctCharacter == guessedCharacter);
        expectedResponse.setWinnerId(correctCharacter == guessedCharacter ? player.getUserId() : null);
        return expectedResponse;
    }
}
