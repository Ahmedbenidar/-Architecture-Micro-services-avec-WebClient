package com.example.client;

import com.example.client.entities.Client;
import com.example.client.repositories.ClientRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;

@EnableDiscoveryClient
@SpringBootApplication
public class ServiceClientApplication {

    public static void main(String[] args) {
        SpringApplication.run(ServiceClientApplication.class, args);
    }

    @Bean
    CommandLineRunner initData(ClientRepository repo) {
        return args -> {
            if (repo.count() == 0) {
                repo.save(new Client(null, "Salma", 22.0f));
                repo.save(new Client(null, "Ahmed", 30.0f));
                repo.save(new Client(null, "Youssef", 41.0f));
            }
        };
    }
}
