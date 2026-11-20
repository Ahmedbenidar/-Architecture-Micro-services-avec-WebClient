package com.example.car.web;

import com.example.car.entities.Car;
import com.example.car.entities.Client;
import com.example.car.repositories.CarRepository;
import com.example.car.services.ClientApi;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
@RequestMapping("/api/cars")
public class CarController {

    private final CarRepository repo;
    private final ClientApi clientApi;

    public CarController(CarRepository repo, ClientApi clientApi) {
        this.repo = repo;
        this.clientApi = clientApi;
    }

    @PostMapping
    public Car save(@RequestBody Car car) {
        // Sauvegarde uniquement la voiture (DB locale carservicedb)
        return repo.save(car);
    }

    @GetMapping
    public List<Car> findAll() {
        List<Car> cars = repo.findAll();

        // Enrichissement : pour chaque voiture, recuperer le client via WebClient
        for (Car car : cars) {
            if (car.getClientId() != null) {
                car.setClient(clientApi.findClientById(car.getClientId()));
            }
        }
        return cars;
    }

    @GetMapping("/byClient/{clientId}")
    public List<Car> findByClient(@PathVariable Long clientId) {
        List<Car> cars = repo.findByClientId(clientId);
        Client client = clientApi.findClientById(clientId);
        for (Car car : cars) {
            car.setClient(client);
        }
        return cars;
    }

    /** Meme logique, mais enchainee en reactif (sans block()) : illustration du gain WebClient. */
    @GetMapping("/reactive")
    public Flux<Car> findAllReactive() {
        return Flux.fromIterable(repo.findAll())
                .flatMap(car -> car.getClientId() == null
                        ? Mono.just(car)
                        : clientApi.findClientByIdReactive(car.getClientId())
                            .doOnNext(car::setClient)
                            .thenReturn(car)
                            .defaultIfEmpty(car));
    }
}
