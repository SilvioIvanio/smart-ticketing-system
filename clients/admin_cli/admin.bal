import ballerina/io;
import ballerina/http;
import ballerina/json;
import ballerina/time;

// Client endpoints for the services
final http:Client transportService = check new ("http://localhost:9094"); // Note: Readme says 9094, docker-compose says 9092 for transport-service internal, but exposed as 9094
final http:Client adminService = check new ("http://localhost:9093");

public function main() returns error? {
    io:println("=================================================");
    io:println("Smart Ticketing System - Admin CLI");
    io:println("=================================================");
    io:println("");

    // --- Create a Bus Route ---
    io:println("1️⃣  CREATING A BUS ROUTE");
    io:println("-------------------------------------------------");
    json routePayload = {
        "name": "Route 101 - City Center Loop",
        "routeType": "bus",
        "stops": ["Main Station", "City Hall", "Park Avenue", "Shopping Mall", "Main Station"],
        "schedule": {
            "weekdays": ["06:00", "07:00", "08:00", "09:00", "17:00", "18:00", "19:00"],
            "weekends": ["08:00", "10:00", "14:00", "18:00"]
        }
    };
    http:Response routeResponse = check transportService->post("/transport/routes", routePayload);
    json routeJson = check routeResponse.getJson();
    io:println(routeJson.toJsonString());
    string routeId = check routeJson.routeId.ensureType();
    io:println("");
    io:println(string`🚌 Created Route ID: ${routeId}`);
    io:println("");

    // --- Create a Trip ---
    io:println("2️⃣  CREATING A TRIP");
    io:println("-------------------------------------------------");
    json tripPayload = {
        "routeId": routeId,
        "departureTime": "2024-12-20T08:00:00Z",
        "arrivalTime": "2024-12-20T09:30:00Z",
        "vehicleId": "BUS-101"
    };
    http:Response tripResponse = check transportService->post("/transport/trips", tripPayload);
    json tripJson = check tripResponse.getJson();
    io:println(tripJson.toJsonString());
    string tripId = check tripJson.tripId.ensureType();
    io:println("");
    io:println(string`🚍 Created Trip ID: ${tripId}`);
    io:println("");

    // --- Generate Admin Sales Report ---
    io:println("3️⃣  GENERATING ADMIN SALES REPORT");
    io:println("-------------------------------------------------");
    http:Response salesReportResponse = check adminService->get("/admin/reports/sales");
    io:println(check salesReportResponse.getJson().toJsonString());
    io:println("");

    // --- Publish Service Disruption ---
    io:println("4️⃣  PUBLISHING SERVICE DISRUPTION");
    io:println("-------------------------------------------------");
    json disruptionPayload = {
        "routeId": routeId,
        "message": "Route 101 is experiencing delays due to heavy traffic.",
        "severity": "HIGH"
    };
    http:Response disruptionResponse = check adminService->post("/admin/disruptions", disruptionPayload);
    io:println(check disruptionResponse.getJson().toJsonString());
    io:println("");

    io:println("=================================================");
    io:println("Admin CLI interactions complete.");
    io:println("=================================================");

    return nil;
}
