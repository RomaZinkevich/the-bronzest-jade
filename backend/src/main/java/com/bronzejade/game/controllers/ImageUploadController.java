package com.bronzejade.game.controllers;

import com.bronzejade.game.service.ImageUploadService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/images")
@RequiredArgsConstructor
public class ImageUploadController {

    private final ImageUploadService imageUploadService;

    @PostMapping(value = "/uploads", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> handleImageUpload(@RequestParam("image") MultipartFile image) throws IOException {
        String uniqueFilename = imageUploadService.uploadImage(image);

        return ResponseEntity.ok(uniqueFilename);
    }

    @DeleteMapping()
    public ResponseEntity<?> deleteImage(@RequestParam("filename") String filename) throws IOException {
        imageUploadService.deleteImage(filename);
        return ResponseEntity.noContent().build();
    }
}