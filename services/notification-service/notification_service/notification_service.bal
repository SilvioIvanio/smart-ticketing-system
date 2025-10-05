import ballerina/log;
import ballerina/io;
import ballerinax/kafka;

configurable string kafkaBootstrap = ?;

// Listen to multiple topics
listener kafka:Listener notificationListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["schedule.updates", "ticket.validated", "payments.processed"]
});

service kafka:Service on notificationListener {

    // FIX 1: Use BytesConsumerRecord instead of ConsumerRecord
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:BytesConsumerRecord[] records) returns error? {

        // FIX 2: Change 'record' to 'rec' (record is a reserved keyword)
        foreach var rec in records {
            // FIX 3: Split string conversion into two steps
            string payloadStr = check string:fromBytes(rec.value);
            json payload = check payloadStr.fromJsonString();
            string topic = rec.topic;

            // Route to appropriate notification handler
            match topic {
                "schedule.updates" => {
                    check sendScheduleNotification(payload);
                }
                "ticket.validated" => {
                    check sendValidationNotification(payload);
                }
                "payments.processed" => {
                    check sendPaymentNotification(payload);
                }
            }
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