import ballerina/io;
import ballerina/http;
import ballerina/json;

// Client endpoints for the services
final http:Client passengerService = check new ("http://localhost:9090");
final http:Client ticketingService = check new ("http://localhost:9091");

public function main() returns error? {
    io:println("=================================================");
    io:println("Smart Ticketing System - Passenger CLI");
    io:println("=================================================");
    io:println("");

    // --- Passenger Registration ---
    io:println("1️⃣  REGISTERING A NEW PASSENGER");
    io:println("-------------------------------------------------");
    json registerPayload = {
        "username": "Jane Doe",
        "email": "jane@example.com",
        "password": "SecurePassword456"
    };
    http:Response registerResponse = check passengerService->post("/passenger/register", registerPayload);
    io:println("✅ Registration complete");
    io:println(check registerResponse.getJson().toJsonString());
    io:println("");

    // --- Passenger Login ---
    io:println("2️⃣  LOGGING IN");
    io:println("-------------------------------------------------");
    json loginPayload = {
        "email": "jane@example.com",
        "password": "SecurePassword456"
    };
    http:Response loginResponse = check passengerService->post("/passenger/login", loginPayload);
    json loginJson = check loginResponse.getJson();
    io:println(loginJson.toJsonString());
    string userId = check loginJson.userId.ensureType();
    io:println("");
    io:println(string`👤 Logged in User ID: ${userId}`);
    io:println("");

    // --- Purchasing a Ticket ---
    // In a real scenario, the passenger app might query available routes/trips.
    // For this demo, we'll use a dummy trip ID.
    string dummyTripId = "TRIP-12345"; // This would typically come from the Transport Service

    io:println("3️⃣  PURCHASING A TICKET (using a dummy trip ID)");
    io:println("-------------------------------------------------");
    json ticketPayload = {
        "userId": userId,
        "tripId": dummyTripId,
        "ticketType": "single",
        "price": 7.50
    };
    http:Response ticketResponse = check ticketingService->post("/ticketing/tickets", ticketPayload);
    json ticketJson = check ticketResponse.getJson();
    io:println(ticketJson.toJsonString());
    string ticketId = check ticketJson.ticketId.ensureType();
    io:println("");
    io:println(string`🎫 Purchased Ticket ID: ${ticketId}`);
    io:println("");

    // --- Checking User's Tickets ---
    io:println("4️⃣  CHECKING USER'S TICKETS");
    io:println("-------------------------------------------------");
    http:Response userTicketsResponse = check passengerService->get(string`/passenger/tickets/${userId}`);
    io:println(check userTicketsResponse.getJson().toJsonString());
    io:println("");

    io:println("=================================================");
    io:println("Passenger CLI interactions complete.");
    io:println("=================================================");

    return nil;
}
