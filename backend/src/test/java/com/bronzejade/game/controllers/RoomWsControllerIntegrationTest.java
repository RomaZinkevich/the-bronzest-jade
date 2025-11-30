package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import com.bronzejade.game.domain.dtos.MessageDto;
import com.bronzejade.game.domain.entities.*;
import com.bronzejade.game.domain.entities.Character;
import com.bronzejade.game.jwtSetup.JwtUtil;
import com.bronzejade.game.repositories.*;
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
import org.springframework.test.context.TestPropertySource;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;
import org.springframework.web.socket.sockjs.client.SockJsClient;
import org.springframework.web.socket.sockjs.client.WebSocketTransport;
import java.lang.reflect.Type;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import static java.util.concurrent.TimeUnit.SECONDS;
import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "jwt.secret=testSecretKeyForTestingPurposesOnly12345",
        "jwt.expiration=3600000"
})
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

    @Autowired
    private UserRepository userRepository; // Add this
    @Autowired
    private JwtUtil jwtUtil;

    private String getWsPath() {
        RoomPlayer player = roomPlayerRepository.findAll().get(0);
        String token = jwtUtil.generateToken(player.getUser().getId());
        String encodedToken = URLEncoder.encode(token, StandardCharsets.UTF_8);
        return String.format("ws://localhost:%d/ws", port) + "?token=" + encodedToken;
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

    private User createUser() {
        User user = User.builder()
                .username("testuser_" + UUID.randomUUID().toString().substring(0, 8))
                .email(UUID.randomUUID() + "@test.com")
                .password("password")
                .build();
        return userRepository.save(user);
    }

    private Room createRoom(User host) {
        Room room = new Room();
        room.setHost(host); // Use User entity instead of hostId
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
        User hostUser = createUser();
        User playerUser = createUser();

        Room room = createRoom(hostUser);
        createGameState(room);

        Character character = characterRepository.findByName("bob");

        RoomPlayer roomPlayer = RoomPlayer.builder()
                .room(room)
                .user(hostUser) // Use User entity instead of userId
                .host(true)
                .ready(false)
                .characterToGuess(character)
                .build();

        RoomPlayer roomPlayer2 = RoomPlayer.builder()
                .room(room)
                .user(playerUser) // Use User entity instead of userId
                .host(false)
                .ready(false)
                .characterToGuess(character)
                .build();

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
        userRepository.deleteAll(); // Add this

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
        connectHeaders.add("userId", String.valueOf(player.getUser().getId())); // Changed from playerId to userId


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

        // Updated expected message format
        String expectedMessage = player.getUser().getUsername() + " has joined room";

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
        connectHeaders.add("userId", String.valueOf(player.getUser().getId())); // Changed from playerId to userId

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

        // Updated expected message format
        String expectedMessage = player.getUser().getUsername() + " is ready";

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
        connectHeaders.add("userId", String.valueOf(player.getUser().getId())); // Changed from playerId to userId

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

        // Updated expected message format
        String expectedMessage = player.getUser().getUsername() + " is not ready";

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }

    // Update other test methods similarly...

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
        connectHeaders.add("userId", String.valueOf(player.getUser().getId())); // Changed from playerId to userId

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

        // Updated expected message format
        String expectedMessage = player.getUser().getUsername() + ": " + question;

        await()
                .atMost(1, SECONDS)
                .untilAsserted(() -> assertEquals(expectedMessage, blockingQueue.poll()));
    }
}
