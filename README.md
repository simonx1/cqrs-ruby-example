# Ruby CQRS example with rom, dry-system, kafka and different services

## Feedback policy

We can implement one pattern or idea in absolutely different ways and it's really cool. If you find some mistakes in implementation let's discuss it in github issues or personal.

### F.A.Q.

> Why did you create this repository?

Because it was interesting to build something like this for me and I got fun doing it.

> Why did you choose <technology_name>?

Because I know this technology better, or I just wanted to show how to use it in the "real" code, or I just wanted to play with technology in this project.

## Motivation

CQRS as a pattern is not super popular in the ruby world. This repository can show you how you can implement commands and queries in your services system and use CQRS for sharing data between separate services and DBs.

**Important:** The main goal of this repository just shows one more way how to implement CQRS pattern in ruby. it's not a production-ready example. And you can use other libraries or DBs without any problems.

## Project details

It's a simple blog platform with creating new users, posts with authors and comments for each post (with the author too). Now this repository implements only creation logic. If you want to add update/delete logic - feel free to send PR.

## Architecture

![Architecture diagram](https://github.com/davydovanton/cqrs-ruby-example/blob/master/docs/images/architecture.png?raw=true)

## List of services

### Users service
* CQRS: one relation DB.
* Kafka: no consumers, producer for `user_created` event
* Sync communications: zero

### Posts service
* CQRS: two relation DB (one for write, one for read)
* Kafka: consumers for `users`, `posts` and `comments` topics, producer for `post_created` event
* Sync communications: zero

### Comments service
* CQRS: two relation DB (one for write, one for read)
* Kafka: consumer for `comments` topic, producer for `comment_created` event
* Sync communications: one http call for getting user full name for read model

## Service implementation

Each service use rom for persistence, sitantra as a HTTP transport, dry-system as a dependency management system

In each service you can find same structure:

* `web_app.rb` - sintatra HTTP application with list of endpoints
* `karafka.rb` - [karafka](https://github.com/karafka/karafka) consumer application

* `config/boot.rb` - entripoint for booting dry-container and `.env` files

* `system/container.rb` - dry-system container
* `system/types.rb` - base dry-types module
* `system/boot/kafka_producer.rb` - simple wrapper around [waterdrop](http://github.com/karafka/waterdrop) for producing events to kafka
* `system/boot/*_rom.rb` - [ROM](http://rom-rb.org) instances for read and write models

- `lib/commands/*.rb` - list of struct objects with existing commands for specific service
- `lib/commands_handler/base.rb` - general class for execut specific command struct object
- `lib/commands_handler/*.rb` - separated classes with logic of each command

- `lib/queries/*.rb` - query classes which we use for getting agretate or data

- `lib/read_model/*.rb` - repositories and entities for read model
- `lib/write_model/*.rb` - repositories and entities for write model

- `lib/event_handlers/*.rb` - list of event execution logic which I call from karafka consumers
- `lib/events/*.rb` - list of struct objects which I use for produce events to kafka

## Useful links
- [Really good blog post wich explain CQRS and small details around this pattern](https://medium.com/@sderosiaux/cqrs-what-why-how-945543482313)
- [CQRS example from arkency. They use rails and rails event store](https://blog.arkency.com/2015/09/cqrs-example-in-the-rails-app/)
- Russian speakers only (sorry for this): [Record from the stream where I worked on this repository](https://youtu.be/_tiiYZGMsUs)

## How to setup project locally
- Web App run: rackup -p 9293
- Kafka: bundle exec karafka server
- Docker: https://developer.confluent.io/quickstart/kafka-docker/

Listen:
```
kafka-console-consumer --bootstrap-server broker:9092 \
                       --topic user-topic \
                       --from-beginning
```

Kafka delete queue:
```
docker exec --interactive --tty broker \
kafka-topics --bootstrap-server broker:9092 \
                       --topic post-topic \
                       --delete
```

APIs:
- Users Service:
```
GET /
GET /users
GET /users/:id
POST /users
```
- Posts Service
```
GET /
GET /posts
GET /posts/:id
POST /posts
```
- Comments Service
```
GET /
GET /comments
GET /comments/:id
GET /posts/:post_id/comments
POST /comments
```

Data Model:
- User
```
DROP TABLE IF EXISTS users;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```
- Post
```
DROP TABLE IF EXISTS posts;
CREATE TABLE `posts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `body` varchar(255) NOT NULL,
  `author_id` int NOT NULL,
  `comments_count` int NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```
- Comment
```
DROP TABLE IF EXISTS comments;
CREATE TABLE `comments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `body` varchar(255) NOT NULL,
  `author_id` int NOT NULL,
  `post_id` int NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```