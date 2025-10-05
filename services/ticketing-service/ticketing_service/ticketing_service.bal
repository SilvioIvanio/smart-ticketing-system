import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerinax/mongodb;
import ballerinax/kafka;

// Configuration
configurable string kafkaBootstrap = ?;
configurable string mongoHost = ?;
configurable string dbName = ?;

// MongoDB client
mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

// Kafka producer (sends messages)
kafka:Producer kafkaProducer = check new (kafkaBootstrap, {
    clientId: "ticketing-producer",
    acks: "all",
    retryCount: 3
});

// HTTP service on port 9091
service /ticketing on new http:Listener(9091) {

    // Endpoint: POST /ticketing/tickets
    // Purpose: Create a new ticket
    resource function post tickets(@http:Payload json ticketData)
            returns json|error {

        log:printInfo("Creating new ticket");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        string ticketId = uuid:createType1AsString();
        string ticketType = check ticketData.ticketType;

        // Determine rides based on ticket type
        int rides = ticketType == "single" ? 1 : (ticketType == "multi" ? 10 : 30);

        Ticket newTicket = {
            ticketId: ticketId,
            userId: check ticketData.userId,
            tripId: check ticketData.tripId,
            ticketType: ticketType,
            status: "CREATED",
            price: check ticketData.price,
            validFrom: time:utcNow(),
            validUntil: time:utcAddSeconds(time:utcNow(), 86400), // 24 hours
            ridesRemaining: rides,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        // Save to database
        check tickets->insertOne(newTicket);

        // Send message to Kafka for payment processing
        TicketRequest request = {
            ticketId: ticketId,
            userId: newTicket.userId,
            tripId: newTicket.tripId,
            ticketType: newTicket.ticketType,
            price: newTicket.price,
            status: "CREATED"
        };

        check kafkaProducer->send({
            topic: "ticket.requests",
            value: request.toJsonString().toBytes()
        });

        log:printInfo("Ticket created: " + ticketId);

        return {
            "ticketId": ticketId,
            "status": "CREATED",
            "message": "Ticket created successfully, payment processing"
        };
    }

    // Endpoint: POST /ticketing/validate
    // Purpose: Validate a ticket when passenger boards
    resource function post validate(@http:Payload TicketValidation validation)
            returns json|http:BadRequest|error {

        log:printInfo("Validating ticket: " + validation.ticketId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        // Find the ticket
        stream<Ticket, error?> ticketStream = check tickets->find({ticketId: validation.ticketId});
        Ticket[]? foundTickets = check from Ticket t in ticketStream select t;

        if foundTickets is () || foundTickets.length() == 0 {
            log:printWarn("Ticket not found: " + validation.ticketId);
            return http:BAD_REQUEST;
        }

        Ticket ticket = foundTickets[0];

        // Check if ticket is paid
        if ticket.status != "PAID" && ticket.status != "VALIDATED" {
            log:printWarn("Ticket not paid: " + validation.ticketId);
            return {
                "error": "Ticket must be paid before validation",
                "currentStatus": ticket.status
            };
        }

        // Check if expired
        time:Utc now = time:utcNow();
        decimal diff = time:utcDiffSeconds(ticket.validUntil, now);

        // FIX 1: Compare decimal with decimal (0.0d or 0d)
        if diff < 0d {
            log:printWarn("Ticket expired: " + validation.ticketId);
            
            // FIX 2: Assign the result to _ to ignore it
            _ = check tickets->updateOne(
                {ticketId: validation.ticketId},
                {"$set": {"status": "EXPIRED", "updatedAt": now}}
            );
            
            return {
                "error": "Ticket has expired",
                "expiredAt": ticket.validUntil
            };
        }

        // Check remaining rides
        int remaining = ticket.ridesRemaining ?: 0;
        if remaining <= 0 {
            log:printWarn("No rides remaining: " + validation.ticketId);
            return {
                "error": "No rides remaining on this ticket"
            };
        }

        // Update ticket
        int newRemaining = remaining - 1;
        string newStatus = newRemaining > 0 ? "VALIDATED" : "EXPIRED";

        // FIX 3: Assign the result to _ to ignore it
        _ = check tickets->updateOne(
            {ticketId: validation.ticketId},
            {
                "$set": {
                    "ridesRemaining": newRemaining,
                    "status": newStatus,
                    "updatedAt": now
                }
            }
        );

        // Send validation event to Kafka
        check kafkaProducer->send({
            topic: "ticket.validated",
            value: validation.toJsonString().toBytes()
        });

        log:printInfo("Ticket validated: " + validation.ticketId);

        return {
            "success": true,
            "ticketId": validation.ticketId,
            "ridesRemaining": newRemaining,
            "status": newStatus
        };
    }

    // Endpoint: GET /ticketing/tickets/{ticketId}
    // Purpose: Get ticket details
    resource function get tickets/[string ticketId]() returns Ticket|http:NotFound|error {

        log:printInfo("Fetching ticket: " + ticketId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        stream<Ticket, error?> ticketStream = check tickets->find({ticketId: ticketId});
        Ticket[]? foundTickets = check from Ticket t in ticketStream select t;

        if foundTickets is () || foundTickets.length() == 0 {
            return http:NOT_FOUND;
        }

        return foundTickets[0];
    }
}

// Kafka Consumer - listens for payment confirmations
listener kafka:Listener paymentListener = check new (kafkaBootstrap, {
    groupId: "ticketing-service-group",
    topics: ["payments.processed"]
});

service kafka:Service on paymentListener {

    // FIX 4: Add kafka: prefix to ConsumerRecord
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:ConsumerRecord[] records) returns error? {

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        // FIX 5: Changed 'record' to 'rec' (record is a reserved keyword)
        foreach var rec in records {
            // Parse the payment message
            json payload = check string:fromBytes(rec.value).fromJsonString();

            string ticketId = check payload.ticketId;
            string status = check payload.status;

            log:printInfo("Received payment notification for ticket: " + ticketId);

            if status == "SUCCESS" {
                // FIX 6: Assign the result to _ to ignore it
                _ = check tickets->updateOne(
                    {ticketId: ticketId},
                    {"$set": {"status": "PAID", "updatedAt": time:utcNow()}}
                );

                log:printInfo("Ticket marked as PAID: " + ticketId);
            } else {
                log:printWarn("Payment failed for ticket: " + ticketId);
            }
        }
    }
}