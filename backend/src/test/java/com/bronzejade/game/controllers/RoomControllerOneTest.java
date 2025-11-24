package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.dtos.CharacterSetDto;
import com.bronzejade.game.domain.dtos.CreateRoomRequest;
import com.bronzejade.game.domain.dtos.JoinRoomRequest;
import com.bronzejade.game.domain.dtos.RoomDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.service.RoomService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class RoomControllerOneTest {

    private MockMvc mockMvc;

    @Mock
    private RoomService roomService;

    @Mock
    private RoomMapper roomMapper;

    @InjectMocks
    private RoomController roomController;

    private ObjectMapper objectMapper;
    private UUID testUserId;
    private UUID testCharacterSetId;
    private UUID testRoomId;
    private UUID testGuestSessionId;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(roomController).build();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();

        testUserId = UUID.randomUUID();
        testCharacterSetId = UUID.randomUUID();
        testRoomId = UUID.randomUUID();
        testGuestSessionId = UUID.randomUUID();
    }

    // ===== Tests for createRoom API (Authenticated User) =====

    @Test
    void createRoom_ShouldReturnCreatedRoom_WhenAuthenticatedUserCreates() throws Exception {
        CreateRoomRequest request = new CreateRoomRequest();
        request.setUserId(testUserId);
        request.setCharacterSetId(testCharacterSetId);

        CharacterSet characterSet = CharacterSet.builder()
                .id(testCharacterSetId)
                .name("Test Character Set")
                .build();

        Room room = Room.builder()
                .id(testRoomId)
                .roomCode("ABC123")
                .hostId(testUserId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSet)
                .createdAt(LocalDateTime.now())
                .build();

        CharacterSetDto characterSetDto = CharacterSetDto.builder()
                .id(testCharacterSetId)
                .name("Test Character Set")
                .build();

        RoomDto roomDto = RoomDto.builder()
                .id(testRoomId)
                .roomCode("ABC123")
                .hostId(testUserId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSetDto)
                .createdAt(LocalDateTime.now())
                .build();

        when(roomService.createRoom(any(CreateRoomRequest.class))).thenReturn(room);
        when(roomMapper.toDto(any(Room.class))).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value("ABC123"))
                .andExpect(jsonPath("$.hostId").value(testUserId.toString()))
                .andExpect(jsonPath("$.status").value("WAITING"))
                .andExpect(jsonPath("$.maxPlayers").value(2))
                .andExpect(jsonPath("$.characterSet.id").value(testCharacterSetId.toString()));

        verify(roomService, times(1)).createRoom(any(CreateRoomRequest.class));
        verify(roomMapper, times(1)).toDto(any(Room.class));
    }

    @Test
    void createRoom_ShouldReturnCreatedRoom_WhenGuestUserCreates() throws Exception {
        CreateRoomRequest request = new CreateRoomRequest();
        request.setGuestSessionId(testGuestSessionId);
        request.setGuestDisplayName("Guest Player");
        request.setCharacterSetId(testCharacterSetId);

        CharacterSet characterSet = CharacterSet.builder()
                .id(testCharacterSetId)
                .name("Test Character Set")
                .build();

        Room room = Room.builder()
                .id(testRoomId)
                .roomCode("XYZ789")
                .hostId(testGuestSessionId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSet)
                .createdAt(LocalDateTime.now())
                .build();

        CharacterSetDto characterSetDto = CharacterSetDto.builder()
                .id(testCharacterSetId)
                .name("Test Character Set")
                .build();

        RoomDto roomDto = RoomDto.builder()
                .id(testRoomId)
                .roomCode("XYZ789")
                .hostId(testGuestSessionId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSetDto)
                .createdAt(LocalDateTime.now())
                .build();

        when(roomService.createRoom(any(CreateRoomRequest.class))).thenReturn(room);
        when(roomMapper.toDto(any(Room.class))).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value("XYZ789"))
                .andExpect(jsonPath("$.hostId").value(testGuestSessionId.toString()));

        verify(roomService, times(1)).createRoom(any(CreateRoomRequest.class));
        verify(roomMapper, times(1)).toDto(any(Room.class));
    }

    // ===== Tests for joinRoom API (Authenticated User) =====

    @Test
    void joinRoom_ShouldReturnJoinedRoom_WhenAuthenticatedUserJoins() throws Exception {
        String roomCode = "ROOM123";
        UUID playerId = UUID.randomUUID();

        JoinRoomRequest joinRoomRequest = new JoinRoomRequest();
        joinRoomRequest.setUserId(playerId);

        CharacterSet characterSet = CharacterSet.builder()
                .id(UUID.randomUUID())
                .name("Test Character Set")
                .build();

        Room joinedRoom = Room.builder()
                .id(testRoomId)
                .roomCode(roomCode)
                .hostId(testUserId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSet)
                .createdAt(LocalDateTime.now())
                .build();

        CharacterSetDto characterSetDto = CharacterSetDto.builder()
                .id(characterSet.getId())
                .name("Test Character Set")
                .build();

        RoomDto roomDto = RoomDto.builder()
                .id(testRoomId)
                .roomCode(roomCode)
                .hostId(testUserId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSetDto)
                .build();

        when(roomService.joinRoom(eq(roomCode), eq(playerId), eq(null), eq(null))).thenReturn(joinedRoom);
        when(roomMapper.toDto(joinedRoom)).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms/join/{roomCode}", roomCode)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinRoomRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value(roomCode))
                .andExpect(jsonPath("$.status").value("WAITING"))
                .andExpect(jsonPath("$.maxPlayers").value(2));

        verify(roomService, times(1)).joinRoom(eq(roomCode), eq(playerId), eq(null), eq(null));
        verify(roomMapper, times(1)).toDto(joinedRoom);
    }

    @Test
    void joinRoom_ShouldReturnJoinedRoom_WhenGuestUserJoins() throws Exception {
        String roomCode = "GUEST123";
        UUID guestSessionId = UUID.randomUUID();
        String guestDisplayName = "Guest Player";

        JoinRoomRequest joinRoomRequest = new JoinRoomRequest();
        joinRoomRequest.setGuestSessionId(guestSessionId);
        joinRoomRequest.setGuestDisplayName(guestDisplayName);

        Room joinedRoom = Room.builder()
                .id(testRoomId)
                .roomCode(roomCode)
                .hostId(testUserId)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .build();

        RoomDto roomDto = RoomDto.builder()
                .id(testRoomId)
                .roomCode(roomCode)
                .build();

        when(roomService.joinRoom(eq(roomCode), eq(null), eq(guestSessionId), eq(guestDisplayName)))
                .thenReturn(joinedRoom);
        when(roomMapper.toDto(joinedRoom)).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms/join/{roomCode}", roomCode)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinRoomRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value(roomCode));

        verify(roomService, times(1)).joinRoom(eq(roomCode), eq(null), eq(guestSessionId), eq(guestDisplayName));
        verify(roomMapper, times(1)).toDto(joinedRoom);
    }
}