import ballerina/http;
import ballerina/log;
import ballerinax/mongodb;
import ballerinax/kafka;
import ballerina/time;

configurable string mongoHost = ?;
configurable string kafkaBootstrap = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

kafka:Producer kafkaProducer = check new (kafkaBootstrap, {
    clientId: "admin-producer"
});

// Define Payment record type
type Payment record {|
    string paymentId;
    string ticketId;
    string userId;
    decimal amount;
    string status;
    string paymentMethod;
    time:Utc createdAt;
    time:Utc? processedAt;
|};

service /admin on new http:Listener(9093) {

    // Get sales report
    resource function get reports/sales() returns json|error {

        log:printInfo("Generating sales report");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");
        mongodb:Collection payments = check db->getCollection("payments");

        // Count total tickets
        int totalTickets = check tickets->countDocuments({});

        // Count successful payments
        int successfulPayments = check payments->countDocuments({status: "SUCCESS"});

        // Calculate total revenue using Payment record type
        stream<Payment, error?> paymentStream = check payments->find({status: "SUCCESS"});
        decimal totalRevenue = 0.0d;

        check from Payment payment in paymentStream
            do {
                totalRevenue += payment.amount;
            };

        log:printInfo("Sales report generated");

        return {
            "totalTickets": totalTickets,
            "successfulPayments": successfulPayments,
            "totalRevenue": totalRevenue,
            "generatedAt": time:utcNow()
        };
    }

    // Publish service disruption - FIXED VERSION
    resource function post disruptions(@http:Payload json disruptionData) returns json|error {

        log:printInfo("Publishing service disruption");

        string routeId = check disruptionData.routeId;
        string message = check disruptionData.message;
        string severity = check disruptionData.severity;

        // 1. Publish to Kafka for Transport Service and other consumers
        json notification = {
            "type": "DISRUPTION",
            "routeId": routeId,
            "message": message,
            "severity": severity,
            "timestamp": time:utcNow()
        };

        check kafkaProducer->send({
            topic: "schedule.updates",
            value: notification.toJsonString().toBytes()
        });

        log:printInfo("Disruption published to Kafka");

        // 2. ✅ NEW: Call Notification Service directly to broadcast to all passengers
        http:Client notificationClient = check new ("http://notification-service:9095");
        
        json disruptionPayload = {
            "routeId": routeId,
            "message": message,
            "severity": severity
        };
        
        http:Response|error notifResponse = notificationClient->post("/disruptions", disruptionPayload);
        
        if notifResponse is http:Response {
            if notifResponse.statusCode == 200 {
                json|error notifResult = notifResponse.getJsonPayload();
                if notifResult is json {
                    log:printInfo(string `Disruption notifications sent to passengers: ${notifResult.toJsonString()}`);
                }
            } else {
                log:printWarn(string `Notification service returned status: ${notifResponse.statusCode}`);
            }
        } else {
            log:printError(string `Error calling notification service: ${notifResponse.message()}`);
        }

        log:printInfo("Disruption published successfully");

        return {
            "success": true,
            "message": "Disruption notification sent to all passengers",
            "routeId": routeId,
            "severity": severity
        };
    }

    // System health check
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcNow()
        };
    }
}