import ballerina/http;
import ballerinax/mongodb;

// ================== MongoDB Client ===================
mongodb:ConnectionConfig mongoConfig = {
    host: "localhost",
    port: 27017,
    connection: {}
};
mongodb:Client mongoClient = check new (mongoConfig);

// ================== Transport Service ===================
service /transport on new http:Listener(8080) {

    // Endpoint: POST /routes
    resource function post routes(@http:Payload json routeData) returns json|error {
        check mongoClient->insertOne("routes", routeData);

        return { message: "Route added successfully", route: routeData };
}
}