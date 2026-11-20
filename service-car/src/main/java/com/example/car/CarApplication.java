package com.example.car;

import com.example.car.entities.Car;
import com.example.car.repositories.CarRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;

@EnableDiscoveryClient
@SpringBootApplication
public class CarApplication {

    public static void main(String[] args) {
        SpringApplication.run(CarApplication.class, args);
    }

    @Bean
    CommandLineRunner initData(CarRepository repo) {
        return args -> {
            if (repo.count() == 0) {
                repo.save(new Car(null, "Toyota", "Yaris", 1L));
                repo.save(new Car(null, "Renault", "Clio", 2L));
                repo.save(new Car(null, "Dacia", "Duster", 3L));
            }
        };
    }
}
