package com.mangetout;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.mongodb.config.EnableMongoAuditing;

// @EnableMongoAuditing activates @CreatedDate and @LastModifiedDate on documents
@SpringBootApplication
@EnableMongoAuditing
public class MangetoutApplication {

    public static void main(String[] args) {
        SpringApplication.run(MangetoutApplication.class, args);
    }
}
