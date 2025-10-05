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

        // Calculate total revenue
        stream<json, error?> paymentStream = check payments->find({status: "SUCCESS"});
        decimal totalRevenue = 0.0;

        check from json payment in paymentStream
            do {
                decimal amount = check payment.amount;
                totalRevenue += amount;
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
}
