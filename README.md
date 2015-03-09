# Servidor proyecto PROGREZZ #
## 1. Introducción ##
El servidor de Progrezz permite centralizar y procesar todos los datos referentes a los usuarios o jugadores del mismo.

Para evitar sobrecarga en los dispositivos y erradicar comportamientos no deseados en los jugadores (trampas, lenguaje ofensivo, ...), se ha tomado la decisión de gestionar el mayor número de tareas posible, permitiendo al usuario realizar tareas tan sencillas como dibujar en pantalla el contenido solicitado al servidor.

Para una mayor modularidad, se utilizará Ruby Sinatra sobre el servidor Thin, usando una base de datos neo4j.

## 2. Acceso al servidor ##
Actualmente, el servidor está hosteado en los siguientes servidores o servicios:

- Heroku: http://progrezz-server.herokuapp.com/

## 3. Dependencias ##
#### Ruby  ####
Las dependecias de ruby se pueden encontrar en el Gemfile del repositorio. Pueden ser instaladas cómodamente con ```bundle```, tal como se muestra en el punto **6. Uso**.

#### Base de datos ####
Será necesario un servidor funcional [neo4j](http://neo4j.com), junto son su dirección de acceso en una de las siguientes variables de entorno:

- PROGREZZ_NEO4J_URL
- GRAPHENDB_URL

Deben tener el siguiente formato URI:

``` http://<usuario>:<password>@<dominio-servidor>:<puerto>/db/data/ ```

También se intentará buscar como último remedio en el host *http:localhost:7474* (sin credenciales de acceso).

## 6.  Uso ##
#### Instalación ####
Una vez instalada e iniciada la base de datos, se puede preparar el servidor con el siguiente comando, desde la carpeta raíz del proyecto:

```
$ rake setup
```

#### Ejecución ####

El servidor puede ser iniciado en modo prueba con

```
$ rake development
```

Para iniciar en modo producción, use
```
$ rake production
```

Para subir el proyecto a heroku, teniendo definida el repositorio remoto ```heroku```,  utilice

```
$ rake heroku
```

#### Otros ####

Para generar la documentación, use

```
$ rake doc
```

Para más información, mire el contenido del fichero ```rakefile```.

## 5. Contacto ##
Envíe cualquier duda, comentario u opinión a cualquier correo de la siguiente lista:

- Proyecto progrezz: [proyecto.progrezz@gmail.com](mailto:proyecto.progrezz@gmail.com)
