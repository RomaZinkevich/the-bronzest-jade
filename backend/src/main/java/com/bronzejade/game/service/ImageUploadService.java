package com.bronzejade.game.service;

import org.apache.coyote.BadRequestException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.Objects;
import java.util.UUID;

@Service
public class ImageUploadService {

    @Value("${FILE_STORAGE_PATH}")
    private String BASE_PATH;

    public String uploadImage(MultipartFile image) throws IOException {
        File directory = new File(BASE_PATH);
        if (!directory.exists()) {
            boolean created = directory.mkdirs();
            if (!created) {
                throw new RuntimeException("Failed to create directory.");
            }
        }
        String filename = Objects.requireNonNull(image.getOriginalFilename());
        if (!filename.endsWith(".jpeg") && !filename.endsWith(".png") && !filename.endsWith(".jpg") && !filename.endsWith(".heic")) {
            throw new BadRequestException("Unsupported image type");
        }
        String uniqueFilename = UUID.randomUUID() + filename.substring(filename.lastIndexOf("."));
        File destination = new File(directory, uniqueFilename);
        image.transferTo(destination);

        return uniqueFilename;
    }

    public void deleteImage(String filename) throws IOException {
        if (filename == null || filename.isBlank()) {
            throw new BadRequestException("Filename cannot be empty");
        }

        if (filename.contains("..") || filename.contains("/") || filename.contains("\\")) {
            throw new BadRequestException("Invalid filename");
        }

        File directory = new File(BASE_PATH);
        File targetFile = new File(directory, filename);

        if (!targetFile.exists()) {
            throw new BadRequestException("File not found: " + filename);
        }

        boolean deleted = targetFile.delete();
        if (!deleted) {
            throw new IOException("Failed to delete file: " + filename);
        }
    }
}
