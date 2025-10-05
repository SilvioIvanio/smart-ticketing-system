#!/bin/bash

echo "================================================"
echo "Smart Ticketing System - Integration Test"
echo "================================================"
echo ""

# Wait for services to start
echo "⏳ Waiting for services to be ready..."
sleep 15

echo ""
echo "1️⃣  REGISTERING A NEW PASSENGER"
echo "------------------------------------------------"
REGISTER_RESPONSE=$(curl -s -X POST <http://localhost:9090/passenger/register> \\
  -H "Content-Type: application/json" \\
  -d '{
    "username": "Alice Johnson",
    "email": "alice@example.com",
    "password": "SecurePass123"
  }')

echo "✅ Registration complete"
echo ""

echo "2️⃣  LOGGING IN"
echo "------------------------------------------------"
LOGIN_RESPONSE=$(curl -s -X POST <http://localhost:9090/passenger/login> \\
  -H "Content-Type: application/json" \\
  -d '{
    "email": "alice@example.com",
    "password": "SecurePass123"
  }')

echo "$LOGIN_RESPONSE" | jq '.'
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.userId')
echo ""
echo "👤 User ID: $USER_ID"
echo ""

echo "3️⃣  CREATING A BUS ROUTE"
echo "------------------------------------------------"
ROUTE_RESPONSE=$(curl -s -X POST <http://localhost:9092/transport/routes> \\
  -H "Content-Type: application/json" \\
  -d '{
    "name": "Route 101 - City Center Loop",
    "routeType": "bus",
    "stops": ["Main Station", "City Hall", "Park Avenue", "Shopping Mall", "Main Station"],
    "schedule": {
      "weekdays": ["06:00", "07:00", "08:00", "09:00", "17:00", "18:00", "19:00"],
      "weekends": ["08:00", "10:00", "14:00", "18:00"]
    }
  }')

echo "$ROUTE_RESPONSE" | jq '.'
ROUTE_ID=$(echo "$ROUTE_RESPONSE" | jq -r '.routeId')
echo ""
echo "🚌 Route ID: $ROUTE_ID"
echo ""

echo "4️⃣  CREATING A TRIP"
echo "------------------------------------------------"
TRIP_RESPONSE=$(curl -s -X POST <http://localhost:9092/transport/trips> \\
  -H "Content-Type: application/json" \\
  -d "{
    \\"routeId\\": \\"$ROUTE_ID\\",
    \\"departureTime\\": \\"2024-12-20T08:00:00Z\\",
    \\"arrivalTime\\": \\"2024-12-20T09:30:00Z\\",
    \\"vehicleId\\": \\"BUS-101\\"
  }")

echo "$TRIP_RESPONSE" | jq '.'
TRIP_ID=$(echo "$TRIP_RESPONSE" | jq -r '.tripId')
echo ""
echo "🚍 Trip ID: $TRIP_ID"
echo ""

echo "5️⃣  PURCHASING A TICKET"
echo "------------------------------------------------"
TICKET_RESPONSE=$(curl -s -X POST <http://localhost:9091/ticketing/tickets> \\
  -H "Content-Type: application/json" \\
  -d "{
    \\"userId\\": \\"$USER_ID\\",
    \\"tripId\\": \\"$TRIP_ID\\",
    \\"ticketType\\": \\"single\\",
    \\"price\\": 5.50
  }")

echo "$TICKET_RESPONSE" | jq '.'
TICKET_ID=$(echo "$TICKET_RESPONSE" | jq -r '.ticketId')
echo ""
echo "🎫 Ticket ID: $TICKET_ID"
echo ""

echo "⏳ Waiting for payment processing (5 seconds)..."
sleep 5
echo ""

echo "6️⃣  CHECKING TICKET STATUS"
echo "------------------------------------------------"
TICKET_STATUS=$(curl -s <http://localhost:9091/ticketing/tickets/$TICKET_ID>)
echo "$TICKET_STATUS" | jq '.'
echo ""

echo "7️⃣  VALIDATING TICKET (Passenger boards bus)"
echo "------------------------------------------------"
VALIDATION_RESPONSE=$(curl -s -X POST <http://localhost:9091/ticketing/validate> \\
  -H "Content-Type: application/json" \\
  -d "{
    \\"ticketId\\": \\"$TICKET_ID\\",
    \\"validatorId\\": \\"VALIDATOR-001\\",
    \\"validatedAt\\": \\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\\"
  }")

echo "$VALIDATION_RESPONSE" | jq '.'
echo ""

echo "8️⃣  CHECKING USER'S TICKETS"
echo "------------------------------------------------"
USER_TICKETS=$(curl -s <http://localhost:9090/passenger/tickets/$USER_ID>)
echo "$USER_TICKETS" | jq '.'
echo ""

echo "9️⃣  UPDATING TRIP STATUS (Simulating delay)"
echo "------------------------------------------------"
STATUS_UPDATE=$(curl -s -X PUT <http://localhost:9092/transport/trips/$TRIP_ID/status> \\
  -H "Content-Type: application/json" \\
  -d "{
    \\"routeId\\": \\"$ROUTE_ID\\",
    \\"status\\": \\"DELAYED\\"
  }")

echo "$STATUS_UPDATE" | jq '.'
echo ""

echo "🔟 GENERATING ADMIN SALES REPORT"
echo "------------------------------------------------"
SALES_REPORT=$(curl -s <http://localhost:9093/admin/reports/sales>)
echo "$SALES_REPORT" | jq '.'
echo ""

echo "================================================"
echo "✅ ALL TESTS COMPLETED SUCCESSFULLY!"
echo "================================================"
