# Smart Ticketing System: The Theory Behind the Practice

This document provides a deep dive into the theoretical concepts that underpin the Smart Ticketing System. It is designed to provide a comprehensive understanding of the "why" behind the implementation, preparing you for a presentation on the project.

## 1. Distributed Systems

A distributed system is a collection of independent computers that appears to its users as a single coherent system. In the context of the Smart Ticketing System, each microservice is a component of a larger distributed system. These services run on different containers, communicating and coordinating their actions to achieve the common goal of providing a seamless ticketing experience.

### Key Characteristics of Distributed Systems in this Project:

*   **Resource Sharing:** The microservices share resources such as the Kafka message broker and the MongoDB database.
*   **Concurrency:** Multiple operations can run simultaneously across different services. For example, a user can be registering for an account through the `passenger-service` while another user is purchasing a ticket through the `ticketing-service`.
*   **Scalability:** The system can be scaled by adding more instances of each microservice to handle increased load. For example, if the `ticketing-service` is under heavy load during peak hours, more instances of it can be deployed without affecting the other services.
*   **Fault Tolerance/Reliability:** If one microservice fails, the other services can continue to operate. For example, if the `notification-service` fails, users can still purchase tickets, and the notifications will be sent once the service is back online. This is achieved through the use of Kafka, which will queue the messages until the service is available.
*   **Transparency:** The user of the system, whether it's a passenger or an administrator, does not need to know which service is handling their request. They interact with the system as a single entity.

### Challenges of Distributed Systems:

*   **Complexity:** Distributed systems are more complex to design, build, and manage than monolithic systems.
*   **Concurrency:** Managing concurrent access to shared resources can be challenging.
*   **Partial Failures:** In a distributed system, it's possible for one part of the system to fail while the rest of the system continues to function. This can lead to inconsistencies if not handled properly.
*   **Security:** Securing a distributed system is more complex than securing a monolithic system, as there are more points of entry for an attacker.

## 2. Microservices Architecture

Microservices architecture is an architectural style that structures an application as a collection of loosely coupled, independently deployable services. Each service is organized around a specific business capability and can be developed, deployed, and scaled independently.

In the Smart Ticketing System, the application is broken down into six microservices:

*   **Passenger Service**
*   **Transport Service**
*   **Ticketing Service**
*   **Payment Service**
*   **Notification Service**
*   **Admin Service**

### Advantages of Microservices Architecture:

*   **Improved Scalability:** Each microservice can be scaled independently, allowing for more efficient use of resources.
*   **Faster Time to Market:** Services can be developed and deployed independently, which can lead to faster development cycles.
*   **Increased Resilience:** The failure of a single service does not necessarily cause the entire application to fail.
*   **Technology Freedom:** Different services can be written in different programming languages and use different technologies.

### Disadvantages of Microservices Architecture:

*   **Increased Complexity:** Microservices architectures are more complex than monolithic architectures, as they involve more moving parts.
*   **Data Consistency:** Maintaining data consistency across multiple services can be challenging.
*   **Testing:** Testing a microservices-based application can be more complex than testing a monolithic application.
*   **Deployment Complexity:** Deploying and managing a microservices-based application can be more complex than deploying and managing a monolithic application.

## 3. Event-Driven Architecture

Event-driven architecture (EDA) is a software design pattern in which services communicate with each other by sending and receiving events. An event is a significant change in state, such as a user purchasing a ticket or a payment being processed.

In the Smart Ticketing System, Kafka is used as the event broker. When a service needs to communicate with another service, it produces an event to a Kafka topic. Other services can then consume these events and react accordingly.

### Key Components of Event-Driven Architecture in this Project:

*   **Event Producers:** These are the services that generate events. For example, the `ticketing-service` produces a `ticket.requests` event when a new ticket is created.
*   **Event Consumers:** These are the services that consume events. For example, the `payment-service` consumes the `ticket.requests` event and processes the payment.
*   **Event Broker:** This is the central component that receives events from producers and delivers them to consumers. In this project, Kafka is used as the event broker.

### Advantages of Event-Driven Architecture:

*   **Loose Coupling:** Services are loosely coupled, as they do not need to have direct knowledge of each other.
*   **Asynchronous Communication:** Services can communicate asynchronously, which can improve the overall performance and responsiveness of the system.
*   **Scalability:** Event-driven architectures are highly scalable, as new services can be added to the system without affecting the existing services.
*   **Fault Tolerance:** If a service fails, the events can be queued in the event broker and processed later when the service is back online.

## 4. Apache Kafka

Apache Kafka is a distributed event streaming platform that is used to build real-time data pipelines and streaming applications. It is a key component of the Smart Ticketing System, enabling asynchronous communication between the microservices.

### Core Concepts of Kafka:

*   **Topics:** A topic is a category or feed name to which records are published. In this project, we have topics such as `ticket.requests`, `payments.processed`, and `schedule.updates`.
*   **Producers:** A producer is an application that publishes records to a Kafka topic.
*   **Consumers:** A consumer is an application that subscribes to one or more topics and processes the records produced to them.
*   **Brokers:** A Kafka cluster is made up of one or more servers called brokers. These brokers are responsible for storing the data and serving it to consumers.
*   **Zookeeper:** Zookeeper is used by Kafka to manage the cluster. It is responsible for tasks such as electing a controller, tracking the status of the brokers, and storing topic configurations.

### Why Kafka is a Good Choice for this Project:

*   **High Throughput:** Kafka is capable of handling a high volume of messages, which is important for a system that needs to process a large number of ticket purchases and validations.
*   **Low Latency:** Kafka is designed for low-latency message delivery, which is important for real-time applications.
*   **Scalability:** Kafka is highly scalable and can be easily expanded to handle a growing number of users and services.
*   **Fault Tolerance:** Kafka is a distributed system and is designed to be fault-tolerant. If a broker fails, the other brokers in the cluster can take over its work.
*   **Durability:** Kafka stores messages on disk, which makes it a durable message broker. This means that messages will not be lost even if a broker fails.

## 5. MongoDB

MongoDB is a popular NoSQL database that is used to store the data for the Smart Ticketing System. It is a document-oriented database, which means that it stores data in JSON-like documents.

### Core Concepts of MongoDB:

*   **Documents:** A document is a set of key-value pairs. Documents have a dynamic schema, which means that documents in the same collection do not need to have the same set of fields or structure.
*   **Collections:** A collection is a group of documents. Collections are analogous to tables in a relational database.
*   **Databases:** A database is a physical container for collections. Each database gets its own set of files on the file system.

### Why MongoDB is a Good Choice for this Project:

*   **Flexible Schema:** The flexible schema of MongoDB makes it easy to store and manage the data for the Smart Ticketing System, as the data model can evolve over time without requiring a schema migration.
*   **Scalability:** MongoDB is highly scalable and can be easily expanded to handle a growing amount of data.
*   **High Performance:** MongoDB is designed for high performance and can handle a large number of reads and writes.
*   **Rich Query Language:** MongoDB provides a rich query language that allows for powerful and flexible queries.

## 6. Containerization with Docker

Containerization is a lightweight form of virtualization that allows you to package an application and its dependencies into a single, isolated unit called a container. Docker is a popular platform for building, running, and managing containers.

In the Smart Ticketing System, each microservice is packaged as a Docker container. This provides several benefits:

*   **Portability:** The containers can be run on any machine that has Docker installed, regardless of the underlying operating system.
*   **Isolation:** Each container runs in its own isolated environment, which prevents conflicts between different services.
*   **Consistency:** The containers ensure that the application runs in a consistent environment, from development to production.

## 7. Orchestration with Docker Compose

Docker Compose is a tool for defining and running multi-container Docker applications. It allows you to use a YAML file to configure your application's services, networks, and volumes.

In the Smart Ticketing System, Docker Compose is used to orchestrate the deployment of the entire system. The `docker-compose.yml` file defines the six microservices, as well as the Kafka, Zookeeper, and MongoDB services. This makes it easy to start, stop, and manage the entire application with a single command.

## 8. REST APIs

REST (Representational State Transfer) is an architectural style for designing networked applications. It is based on a stateless, client-server, cacheable communications protocol — and in virtually all cases, the HTTP protocol is used.

REST APIs are used in the Smart Ticketing System to expose the functionality of the microservices to the client applications. For example, the `passenger-cli` application uses the REST API of the `passenger-service` to register and log in users.

### Key Principles of REST:

*   **Client-Server:** The client and server are separate from each other and can evolve independently.
*   **Stateless:** The server does not store any information about the client between requests. Each request from the client must contain all the information needed to understand and process the request.
*   **Cacheable:** The client can cache responses. The server must, therefore, implicitly or explicitly state whether the response is cacheable or not.
*   **Uniform Interface:** This is the fundamental principle of REST. It simplifies and decouples the architecture, which enables each part to evolve independently.

## 9. Ballerina

Ballerina is an open-source programming language for the cloud that makes it easier to use, combine, and create network services. It is the language used to write all the microservices in the Smart Ticketing System.

### Key Features of Ballerina:

*   **Cloud-Native:** Ballerina is designed from the ground up for writing cloud-native applications. It has built-in support for microservices, Docker, and Kubernetes.
*   **Network-Aware:** Ballerina has a network-aware type system that makes it easy to work with network services.
*   **Graphical Syntax:** Ballerina has a graphical syntax that allows you to visualize your code as a sequence diagram. This makes it easier to understand and debug your code.
*   **Concurrency:** Ballerina has built-in support for concurrency, which makes it easy to write high-performance, scalable applications.