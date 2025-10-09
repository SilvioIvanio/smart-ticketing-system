# Project Overview

This project implements a Smart Public Transport Ticketing System using a microservices architecture. It's designed for managing passenger information, ticketing, transport routes, payments, and notifications for a city's public transport system.

**Key Technologies:**

*   **Ballerina:** Used for implementing the individual microservices.
*   **Apache Kafka:** Serves as the event-driven messaging backbone for inter-service communication.
*   **MongoDB:** The primary NoSQL database for persistent data storage across services.
*   **Docker & Docker Compose:** Used for containerization and orchestration of all services and infrastructure components.

**Architecture:**

The system comprises six distinct microservices: Passenger, Ticketing, Transport, Admin, Payment, and Notification. These services interact with each other primarily through Apache Kafka for asynchronous communication and share data persistence via MongoDB.

## Building and Running

### Prerequisites

*   Docker Desktop
*   PowerShell (for Windows-specific scripts, though `build-all.sh` and `test_system.sh` are bash scripts)
*   Minimum 6GB RAM available

### Build All Services

To build all Ballerina microservices, execute the `build-all.sh` script:

```bash
./build-all.sh
```

This script navigates into each service's directory and runs `bal build` to compile the Ballerina code into executable JAR files.

### Deploy and Run with Docker Compose

The entire system, including Kafka, Zookeeper, MongoDB, and all microservices, can be deployed and run using Docker Compose:

```bash
docker-compose up -d
```

Wait approximately 30 seconds for all services to become ready after deployment.

### Run Integration Tests

An integration test suite is available to verify the system's functionality. Ensure the system is deployed and running before executing:

```bash
./test_system.sh
```

This script performs a series of `curl` commands to simulate user interactions like registration, login, route creation, ticket purchase, and report generation.

### Stopping the System

To stop all running services and remove their containers:

```bash
docker-compose down
```

To stop services and remove all associated data volumes (for a clean slate):

```bash
docker-compose down -v
```

## Development Conventions

*   **Language:** Ballerina is the primary language for service implementation.
*   **Configuration:** Service-specific configurations (e.g., database connections, Kafka bootstrap servers) are managed via `Config.toml` files within each service's directory.
*   **Containerization:** Each service is containerized using Docker, with `Dockerfile`s defining their build environment and dependencies. The `docker-compose.yml` orchestrates their deployment.
*   **API Endpoints:** Services expose RESTful HTTP endpoints, as demonstrated in `admin_service.bal`.
*   **Messaging:** Apache Kafka is used for event-driven communication between services, facilitating asynchronous operations like payment processing and notifications.
*   **Data Storage:** MongoDB is used for persisting application data.
