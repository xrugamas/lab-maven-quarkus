package org.acme.rest.json;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasItems;

import org.junit.jupiter.api.Test;

import io.quarkus.test.junit.QuarkusTest;

@QuarkusTest
class FruitResourceTest {

    @Test
    void listaInicial() {
        given().when().get("/fruits")
            .then().statusCode(200)
            .body("name", hasItems("Apple", "Pineapple"));
    }

    @Test
    void agregarFruta() {
        given().contentType("application/json")
            .body("{\"name\":\"Mango\",\"description\":\"Fruta de temporada\"}")
            .when().post("/fruits")
            .then().statusCode(200)
            .body("name", hasItem("Mango"));
    }
}
