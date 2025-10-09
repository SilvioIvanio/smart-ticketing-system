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
        io:println("\n╔════════════════════════════════════════════╗");
        io:println("║          Admin Commands                    ║");
        io:println("╠════════════════════════════════════════════╣");
        io:println("║  1. Create route                           ║");
        io:println("║  2. Create trip                            ║");
        io:println("║  3. Sales report                           ║");
        io:println("║  4. Publish disruption                     ║");
        io:println("║  0. Exit                                   ║");
        io:println("╚════════════════════════════════════════════╝");
        io:print("\n👉 Enter your choice: ");

        string? command = io:readln();

        if command is string {
            match command.trim() {
                "1" => {
                    check handleCreateRoute();
                }
                "2" => {
                    check handleCreateTrip();
                }
                "3" => {
                    check handleSalesReport();
                }
                "4" => {
                    check handlePublishDisruption();
                }
                "0" => {
                    running = false;
                    io:println("\n👋 Exiting Admin CLI. Goodbye!");
                }
                _ => {
                    io:println("❌ Invalid choice. Please enter a valid number.");
                }
            }
        } else {
            io:println("❌ Invalid input. Please try again.");
        }
    }
    return;
}

function handleCreateRoute() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         Create New Route                   ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter route name: ");
    string? name = io:readln();
    io:print("Enter route type (bus/train): ");
    string? routeType = io:readln();
    io:print("Enter stops (comma-separated): ");
    string? stopsStr = io:readln();

    if name is string && routeType is string && stopsStr is string {
        string[] stops = regex:split(stopsStr, ",").map(s => s.trim());
        
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
        
        io:println("\n⏳ Creating route...");
        
        http:Response|error routeResponse = transportService->post("/transport/routes", routePayload);
        
        if routeResponse is http:Response {
            int statusCode = routeResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = routeResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Route created successfully!");
                    io:println(responseJson.toJsonString());
                } else {
                    io:println("✅ Route created successfully!");
                }
            } else {
                string|error payload = routeResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Route creation failed (Status ${statusCode}): ${payload}`);
                } else {
                    io:println(string`❌ Route creation failed with status code: ${statusCode}`);
                }
            }
        } else {
            io:println("❌ Error connecting to Transport Service.");
            io:println("💡 Make sure the service is running on http://localhost:9094");
            io:println(string`Error details: ${routeResponse.message()}`);
        }
    } else {
        io:println("❌ All fields are required for route creation.");
    }
}

function handleCreateTrip() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║           Create New Trip                  ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter Route ID: ");
    string? routeId = io:readln();
    io:print("Enter Departure Time (YYYY-MM-DDTHH:MM:SSZ): ");
    string? departureTime = io:readln();
    io:print("Enter Arrival Time (YYYY-MM-DDTHH:MM:SSZ): ");
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
        
        io:println("\n⏳ Creating trip...");
        
        http:Response|error tripResponse = transportService->post("/transport/trips", tripPayload);
        
        if tripResponse is http:Response {
            int statusCode = tripResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = tripResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Trip created successfully!");
                    io:println(responseJson.toJsonString());
                } else {
                    io:println("✅ Trip created successfully!");
                }
            } else {
                string|error payload = tripResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Trip creation failed (Status ${statusCode}): ${payload}`);
                } else {
                    io:println(string`❌ Trip creation failed with status code: ${statusCode}`);
                }
            }
        } else {
            io:println("❌ Error connecting to Transport Service.");
            io:println("💡 Make sure the service is running on http://localhost:9094");
            io:println(string`Error details: ${tripResponse.message()}`);
        }
    } else {
        io:println("❌ All fields are required for trip creation.");
    }
}

function handleSalesReport() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║          Sales Report                      ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Generating report...");
    
    http:Response|error salesReportResponse = adminService->get("/admin/reports/sales");
    
    if salesReportResponse is http:Response {
        int statusCode = salesReportResponse.statusCode;
        
        if statusCode == 200 {
            json|error responseJson = salesReportResponse.getJsonPayload();
            if responseJson is json {
                io:println("\n✅ Sales Report:");
                io:println(responseJson.toJsonString());
            } else {
                io:println("❌ Invalid response format");
            }
        } else {
            string|error payload = salesReportResponse.getTextPayload();
            if payload is string {
                io:println(string`❌ Failed to generate report (Status ${statusCode}): ${payload}`);
            } else {
                io:println(string`❌ Failed to generate report with status code: ${statusCode}`);
            }
        }
    } else {
        io:println("❌ Error connecting to Admin Service.");
        io:println("💡 Make sure the service is running on http://localhost:9093");
        io:println(string`Error details: ${salesReportResponse.message()}`);
    }
}

function handlePublishDisruption() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║       Publish Disruption                   ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter Route ID: ");
    string? routeId = io:readln();
    io:print("Enter message: ");
    string? message = io:readln();
    io:print("Enter severity (LOW/MEDIUM/HIGH): ");
    string? severity = io:readln();

    if routeId is string && message is string && severity is string {
        json disruptionPayload = {
            "routeId": routeId,
            "message": message,
            "severity": severity
        };
        
        io:println("\n⏳ Publishing disruption...");
        
        http:Response|error disruptionResponse = adminService->post("/admin/disruptions", disruptionPayload);
        
        if disruptionResponse is http:Response {
            int statusCode = disruptionResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = disruptionResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Disruption published successfully!");
                    io:println(responseJson.toJsonString());
                } else {
                    io:println("✅ Disruption published successfully!");
                }
            } else {
                string|error payload = disruptionResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Failed to publish disruption (Status ${statusCode}): ${payload}`);
                } else {
                    io:println(string`❌ Failed to publish disruption with status code: ${statusCode}`);
                }
            }
        } else {
            io:println("❌ Error connecting to Admin Service.");
            io:println("💡 Make sure the service is running on http://localhost:9093");
            io:println(string`Error details: ${disruptionResponse.message()}`);
        }
    } else {
        io:println("❌ All fields are required for publishing a disruption.");
    }
}