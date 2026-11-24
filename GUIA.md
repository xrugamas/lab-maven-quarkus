# Laboratorio: Maven + Quarkus REST JSON en Ubuntu (WSL)

**Objetivo:** dominar el ciclo de vida de Apache Maven y construir una API REST con JSON usando
Quarkus. Todo se publica en GitHub (`xrugamas`) con ramas, issues, pull requests y CI, que es la
forma en que se ganan los logros (badges) del perfil.

**Carpeta de trabajo:** `~/labs/lab-maven-quarkus` (dentro de Linux, **no** en `/mnt/c/...`:
ahí Maven es mucho más lento y Git pierde el permiso de ejecución de `mvnw`).

Estructura final del repositorio:

```
lab-maven-quarkus/
├── GUIA.md
├── README.md                      ← con el badge de build
├── .github/workflows/maven.yml    ← CI: compila y corre pruebas en cada push
├── scripts/01-instalar-herramientas.sh
├── 01-maven-basico/mi-primer-lab/        ← Parte 3
└── 02-quarkus-rest-json/rest-json-quickstart/  ← Parte 4
```

---

## Parte 1 · Herramientas

### 1.1 Paquetes del sistema (necesita sudo)

```bash
bash ~/labs/lab-maven-quarkus/scripts/01-instalar-herramientas.sh
```

Instala `zip`, `tree` y `gh` (CLI de GitHub), y **descarga** el instalador de SDKMAN sin
ejecutarlo.

### 1.2 SDKMAN (gestor de versiones de Java, Maven y Quarkus)

> Regla de seguridad: solo ejecutas scripts de instalación que **tú** descargaste de la página
> oficial de la herramienta y que revisaste. Ningún sitio legítimo te pide pegar comandos para
> "verificar que eres humano".

```bash
less /tmp/sdkman-install.sh          # revisar
bash /tmp/sdkman-install.sh
source ~/.sdkman/bin/sdkman-init.sh
sdk version
```

### 1.3 Java 21, Maven y Quarkus CLI

Quarkus pide JDK 17 o superior; usamos Temurin 21 (LTS).

```bash
sdk list java | grep -- '-tem'       # copia el identificador 21.x, por ejemplo 21.0.x-tem
sdk install java <identificador-21-tem>
sdk install maven 3.9.16             # si no aparece: sdk list maven
sdk install quarkus
```

SDKMAN configura `JAVA_HOME` solo; **no** hace falta editar `~/.bashrc` a mano.

### 1.4 Verificar

```bash
java -version          # 21.x
echo $JAVA_HOME        # ~/.sdkman/candidates/java/current
mvn -version           # Apache Maven 3.9.x y la misma ruta de Java
quarkus --version
```

✅ **Listo cuando** `mvn -version` muestra Maven 3.9.x y Java 21.

---

## Parte 2 · Git y GitHub

```bash
git config --global user.name  "Cesar Romero"
git config --global user.email "<tu-correo-noreply-de-github>"
git config --global init.defaultBranch main
gh auth login          # GitHub.com → HTTPS → Login with a web browser
```

El correo **noreply** está en GitHub → Settings → Emails (“Keep my email addresses private”).
Así tu correo real no queda en el historial público.

Crear el repositorio y subir la guía:

```bash
cd ~/labs/lab-maven-quarkus
git init
git add GUIA.md scripts
git commit -m "Guía y script de instalación del laboratorio"
gh repo create xrugamas/lab-maven-quarkus --public --source=. --push
```

---

## Parte 3 · Maven básico (repaso)

```bash
mkdir -p ~/labs/lab-maven-quarkus/01-maven-basico && cd $_
mvn archetype:generate -DgroupId=sv.xrugamas.lab -DartifactId=mi-primer-lab \
  -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
cd mi-primer-lab && tree
```

| Comando | Fase del ciclo de vida | Qué deja |
|---|---|---|
| `mvn clean` | clean | borra `target/` |
| `mvn compile` | compile | `.class` en `target/classes` |
| `mvn test` | test | corre JUnit de `src/test/java` |
| `mvn package` | package | `target/mi-primer-lab-1.0-SNAPSHOT.jar` |
| `mvn install` | install | copia el JAR a `~/.m2/repository` |

```bash
mvn clean package
java -cp target/mi-primer-lab-1.0-SNAPSHOT.jar sv.xrugamas.lab.App   # Hello World!
```

**Ejercicio:** cada fase incluye las anteriores. Ejecuta `mvn package -DskipTests` y compara la
salida con `mvn package`: ¿qué fase se saltó?

✅ Sube esta parte con tu **primer pull request** (Parte 5, flujo de trabajo).

---

## Parte 4 · API REST con JSON (Quarkus)

La aplicación guarda una lista de frutas. El navegador y el servidor se hablan en JSON.

### 4.1 Crear el proyecto

```bash
mkdir -p ~/labs/lab-maven-quarkus/02-quarkus-rest-json && cd $_
quarkus create app org.acme:rest-json-quickstart --extension='rest-jackson' --no-code
cd rest-json-quickstart && tree -L 4
```

Sin la CLI de Quarkus, el mismo proyecto se crea con el plugin de Maven:
`mvn io.quarkus.platform:quarkus-maven-plugin:create -DprojectGroupId=org.acme -DprojectArtifactId=rest-json-quickstart -Dextensions='rest-jackson' -DnoCode`

Mira en `pom.xml` la dependencia que se agregó:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-rest-jackson</artifactId>
</dependency>
```

El proyecto trae **`./mvnw`** (Maven Wrapper): fija la versión de Maven del proyecto. Úsalo en
lugar de `mvn` dentro de esta carpeta.

### 4.2 El modelo · `src/main/java/org/acme/rest/json/Fruit.java`

```java
package org.acme.rest.json;

public class Fruit {

    public String name;
    public String description;

    public Fruit() {
    }

    public Fruit(String name, String description) {
        this.name = name;
        this.description = description;
    }
}
```

El constructor vacío es obligatorio: Jackson lo usa para convertir el JSON que llega en un objeto.

### 4.3 El recurso REST · `src/main/java/org/acme/rest/json/FruitResource.java`

```java
package org.acme.rest.json;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Set;

import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;

@Path("/fruits")
public class FruitResource {

    private final Set<Fruit> fruits = Collections.newSetFromMap(Collections.synchronizedMap(new LinkedHashMap<>()));

    public FruitResource() {
        fruits.add(new Fruit("Apple", "Winter fruit"));
        fruits.add(new Fruit("Pineapple", "Tropical fruit"));
    }

    @GET
    public Set<Fruit> list() {
        return fruits;
    }

    @POST
    public Set<Fruit> add(Fruit fruit) {
        fruits.add(fruit);
        return fruits;
    }

    @DELETE
    public Set<Fruit> delete(Fruit fruit) {
        fruits.removeIf(existing -> existing.name.contentEquals(fruit.name));
        return fruits;
    }
}
```

No hace falta `@Produces`/`@Consumes`: con `rest-jackson`, Quarkus responde y recibe JSON por
defecto.

### 4.4 Probar en modo desarrollo

```bash
./mvnw quarkus:dev          # o: quarkus dev
```

En otra terminal de Ubuntu:

```bash
curl -s localhost:8080/fruits
curl -s -X POST localhost:8080/fruits -H 'Content-Type: application/json' \
     -d '{"name":"Mango","description":"Fruta de temporada"}'
curl -s -X DELETE localhost:8080/fruits -H 'Content-Type: application/json' -d '{"name":"Apple"}'
```

`localhost:8080` también abre desde el navegador de Windows. En modo dev, cambia el código y
vuelve a llamar: Quarkus recarga solo. La tecla `d` abre la Dev UI.

### 4.5 El formulario · `src/main/resources/META-INF/resources/fruits.html`

```html
<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>Frutas</title></head>
<body>
  <h1>Frutas</h1>
  <form id="f">
    <input id="name" placeholder="Nombre" required>
    <input id="description" placeholder="Descripción">
    <button>Agregar</button>
  </form>
  <ul id="lista"></ul>
  <script>
    const pintar = frutas => document.getElementById('lista').innerHTML =
      frutas.map(f => `<li>${f.name}: ${f.description ?? ''}</li>`).join('');
    fetch('/fruits').then(r => r.json()).then(pintar);
    document.getElementById('f').addEventListener('submit', e => {
      e.preventDefault();
      fetch('/fruits', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({name: name.value, description: description.value})
      }).then(r => r.json()).then(pintar);
      e.target.reset();
    });
  </script>
</body>
</html>
```

Abre `http://localhost:8080/fruits.html`, agrega una fruta y mira la lista actualizarse.

### 4.6 Prueba automática · `src/test/java/org/acme/rest/json/FruitResourceTest.java`

```java
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
```

Si `./mvnw test` no encuentra `io.restassured`, agrega al `pom.xml`:

```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <scope>test</scope>
</dependency>
```

### 4.7 Empaquetar y ejecutar

```bash
./mvnw clean package
java -jar target/quarkus-app/quarkus-run.jar
```

✅ **Listo cuando** `./mvnw verify` pasa y `fruits.html` agrega frutas.

---

## Parte 5 · Flujo de trabajo en GitHub y logros

Cada parte del laboratorio entra al repositorio por **pull request**, no con push directo a `main`.

### Flujo para cada cambio

```bash
git switch -c feat/maven-basico            # una rama por tema
git add 01-maven-basico
git commit -m "Proyecto Maven quickstart y ciclo de vida"
git push -u origin feat/maven-basico
gh pr create --fill
gh pr merge --merge --delete-branch
git switch main && git pull
```

Ramas sugeridas, en orden: `feat/maven-basico` → `feat/quarkus-proyecto` → `feat/fruit-api`
→ `feat/formulario` → `test/fruit-resource` → `ci/github-actions`.

### CI con badge · `.github/workflows/maven.yml`

```yaml
name: Build
on:
  push:
    branches: [main]
  pull_request:
jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 02-quarkus-rest-json/rest-json-quickstart
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
          cache: maven
      - run: ./mvnw -B verify
```

En `README.md` del repositorio:

```markdown
# Laboratorio Maven + Quarkus
![Build](https://github.com/xrugamas/lab-maven-quarkus/actions/workflows/maven.yml/badge.svg)
```

### Logros del perfil que este flujo da de forma legítima

| Logro | Cómo se obtiene en este laboratorio |
|---|---|
| **Pull Shark** | 2 pull requests fusionados (el flujo de arriba da 6) |
| **YOLO** | Fusionar un PR sin revisión: `gh pr merge` en tu propio repo |
| **Quickdraw** | Cerrar un issue o PR en menos de 5 min desde que se abrió: crea el issue `gh issue create --title "Agregar badge de build al README"`, haz el cambio y fusiona el PR con `Closes #<número>` en el mensaje |
| **Pair Extraordinaire** | Un commit en coautoría **real** dentro de un PR fusionado: cuando un compañero trabaje contigo, agrega al final del commit `Co-authored-by: Nombre <correo-de-su-cuenta>` |
| Starstruck, Galaxy Brain | Dependen de otras personas (estrellas, respuestas aceptadas): llegan solos si el repositorio les sirve |

Para que se vean: GitHub → Settings → Public profile → marcar **Show Achievements on my profile**.
Los logros pueden tardar unas horas en aparecer.

---

## Lista de verificación

- [ ] Parte 1: `mvn -version` con Maven 3.9.x y Java 21
- [ ] Parte 2: repositorio `xrugamas/lab-maven-quarkus` creado
- [ ] Parte 3: `Hello World!` desde el JAR · PR fusionado
- [ ] Parte 4: `fruits.html` funciona · `./mvnw verify` pasa
- [ ] Parte 5: badge de build en verde · issue cerrado con PR

Mis Notas
# Ejercicio: mvn package -DskipTests vs mvn package

## Qué observé
- ...
## Qué fase se saltó (y cuál no)
- ...

## Por qué igual se generó el JAR
- ...

## -DskipTests vs -Dmaven.test.skip=true
- ...