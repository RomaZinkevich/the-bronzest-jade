package com.bronzejade.game.controllers;

import com.bronzejade.game.authFilter.ApiUserDetails;
import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.dtos.CharacterSetDto;
import com.bronzejade.game.domain.dtos.CreateRoomRequest;
import com.bronzejade.game.domain.dtos.RoomDto;
import com.bronzejade.game.domain.dtos.UserDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.service.AuthService;
import com.bronzejade.game.service.RoomService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
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

    @Mock
    private AuthService authService;

    @Mock
    private Authentication authentication;

    @Mock
    private ApiUserDetails userDetails;

    @InjectMocks
    private RoomController roomController;

    private ObjectMapper objectMapper;
    private UUID testUserId;
    private UUID testCharacterSetId;
    private UUID testRoomId;
    private User testHostUser;
    private UserDto testHostUserDto;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(roomController).build();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();

        testUserId = UUID.randomUUID();
        testCharacterSetId = UUID.randomUUID();
        testRoomId = UUID.randomUUID();

        // Create test host user and DTO
        testHostUser = User.builder()
                .id(testUserId)
                .username("testuser")
                .email("test@example.com")
                .createdAt(LocalDateTime.now())
                .build();

        testHostUserDto = UserDto.builder()
                .id(testUserId)
                .username("testuser")
                .email("test@example.com")
                .createdAt(testHostUser.getCreatedAt())
                .build();

        // Mock authentication chain
        when(authentication.getPrincipal()).thenReturn(userDetails);
        when(authService.getUserFromPrincipal(userDetails)).thenReturn(testHostUserDto);
    }

    @Test
    void createRoom_ShouldReturnCreatedRoom() throws Exception {
        CreateRoomRequest request = new CreateRoomRequest();
        request.setCharacterSetId(testCharacterSetId);

        CharacterSet characterSet = CharacterSet.builder()
                .id(testCharacterSetId)
                .name("Test Character Set")
                .build();

        Room room = Room.builder()
                .id(testRoomId)
                .roomCode("ABC123")
                .host(testHostUser)
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
                .host(testHostUserDto)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSetDto)
                .createdAt(LocalDateTime.now())
                .build();

        when(roomService.createRoom(any(CreateRoomRequest.class), eq(testHostUserDto.getId()))).thenReturn(room);
        when(roomMapper.toDto(any(Room.class))).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(authentication))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value("ABC123"))
                .andExpect(jsonPath("$.host.id").value(testUserId.toString()))
                .andExpect(jsonPath("$.host.username").value("testuser"))
                .andExpect(jsonPath("$.host.email").value("test@example.com"))
                .andExpect(jsonPath("$.status").value("WAITING"))
                .andExpect(jsonPath("$.maxPlayers").value(2))
                .andExpect(jsonPath("$.characterSet.id").value(testCharacterSetId.toString()));

        verify(roomService, times(1)).createRoom(any(CreateRoomRequest.class), eq(testHostUserDto.getId()));
        verify(roomMapper, times(1)).toDto(any(Room.class));
    }

    @Test
    void joinRoom_ShouldReturnJoinedRoom() throws Exception {
        String roomCode = "ROOM123";

        CharacterSet characterSet = CharacterSet.builder()
                .id(UUID.randomUUID())
                .name("Test Character Set")
                .build();

        Room joinedRoom = Room.builder()
                .id(testRoomId)
                .roomCode(roomCode)
                .host(testHostUser)
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
                .host(testHostUserDto)
                .status(RoomStatus.WAITING)
                .maxPlayers(2)
                .characterSet(characterSetDto)
                .build();

        when(roomService.joinRoom(eq(roomCode), eq(testHostUserDto.getId()))).thenReturn(joinedRoom);
        when(roomMapper.toDto(joinedRoom)).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms/join/{roomCode}", roomCode)
                        .contentType(MediaType.APPLICATION_JSON)
                        .principal(authentication))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(testRoomId.toString()))
                .andExpect(jsonPath("$.roomCode").value(roomCode))
                .andExpect(jsonPath("$.host.id").value(testUserId.toString()))
                .andExpect(jsonPath("$.host.username").value("testuser"))
                .andExpect(jsonPath("$.status").value("WAITING"))
                .andExpect(jsonPath("$.maxPlayers").value(2));

        verify(roomService, times(1)).joinRoom(eq(roomCode), eq(testHostUserDto.getId()));
        verify(roomMapper, times(1)).toDto(joinedRoom);
    }
}