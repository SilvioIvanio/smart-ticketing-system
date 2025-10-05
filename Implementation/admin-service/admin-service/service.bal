import ballerina/http;
import ballerinax/kafka;

// ================== Kafka Producer ===================
kafka:Producer kafkaProducer = check new (kafka:PRODUCER_CONFIG {
    bootstrapServers: "localhost:9092"
});

// ================== Admin Service ===================
service /admin on new http:Listener(8080) {

    // Endpoint: POST /disruptions
    resource function post disruptions(@http:Payload json disruptionData) returns json|error {

        // Example payload matches contract
        // {
        //   "eventType": "TRIP_DELAYED" |  "TRIP_CANCELLED",
        //   "tripId": "string",
        //   "details": "string"
        // }

        check kafkaProducer->send({
            topic: "schedule.events",
            value: disruptionData.toJsonString()
        });

        return { message: "Disruption reported and event published", disruption: disruptionData };
    }
}
