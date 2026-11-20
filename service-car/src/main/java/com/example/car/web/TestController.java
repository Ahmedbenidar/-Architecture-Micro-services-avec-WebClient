package com.example.car.web;

import com.example.car.entities.Client;
import com.example.car.services.ClientApi;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * Endpoint de validation isole (etape 3.6 du lab) : prouve que le WebClient
 * resout bien SERVICE-CLIENT via Eureka, independamment de la table car.
 */
@RestController
@RequestMapping("/api/test")
public class TestController {

    private final ClientApi clientApi;

    public TestController(ClientApi clientApi) {
        this.clientApi = clientApi;
    }

    @GetMapping("/client/{id}")
    public Client testClient(@PathVariable Long id) {
        return clientApi.findClientById(id);
    }

    @GetMapping("/client/{id}/reactive")
    public Mono<Client> testClientReactive(@PathVariable Long id) {
        return clientApi.findClientByIdReactive(id);
    }
}
