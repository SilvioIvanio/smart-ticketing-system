# Smart Public Transport Ticketing System - Database Schema(MongoDB collections schema)

# Users Collection, tickets collection and routes collection

```json
{
  "userId": "string",
  "name": "string",
  "email": "string",
  "passwordHash": "string",
  "role": "PASSENGER | ADMIN | VALIDATOR",
  "phone": "string",
  "createdAt": "ISODate"
}

{
  "ticketId": "string",
  "userId": "string",
  "tripId": "string",
  "routeId": "string",
  "status": "CREATED | PAID | VALIDATED | EXPIRED",
  "ticketType": "SINGLE_RIDE | MULTIPLE_RIDE | DAY_PASS | WEEKLY_PASS",
  "price": "decimal",
  "purchaseDate": "ISODate",
  "expiryDate": "ISODate",
  "paymentId": "string"
}

{
  "routeId": "string",
  "name": "string",
  "transportType": "BUS | TRAIN",
  "destination": "string",
  "stops": [
    {
      "stopId": "string",
      "name": "string",
      "sequence": "integer"
    }
  ],
  "trips": [
    {
      "tripId": "string",
      "departureTime": "ISODate",
      "arrivalTime": "ISODate",
      "vehicleId": "string",
      "driverId": "string",
      "availableSeats": "integer",
      "status": "SCHEDULED | ACTIVE | COMPLETED | CANCELLED"
    }
  ],
  "active": "boolean",
  "createdBy": "string",
  "createdAt": "ISODate"
}