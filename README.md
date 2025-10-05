# Smart Public Transport Ticketing System

## Quick Start

### Deploy System
```powershell
docker-compose up -d

```

### Run Demo

```powershell
Start-Sleep -Seconds 30
.\\demo.ps1

```

### Check Status

```powershell
docker-compose ps
docker-compose logs -f

```

### Stop System

```powershell
docker-compose down

```

## Architecture

- **6 Microservices** in Docker containers
- **Kafka** for event-driven messaging
- **MongoDB** for data persistence
- **Docker Compose** for orchestration

## Services

- Passenger Service: [http://localhost:9090](http://localhost:9090/)
- Ticketing Service: [http://localhost:9091](http://localhost:9091/)
- Transport Service: [http://localhost:9092](http://localhost:9092/)
- Admin Service: [http://localhost:9093](http://localhost:9093/)