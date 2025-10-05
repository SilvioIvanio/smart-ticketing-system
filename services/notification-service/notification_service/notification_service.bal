import ballerina/log;
import ballerina/io;
import ballerinax/kafka;

configurable string kafkaBootstrap = ?;

// Separate listener for schedule updates
listener kafka:Listener scheduleListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["schedule.updates"]
});

// Separate listener for ticket validations
listener kafka:Listener validationListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["ticket.validated"]
});

// Separate listener for payments
listener kafka:Listener paymentListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["payments.processed"]
});

// Service for schedule updates
service kafka:Service on scheduleListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendScheduleNotification(payload);
        }
    }
}

// Service for ticket validations
service kafka:Service on validationListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendValidationNotification(payload);
        }
    }
}

// Service for payments
service kafka:Service on paymentListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendPaymentNotification(payload);
        }
    }
}

// Send schedule update notification
function sendScheduleNotification(json data) returns error? {
    string tripId = check data.tripId;
    string status = check data.status;

    string message = string `🚌 Trip ${tripId} is now ${status}`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
}

// Send ticket validation notification
function sendValidationNotification(json data) returns error? {
    string ticketId = check data.ticketId;

    string message = string `✅ Ticket ${ticketId} validated successfully`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
}

// Send payment notification
function sendPaymentNotification(json data) returns error? {
    string ticketId = check data.ticketId;
    string status = check data.status;

    string emoji = status == "SUCCESS" ? "💳" : "❌";
    string message = string `${emoji} Payment for ticket ${ticketId}: ${status}`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
}