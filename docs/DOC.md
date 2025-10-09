# Smart Public Transport Ticketing System Documentation

## Overview

This project implements a distributed, event-driven smart ticketing system for Windhoek's city buses and trains using microservices architecture. The system facilitates passenger ticketing, transport administration, ticket validation, and real-time notifications through asynchronous Kafka messaging, persistent storage in MongoDB, and container orchestration with Docker and Kubernetes.

---

## Learning Objectives

- Design and implement microservices with clear boundaries using Ballerina.
- Apply event-driven architecture with Kafka producers and consumers.
- Model persistent data using MongoDB; understand consistency considerations.
- Containerise microservices with Docker; orchestrate with Docker Compose or Kubernetes.
- Implement testing, monitoring, and fault tolerance in distributed environments.

---

## System Architecture & Components

## Microservices and Responsibilities

| Service | Responsibilities |
| --- | --- |
| **Passenger** | User registration/login, account & ticket management, view purchased tickets |
| **Transport** | Route and trip creation/management, publish schedule updates |
| **Ticketing** | Handle ticket lifecycle: CREATED → PAID → VALIDATED → EXPIRED |
| **Payment** | Simulate and confirm ticket payments via Kafka events |
| **Notification** | Send notifications on disruptions, delays, cancellations, and ticket validation confirmations |
| **Admin** | Manage routes, trips, sales reports, publish disruptions and schedule changes |

---

## Key Technologies & Tools

- **Ballerina:** For writing all microservices. Supports inbuilt support for network handling, Kafka, HTTP APIs, and MongoDB integration.
- **Apache Kafka:** Event-driven messaging. Topic examples: `ticket.requests`, `payments.processed`, `schedule.updates`.
- **MongoDB:** NoSQL document store for persistence of Users, Tickets, Routes, Trips, Payments, etc.
- **Docker & Docker Compose/Kubernetes:** Containerization and orchestration for deploying and managing microservices.

---

## Step-by-Step Implementation Guide

## 1. Kafka Setup & Topic Management

- Install Kafka and Zookeeper or use a Kafka cluster.
- Create required Kafka topics:
    - `ticket.requests`
    - `payments.processed`
    - `schedule.updates`
- Define Kafka producers and consumers in each service as appropriate, e.g.,
    - Ticketing service listens to `ticket.requests`
    - Payment service produces to `payments.processed`

## 2. Database Setup & Schema Design

- Design MongoDB collections for key entities:
    - `users`: id, username, password_hash, roles (passenger, admin, validator)
    - `routes`: route_id, name, stops, schedules
    - `trips`: trip_id, route_id, departure_time, status
    - `tickets`: ticket_id, user_id, trip_id, type (single, multi, pass), status (CREATED, PAID, VALIDATED, EXPIRED)
    - `payments`: payment_id, ticket_id, status
- Use MongoDB Compass for schema visualization and testing.
- Ensure atomic updates where needed for consistency.

## 3. Microservices Implementation in Ballerina

- Structure each service as a standalone Ballerina project.
- Define REST API endpoints for interaction (e.g., Passenger registration/login, Admin route management).
- Implement Kafka producers and consumers using Ballerina Kafka client.
- Use MongoDB client APIs in Ballerina for persistence.
- Maintain event-driven communication to update statuses across services.
- Example: Ticketing service listens for payment confirmation events to update ticket status to PAID.

## 4. Authentication & Security

- Implement user authentication in Passenger Service (e.g., JWT tokens).
- Secure sensitive APIs with role-based access control.
- Passwords stored securely using hashing algorithms.

## 5. Containerization with Docker

- Write Dockerfiles for each microservice defining the environment to run Ballerina programs.
- Build Docker images and tag appropriately.
- Use Docker Compose or Kubernetes manifests for multi-service deployment:
    - Define service dependencies (e.g., Kafka broker and MongoDB service dependencies).
    - Map ports for external API access.
    - Persist data volumes for MongoDB storage.

## 6. Orchestration & Deployment

- Use Docker Compose for local multi-service orchestration:
    - Compose file defines all services plus Kafka, Zookeeper, and MongoDB.
- Alternatively, write Kubernetes manifests (Deployment, Service, ConfigMap) for production-like environment.
- Ensure services restart policies and resource limits are set.

## 7. Testing & Validation

- Write unit and integration tests for each microservice API.
- Simulate concurrent ticket purchases and validations to test Kafka messaging and database consistency.
- Monitor logs and metrics to identify faults.
- Implement retry mechanisms for transient failures.

## 8. Monitoring & Fault Tolerance

- Integrate logging in all services.
- Use Kafka’s built-in fault tolerance and topic replication.
- Consider Kafka consumer offset management for message processing guarantees.
- Use Docker/Kubernetes health checks and auto-restart policies.

## 9. Documentation & Presentation

- Prepare clear README files per service (API specs, setup instructions).
- Document Kafka topics and event schemas.
- Provide deployment guides.
- Include diagrams for microservices interaction and data flow.

---

## Sample Kafka Topic Event Schema (JSON)

```json
"ticketRequest": {
    "ticketId": "uuid",
    "userId": "uuid",
    "tripId": "uuid",
    "ticketType": "single|multi|pass",
    "status": "CREATED"
  },
  "paymentProcessed": {
    "paymentId": "uuid",
    "ticketId": "uuid",
    "status": "SUCCESS|FAILED",
    "timestamp": "ISO8601"
  },
  "scheduleUpdate": {
    "routeId": "uuid",
    "tripId": "uuid",
    "status": "ON_TIME|DELAYED|CANCELLED",
    "timestamp": "ISO8601"
  }
```

---

## Additional Resources for Ballerina, Kafka, MongoDB, Docker

- [Ballerina Official Documentation](https://ballerina.io/learn/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

This documentation should guide you through the full lifecycle of designing, developing, deploying, and testing the smart public transport ticketing system. Each step aligns with the assignment's evaluation criteria.