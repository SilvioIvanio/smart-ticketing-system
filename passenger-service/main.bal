import ballerina/http;
import ballerinax/mongodb;

type User record {|
    string name;
    string email;
    string password;
|};

type LoginRequest record {|
    string email;
    string password;
|};

// MongoDB setup
mongodb:Client mongoClient = check new ({
    host: "localhost",
    port: 27017
});

// Kafka REST Proxy setup
final string KAFKA_REST_URL = "http://localhost:8082/topics/new_tickets";
http:Client kafkaProxy = check new(KAFKA_REST_URL);

listener http:Listener passengerListener = new(8080);
