package com.bronzejade.game;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(
        properties = {
                "jwt.secret=testsecret1234567890testsecret1234567890",
                "jwt.expiration=86400000",
                "spring.datasource.url=jdbc:h2:mem:testdb",
                "spring.jpa.hibernate.ddl-auto=create-drop"
        }
)
class BackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
