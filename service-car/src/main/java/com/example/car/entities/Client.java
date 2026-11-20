package com.example.car.entities;

/**
 * DTO local : sert uniquement a mapper le JSON renvoye par SERVICE-CLIENT.
 * Les noms de champs doivent correspondre EXACTEMENT au JSON distant
 * (id, nom, age) sinon Jackson les laisse a null silencieusement.
 */
public class Client {

    private Long id;
    private String nom;
    private Float age;

    public Client() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public Float getAge() { return age; }
    public void setAge(Float age) { this.age = age; }
}
