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

    // Publish service disruption
    resource function post disruptions(@http:Payload json disruptionData)
            returns json|error {

        log:printInfo("Publishing service disruption");

        json notification = {
            "type": "DISRUPTION",
            "routeId": check disruptionData.routeId,
            "message": check disruptionData.message,
            "severity": check disruptionData.severity,
            "timestamp": time:utcNow()
        };

        check kafkaProducer->send({
            topic: "schedule.updates",
            value: notification.toJsonString().toBytes()
        });

        log:printInfo("Disruption published");

        return {
            "success": true,
            "message": "Disruption notification sent"
        };
    }

    // System health check
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcNow()
        };
    }
}...
