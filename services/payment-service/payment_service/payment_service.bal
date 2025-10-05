import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerinax/mongodb;
import ballerinax/kafka;
import ballerina/lang.runtime;

configurable string kafkaBootstrap = ?;
configurable string mongoHost = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

kafka:Producer kafkaProducer = check new (kafkaBootstrap, {
    clientId: "payment-producer",
    acks: "all",
    retryCount: 3
});

// Listen for ticket requests
listener kafka:Listener ticketListener = check new (kafkaBootstrap, {
    groupId: "payment-service-group",
    topics: ["ticket.requests"]
});

service kafka:Service on ticketListener {

    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:ConsumerRecord[] records) returns error? {

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection payments = check db->getCollection("payments");

        foreach var record in records {
            json payload = check string:fromBytes(record.value).fromJsonString();

            string ticketId = check payload.ticketId;
            string userId = check payload.userId;
            decimal price = check payload.price;

            log:printInfo("Processing payment for ticket: " + ticketId);

            // Create payment record
            string paymentId = uuid:createType1AsString();

            Payment payment = {
                paymentId: paymentId,
                ticketId: ticketId,
                userId: userId,
                amount: price,
                status: "PENDING",
                paymentMethod: "card",
                createdAt: time:utcNow(),
                processedAt: ()
            };

            check payments->insertOne(payment);

            // Simulate payment processing (2 seconds)
            runtime:sleep(2);

            // Simulate payment (95% success rate)
            boolean success = simulatePayment();
            string finalStatus = success ? "SUCCESS" : "FAILED";

            // Update payment
            check payments->updateOne(
                {paymentId: paymentId},
                {
                    "$set": {
                        "status": finalStatus,
                        "processedAt": time:utcNow()
                    }
                }
            );

            // Notify ticketing service
            json result = {
                "paymentId": paymentId,
                "ticketId": ticketId,
                "status": finalStatus,
                "timestamp": time:utcNow()
            };

            check kafkaProducer->send({
                topic: "payments.processed",
                value: result.toJsonString().toBytes()
            });

            log:printInfo(string `Payment ${paymentId}: ${finalStatus}`);
        }
    }
}

// Simulate payment processing (95% success)
function simulatePayment() returns boolean {
    int random = <int>(time:utcNow()[0] % 100);
    return random < 95;
}
