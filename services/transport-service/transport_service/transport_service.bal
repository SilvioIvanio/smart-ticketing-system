import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerinax/mongodb;
import ballerinax/kafka;

configurable string mongoHost = ?;
configurable string kafkaBootstrap = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

kafka:Producer kafkaProducer = check new (kafkaBootstrap, {
    clientId: "transport-producer"
});

service /transport on new http:Listener(9092) {

    // Create a new route
    resource function post routes(@http:Payload json routeData)
            returns json|error {

        log:printInfo("Creating new route");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection routes = check db->getCollection("routes");

        string routeId = uuid:createType1AsString();

        // FIX: Properly convert JSON fields to their types
        string[] stopsArray = check (check routeData.stops).cloneWithType();
        json scheduleJson = check routeData.schedule;
        
        Route newRoute = {
            routeId: routeId,
            name: check routeData.name,
            routeType: check routeData.routeType,
            stops: stopsArray,
            schedule: scheduleJson,
            active: true,
            createdAt: time:utcNow()
        };

        check routes->insertOne(newRoute);

        log:printInfo("Route created: " + routeId);

        return {
            "routeId": routeId,
            "message": "Route created successfully"
        };
    }

    // Get all active routes
    resource function get routes() returns Route[]|error {

        log:printInfo("Fetching all routes");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection routes = check db->getCollection("routes");

        stream<Route, error?> routeStream = check routes->find({active: true});
        return check from Route r in routeStream select r;
    }

    // Create a trip
    resource function post trips(@http:Payload json tripData)
            returns json|error {

        log:printInfo("Creating new trip");

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection trips = check db->getCollection("trips");

        string tripId = uuid:createType1AsString();

        Trip newTrip = {
            tripId: tripId,
            routeId: check tripData.routeId,
            departureTime: check time:utcFromString(check tripData.departureTime),
            arrivalTime: check time:utcFromString(check tripData.arrivalTime),
            status: "ON_TIME",
            vehicleId: check tripData.vehicleId,
            createdAt: time:utcNow()
        };

        check trips->insertOne(newTrip);

        log:printInfo("Trip created: " + tripId);

        return {
            "tripId": tripId,
            "message": "Trip created successfully"
        };
    }

    // Update trip status
    resource function put trips/[string tripId]/status(@http:Payload json statusData)
            returns json|http:NotFound|error {

        log:printInfo("Updating trip status: " + tripId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection trips = check db->getCollection("trips");

        mongodb:UpdateResult result = check trips->updateOne(
            {tripId: tripId},
            {"$set": {"status": check statusData.status}}
        );

        if result.modifiedCount == 0 {
            return http:NOT_FOUND;
        }

        // Publish update to Kafka
        json update = {
            "tripId": tripId,
            "routeId": check statusData.routeId,
            "status": check statusData.status,
            "timestamp": time:utcNow()
        };

        check kafkaProducer->send({
            topic: "schedule.updates",
            value: update.toJsonString().toBytes()
        });

        log:printInfo("Trip status updated");

        return {
            "success": true,
            "message": "Trip status updated"
        };
    }

    // Get trips for a route
    resource function get trips/route/[string routeId]() returns Trip[]|error {

        log:printInfo("Fetching trips for route: " + routeId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection trips = check db->getCollection("trips");

        stream<Trip, error?> tripStream = check trips->find({routeId: routeId});
        return check from Trip t in tripStream select t;
    }
}
