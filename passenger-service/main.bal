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

service / on passengerListener {

    resource function post register(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is json {
            User|error user = payload.cloneWithType(User);
            if user is User {
                // Find existing user by email
                map<json> filter = { "email": user.email };
                stream<map<json>, error?> existingStream = check mongoClient->find(
                    "transportDB", "users", filter
                );
                map<json>[] existing = [];
                error? e = existingStream.forEach(function(map<json> u) {
                    existing.push(u);
                });
                if existing.length() > 0 {
                    http:Response res = new;
                    res.statusCode = 409;
                    res.setPayload({ message: "User already exists" });
                    check caller->respond(res);
                    return;
                }
                // Insert new user
                map<json> userDoc = {
                    "name": user.name,
                    "email": user.email,
                    "password": user.password
                };
                check mongoClient->insert("transportDB", "users", userDoc);
                http:Response res = new;
                res.statusCode = 201;
                res.setPayload({ message: "User registered successfully" });
                check caller->respond(res);

            } else {
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload({ message: "Invalid or missing fields" });
                check caller->respond(res);
            }
        } else {
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload({ message: "Invalid or missing fields" });
            check caller->respond(res);
        }
    }

