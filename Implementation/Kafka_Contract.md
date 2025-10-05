#Kafka Contract - Smart Public Transport Ticket System

<!-- ticket.requests: -->
{"userId":"string",
 "tripId":"string",
 "ticketType":"SINGLE_RIDE"
}


<!-- payment.requests: -->
{"ticketId":"string",
 "amount":"float",
 "userId":"string"
}

<!-- payment.events: -->
{"ticketId":"string",
 "status":"CONFIRMED"|"FAILED",
 "transactionId":"string"
}

<!-- schedule.events: -->
 { "eventType": "TRIP_DELAYED" | "TRIP_CANCELLED", 
"tripId": "string", 
"details": "string" 
}
