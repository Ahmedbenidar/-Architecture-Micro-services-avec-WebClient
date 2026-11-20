package com.example.car.services;

import com.example.car.entities.Client;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

@Service
public class ClientApi {

    private static final Logger log = LoggerFactory.getLogger(ClientApi.class);

    private final WebClient.Builder builder;

    public ClientApi(WebClient.Builder builder) {
        this.builder = builder;
    }

    /**
     * Appel non bloquant : renvoie un Mono<Client> vide si SERVICE-CLIENT
     * est indisponible ou renvoie une erreur (degradation gracieuse).
     */
    public Mono<Client> findClientByIdReactive(Long id) {
        return builder.build()
                .get()
                .uri("http://SERVICE-CLIENT/api/clients/" + id)
                .retrieve()
                .bodyToMono(Client.class)
                // client inexistant : le service-client renvoie un corps vide
                .switchIfEmpty(Mono.error(new IllegalStateException("Client " + id + " introuvable")))
                .onErrorResume(WebClientResponseException.class, ex -> {
                    log.warn("SERVICE-CLIENT a repondu {} pour le client {}", ex.getStatusCode(), id);
                    return Mono.empty();
                })
                .onErrorResume(Exception.class, ex -> {
                    log.warn("SERVICE-CLIENT injoignable pour le client {} : {}", id, ex.getMessage());
                    return Mono.empty();
                });
    }

    /**
     * Version TP : block() est volontairement utilise pour garder un
     * controleur Spring MVC classique (voir section "Remarques qualite TP"
     * du README : en production, rester en Mono/Flux de bout en bout).
     */
    public Client findClientById(Long id) {
        return findClientByIdReactive(id).block();
    }
}
