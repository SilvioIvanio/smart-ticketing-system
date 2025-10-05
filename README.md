# Smart Public Transport Ticketing System

A distributed microservices-based ticketing platform for Windhoek City Council's buses and trains.

## Architecture

- **6 Microservices** running in Docker containers
- **Apache Kafka** for event-driven messaging
- **MongoDB** for persistent data storage
- **Docker Compose** for orchestration

## Services

| Service | Port | Description |
|---------|------|-------------|
| Passenger Service | 9090 | User registration, login, ticket management |
| Ticketing Service | 9091 | Ticket lifecycle management |
| Transport Service | 9094 | Routes and trips management |
| Admin Service | 9093 | Sales reports, disruption alerts |
| Payment Service | - | Payment processing (background) |
| Notification Service | - | Event notifications (background) |

## Prerequisites

- Docker Desktop
- PowerShell (Windows)
- 6GB RAM available

## Quick Start

### 1. Deploy System

```powershell
docker-compose up -d

```


### 2. Wait for Services (30 seconds)

```powershell
Start-Sleep -Seconds 30

```

### 3. Run Demo

```powershell
.\\demo.ps1

```

### 4. Check Status

```powershell
docker-compose ps

```

All services should show "Up" status.

### 5. View Logs

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f passenger-service

```

## Testing the System

### Register a Passenger

```powershell
Invoke-RestMethod -Uri "<http://localhost:9090/passenger/register>" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    username = "John Doe"
    email = "john@example.com"
    password = "password123"
  } | ConvertTo-Json)

```

### Create a Route

```powershell
Invoke-RestMethod -Uri "<http://localhost:9094/transport/routes>" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    name = "City Loop"
    routeType = "bus"
    stops = @("Station A", "Station B")
    schedule = @{ weekdays = @("08:00") }
  } | ConvertTo-Json)

```

### Get Sales Report

```powershell
Invoke-RestMethod -Uri "<http://localhost:9093/admin/reports/sales>"

```

## Data Persistence

MongoDB data is persisted in Docker volume: `smart-ticketing-system_mongodb-data`

### View MongoDB Data

```powershell
# Connect to MongoDB
docker exec -it mongodb mongosh

# Inside MongoDB shell
use ticketing_db
db.users.find().pretty()
db.tickets.find().pretty()
db.routes.find().pretty()
exit

```

### View Kafka Messages

```powershell
# View ticket requests
docker exec -it kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic ticket.requests `
  --from-beginning

# View payment confirmations
docker exec -it kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic payments.processed `
  --from-beginning

```

## Stopping the System

```powershell
# Stop all services
docker-compose down

# Stop and remove all data
docker-compose down -v

```

## Troubleshooting

### Services won't start

```powershell
# Check logs
docker-compose logs passenger-service

# Restart specific service
docker-compose restart passenger-service

```

### Port conflicts

```powershell
# Check what's using ports
netstat -ano | findstr ":9090"

# Kill process
taskkill /PID <PID> /F

```

### Reset everything

```powershell
docker-compose down -v
docker system prune -f
docker-compose up -d

```

## Architecture Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Passenger  │────▶│  Ticketing  │────▶│   Payment   │
│   Service   │     │   Service   │     │   Service   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                     │
       │                   ▼                     │
       │            ┌─────────────┐             │
       └───────────▶│    Kafka    │◀────────────┘
                    └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Notification│
                    │   Service   │
                    └─────────────┘

┌─────────────┐     ┌─────────────┐
│  Transport  │     │    Admin    │
│   Service   │     │   Service   │
└─────────────┘     └─────────────┘
       │                   │
       └────────┬──────────┘
                ▼
         ┌─────────────┐
         │   MongoDB   │
         └─────────────┘

```

## Technologies Used

- **Ballerina** - Service implementation
- **Apache Kafka** - Message broker
- **MongoDB** - NoSQL database
- **Docker** - Containerization
- **Docker Compose** - Orchestration
- ** Docker component
