# Smart Public Transport Ticketing System

A distributed, event‑driven ticketing platform for buses and trains, built with a microservices architecture for the Windhoek City Council.

## Overview

This system replaces paper tickets and siloed machines with modern digital purchase, validation, and monitoring flows across passengers, admins, and validators.

### Problem

- Limited purchase options for passengers
- Validator failures cause delays
- Poor visibility for administrators
- No real‑time disruption notifications

### Solution

- Digital purchase and validation
- Real‑time notifications and updates
- Admin analytics and reports
- Scales to peak demand via Kafka‑backed, fault‑tolerant microservices

## Features

### Passenger

- Registration, login, profile
- Browse routes and trips
- Purchase single, daily, weekly tickets
- Digital validation and status tracking
- Real‑time alerts for disruptions

### Administrator

- Create and manage routes and trips
- Vehicle assignment and activation
- Real‑time sales and revenue reports
- Publish service disruptions with severity

### System

- Event‑driven via Kafka topics
- Fault tolerance and high availability
- MongoDB persistence
- Dockerized services with Compose orchestration

## Architecture

```
CLIENTS (Passenger CLI | Admin CLI | Validator App)
    │
    ▼
MICROSERVICES
    Passenger :9090 | Ticketing :9091 | Payment :9092
    Admin :9093     | Transport :9094 | Notification :9095
        │
        ▼
INFRASTRUCTURE
    Kafka (:9092, :29092) topics: ticket.requests, payments.processed,
        schedule.updates, [ticket.events](http://ticket.events)
    MongoDB (:27017) collections: users, routes, trips, tickets,
        payments, disruptions
```

### Event Flows

- Ticket purchase: Passenger → Ticketing → ticket.requests → Payment → payments.processed → Ticketing updates → Notification
- Disruption: Admin → schedule.updates → Notification → affected passengers

## Tech Stack

| Technology | Version | Purpose |
| --- | --- | --- |
| Ballerina | 2201.12.10 | Services |
| Apache Kafka | 3.x | Event streaming |
| MongoDB | 7.x | Persistence |
| Docker | 20.x+ | Containers |
| Docker Compose | 2.x+ | Orchestration |

## Prerequisites

- Ballerina 2201.12.10 (`bal version`)
- Docker 20.x (`docker --version`)
- Docker Compose 2.x (`docker compose version`)
- Java 11+ (`java -version`)

## Quick Start

1. Clone and build
    
    ```bash
    git clone <REPO_URL>
    cd smart-ticketing-system
    chmod +x [build-all.sh](http://build-all.sh) && ./[build-all.sh](http://build-all.sh)    # Linux/Mac
    # or
    ./build-all.bat                             # Windows
    ```
    
2. Start infrastructure
    
    ```bash
    docker compose up -d
    docker compose ps
    ```
    
3. Smoke test
    
    ```bash
    chmod +x test_[system.sh](http://system.sh) && ./test_[system.sh](http://system.sh)     # Linux/Mac
    # or
    ./test_[system.ps](http://system.ps)1                               # Windows
    ```