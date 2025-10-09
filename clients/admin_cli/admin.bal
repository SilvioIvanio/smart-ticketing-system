import ballerina/io;
import ballerina/http;
import ballerina/regex;

// Client endpoints for the services
final http:Client transportService = check new ("http://localhost:9094");
final http:Client adminService = check new ("http://localhost:9093");

public function main() returns error? {
    io:println("=================================================");
    io:println("Smart Ticketing System - Admin CLI");
    io:println("=================================================");

    boolean running = true;
    while running {
        io:println("\nAvailable commands:");
        io:println("  1. create_route       - Create a new transport route");
        io:println("  2. create_trip        - Create a new trip for a route");
        io:println("  3. sales_report       - Generate a sales report");
        io:println("  4. publish_disruption - Publish a service disruption alert");
        io:println("  5. exit               - Exit the application");
        io:print("\nEnter command: ");

        string? command = io:readln();

        if command is string {
            match command.trim() {
                "create_route" => {
                    check handleCreateRoute();
                }
                "create_trip" => {
                    check handleCreateTrip();
                }
                "sales_report" => {
                    check handleSalesReport();
                }
                "publish_disruption" => {
                    check handlePublishDisruption();
                }
                "exit" => {
                    running = false;
                    io:println("Exiting Admin CLI. Goodbye!");
                }
                _ => {
                    io:println("Unknown command. Please try again.");
                }
            }
        } else {
            io:println("Invalid input. Please try again.");
        }
    }
    return;
}

function handleCreateRoute() returns error? {
    io:println("\n--- Create New Transport Route ---");
    io:print("Enter route name: ");
    string? name = io:readln();
    io:print("Enter route type (e.g., bus, train): ");
    string? routeType = io:readln();
    io:print("Enter stops (comma-separated, e.g., 'Stop A,Stop B'): ");
    string? stopsStr = io:readln();

    if name is string && routeType is string && stopsStr is string {
        string[] stops = regex:split(stopsStr, ",").map(s => s.trim());
        // For simplicity, schedule is hardcoded. In a real app, this would be user input.
        json schedule = {
            "weekdays": ["08:00", "17:00"],
            "weekends": ["10:00"]
        };
        json routePayload = {
            "name": name,
            "routeType": routeType,
            "stops": stops,
            "schedule": schedule
        };
        do {
            http:Response routeResponse = check transportService->post("/transport/routes", routePayload);
            json responseJson = check routeResponse.getJsonPayload();
            io:println("Route creation successful:");
            io:println(responseJson.toJsonString());
        } on fail error err {
            io:println(string`Error creating route: ${err.message()}`);
        }
    } else {
        io:println("All fields are required for route creation.");
    }
}

function handleCreateTrip() returns error? {
    io:println("\n--- Create New Trip ---");
    io:print("Enter Route ID: ");
    string? routeId = io:readln();
    io:print("Enter Departure Time (YYYY-MM-DDTHH:MM:SSZ, e.g., 2024-12-20T08:00:00Z): ");
    string? departureTime = io:readln();
    io:print("Enter Arrival Time (YYYY-MM-DDTHH:MM:SSZ, e.g., 2024-12-20T09:30:00Z): ");
    string? arrivalTime = io:readln();
    io:print("Enter Vehicle ID: ");
    string? vehicleId = io:readln();

    if routeId is string && departureTime is string && arrivalTime is string && vehicleId is string {
        json tripPayload = {
            "routeId": routeId,
            "departureTime": departureTime,
            "arrivalTime": arrivalTime,
            "vehicleId": vehicleId
        };
        do {
            http:Response tripResponse = check transportService->post("/transport/trips", tripPayload);
            json responseJson = check tripResponse.getJsonPayload();
            io:println("Trip creation successful:");
            io:println(responseJson.toJsonString());
        } on fail error err {
            io:println(string`Error creating trip: ${err.message()}`);
        }
    } else {
        io:println("All fields are required for trip creation.");
    }
}

function handleSalesReport() returns error? {
    io:println("\n--- Generate Sales Report ---");
    do {
        http:Response salesReportResponse = check adminService->get("/admin/reports/sales");
        json responseJson = check salesReportResponse.getJsonPayload();
        io:println("Sales Report:");
        io:println(responseJson.toJsonString());
    } on fail error err {
        io:println(string`Error generating sales report: ${err.message()}`);
    }
}

function handlePublishDisruption() returns error? {
    io:println("\n--- Publish Service Disruption ---");
    io:print("Enter Route ID for disruption: ");
    string? routeId = io:readln();
    io:print("Enter disruption message: ");
    string? message = io:readln();
    io:print("Enter severity (e.g., LOW, MEDIUM, HIGH): ");
    string? severity = io:readln();

    if routeId is string && message is string && severity is string {
        json disruptionPayload = {
            "routeId": routeId,
            "message": message,
            "severity": severity
        };
        do {
            http:Response disruptionResponse = check adminService->post("/admin/disruptions", disruptionPayload);
            json responseJson = check disruptionResponse.getJsonPayload();
            io:println("Disruption published successfully:");
            io:println(responseJson.toJsonString());
        } on fail error err {
            io:println(string`Error publishing disruption: ${err.message()}`);
        }
    } else {
        io:println("All fields are required for publishing a disruption.");
    }
}