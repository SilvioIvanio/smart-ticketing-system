# GEMINI.md

## Project Overview

This project is a **Smart Public Transport Ticketing System** for Windhoek City Council's buses and trains. It is a distributed, microservices-based platform designed to replace traditional paper-based ticketing systems. The system is built using **Ballerina** for the microservices, **Apache Kafka** for event-driven communication, **MongoDB** for data storage, and **Docker** for containerization and orchestration.

The main goals of the project are to provide a seamless and convenient ticketing experience for passengers, and to provide administrators with real-time data and tools to manage the transport system efficiently.

## Building and Running

### Prerequisites

*   Docker Desktop
*   PowerShell (on Windows) or a shell that can run `.sh` files.
*   6GB of RAM available

### Building the Services

To build all the services, run the `build-all.sh` script from the root of the project:

```sh
./build-all.sh
```

This will compile all the Ballerina services and create the necessary JAR files for running them.

### Running the System

The entire system can be started using Docker Compose:

```sh
docker-compose up -d
```

This will start all the microservices, as well as Kafka, Zookeeper, and MongoDB.

To stop the system, run:

```sh
docker-compose down
```

To stop the system and remove all data, run:

```sh
docker-compose down -v
```

### Testing the System

The `Readme.md` file contains a set of `Invoke-RestMethod` commands for testing the system using PowerShell. These can be adapted for use with `curl` or other tools.

## Development Conventions

*   All microservices are written in **Ballerina**.
*   Services communicate with each other asynchronously using **Apache Kafka**.
*   **MongoDB** is used as the persistent data store.
*   All services are containerized using **Docker**.
*   The system is orchestrated using **Docker Compose**.
*   The `build-all.sh` script is used to build all the services.

## Services

The system is composed of the following microservices:

| Service | Port | Description |
|---|---|---|
| **Passenger Service** | 9090 | Handles user registration, login, and ticket management. |
| **Ticketing Service** | 9091 | Manages the lifecycle of tickets (CREATED, PAID, VALIDATED, EXPIRED). |
| **Transport Service** | 9094 | Manages routes and trips. |
| **Admin Service** | 9093 | Provides sales reports and allows for publishing disruption alerts. |
| **Payment Service** | - | Simulates payment processing and runs as a background service. |
| **Notification Service** | - | Sends notifications to users about trip updates and other events. |

## Data Models

The main data models used in the system are:

*   **User:** Represents a passenger or an administrator.
*   **Route:** Represents a bus or train route.
*   **Trip:** Represents a specific journey on a route at a particular time.
*   **Ticket:** Represents a ticket for a trip.
*   **Payment:** Represents a payment for a ticket.

## Kafka Topics

The following Kafka topics are used for event-driven communication between the services:

*   `ticket.requests`: Used to request the creation of a new ticket.
*   `payments.processed`: Used to confirm that a payment has been processed.
*   `schedule.updates`: Used to broadcast updates to transport schedules.
