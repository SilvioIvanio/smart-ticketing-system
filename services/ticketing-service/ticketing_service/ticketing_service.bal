import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerinax/mongodb;
import ballerinax/kafka;

configurable string kafkaBootstrap = ?;
configurable string mongoHost = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

kafka:Producer kafkaProducer = check new (kafkaBootstrap, {
    clientId: "ticketing-producer",
    acks: "all",
    retryCount: 3
});

service /ticketing on new http:Listener(9091) {

    resource function post tickets(@http:Payload json ticketData)
            returns json|error {

        log:printInfo("Creating new ticket");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        string ticketId = uuid:createType1AsString();
        string ticketType = check ticketData.ticketType;

        int rides = ticketType == "single" ? 1 : (ticketType == "multi" ? 10 : 30);

        Ticket newTicket = {
            ticketId: ticketId,
            userId: check ticketData.userId,
            tripId: check ticketData.tripId,
            ticketType: ticketType,
            status: "CREATED",
            price: check ticketData.price,
            validFrom: time:utcNow(),
            validUntil: time:utcAddSeconds(time:utcNow(), 86400),
            ridesRemaining: rides,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        check tickets->insertOne(newTicket);

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

    // ADDED: New endpoint for path-based validation
    resource function post tickets/[string ticketId]/validate() returns json|error {

        log:printInfo("Validating ticket: " + ticketId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        stream<Ticket, error?> ticketStream = check tickets->find({ticketId: ticketId});
        Ticket[]? foundTickets = check from Ticket t in ticketStream select t;

        if foundTickets is () || foundTickets.length() == 0 {
            log:printWarn("Ticket not found: " + ticketId);
            return {
                "success": false,
                "error": "Ticket not found"
            };
        }

        Ticket ticket = foundTickets[0];

        if ticket.status != "PAID" && ticket.status != "VALIDATED" {
            log:printWarn("Ticket not paid: " + ticketId);
            return {
                "success": false,
                "error": "Ticket must be paid before validation",
                "currentStatus": ticket.status
            };
        }

        time:Utc now = time:utcNow();
        decimal diff = time:utcDiffSeconds(ticket.validUntil, now);

        if diff < 0d {
            log:printWarn("Ticket expired: " + ticketId);
            
            _ = check tickets->updateOne(
                {ticketId: ticketId},
                {"$set": {"status": "EXPIRED", "updatedAt": now}}
            );
            
            return {
                "success": false,
                "error": "Ticket has expired",
                "expiredAt": ticket.validUntil
            };
        }

        int remaining = ticket.ridesRemaining ?: 0;
        if remaining <= 0 {
            log:printWarn("No rides remaining: " + ticketId);
            return {
                "success": false,
                "error": "No rides remaining on this ticket"
            };
        }

        int newRemaining = remaining - 1;
        string newStatus = newRemaining > 0 ? "VALIDATED" : "EXPIRED";

        _ = check tickets->updateOne(
            {ticketId: ticketId},
            {
                "$set": {
                    "ridesRemaining": newRemaining,
                    "status": newStatus,
                    "updatedAt": now
                }
            }
        );

        json validationEvent = {
            "ticketId": ticketId,
            "userId": ticket.userId,
            "status": "VALIDATED",
            "timestamp": now
        };

        check kafkaProducer->send({
            topic: "ticket.validated",
            value: validationEvent.toJsonString().toBytes()
        });

        log:printInfo("Ticket validated: " + ticketId);

        return {
            "success": true,
            "ticketId": ticketId,
            "ridesRemaining": newRemaining,
            "status": newStatus,
            "message": "Ticket validated successfully"
        };
    }

    // Keep the old validate endpoint for backward compatibility
    resource function post validate(@http:Payload TicketValidation validation)
            returns json|http:BadRequest|error {

        log:printInfo("Validating ticket: " + validation.ticketId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        stream<Ticket, error?> ticketStream = check tickets->find({ticketId: validation.ticketId});
        Ticket[]? foundTickets = check from Ticket t in ticketStream select t;

        if foundTickets is () || foundTickets.length() == 0 {
            log:printWarn("Ticket not found: " + validation.ticketId);
            return http:BAD_REQUEST;
        }

        Ticket ticket = foundTickets[0];

        if ticket.status != "PAID" && ticket.status != "VALIDATED" {
            log:printWarn("Ticket not paid: " + validation.ticketId);
            return {
                "error": "Ticket must be paid before validation",
                "currentStatus": ticket.status
            };
        }

        time:Utc now = time:utcNow();
        decimal diff = time:utcDiffSeconds(ticket.validUntil, now);

        if diff < 0d {
            log:printWarn("Ticket expired: " + validation.ticketId);
            
            _ = check tickets->updateOne(
                {ticketId: validation.ticketId},
                {"$set": {"status": "EXPIRED", "updatedAt": now}}
            );
            
            return {
                "error": "Ticket has expired",
                "expiredAt": ticket.validUntil
            };
        }

        int remaining = ticket.ridesRemaining ?: 0;
        if remaining <= 0 {
            log:printWarn("No rides remaining: " + validation.ticketId);
            return {
                "error": "No rides remaining on this ticket"
            };
        }

        int newRemaining = remaining - 1;
        string newStatus = newRemaining > 0 ? "VALIDATED" : "EXPIRED";

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

listener kafka:Listener paymentListener = check new (kafkaBootstrap, {
    groupId: "ticketing-service-group",
    topics: ["payments.processed"]
});

service kafka:Service on paymentListener {

    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:BytesConsumerRecord[] records) returns error? {

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        foreach var rec in records {
            string payloadStr = check string:fromBytes(rec.value);
            json payload = check payloadStr.fromJsonString();

            string ticketId = check payload.ticketId;
            string status = check payload.status;

            log:printInfo("Received payment notification for ticket: " + ticketId);

            if status == "SUCCESS" {
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