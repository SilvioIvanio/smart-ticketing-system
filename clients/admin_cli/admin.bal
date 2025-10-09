import ballerina/io;
import ballerina/http;
import ballerina/regex;

// Client endpoints for the services
final http:Client transportService = check new ("http://localhost:9094");
final http:Client adminService = check new ("http://localhost:9093");

public function main() returns error? {
    io:println("\n");
    io:println("═══════════════════════════════════════════════════");
    io:println("    🔧 Smart Ticketing System - Admin Console 🔧   ");
    io:println("═══════════════════════════════════════════════════");

    boolean running = true;
    while running {
        showMainMenu();
        io:print("\n👉 Enter your choice: ");

        string? command = io:readln();

        if command is string {
            running = check handleCommand(command.trim());
        } else {
            io:println("❌ Invalid input. Please try again.");
        }
    }
    
    io:println("\n👋 Thank you for using Admin Console. Goodbye!\n");
    return;
}

function showMainMenu() {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║          🔧 Admin Commands                 ║");
    io:println("╠════════════════════════════════════════════╣");
    io:println("║  1. 🛣️  Create route                       ║");
    io:println("║  2. 🚌 Create trip                         ║");
    io:println("║  3. 📋 View all routes                     ║");
    io:println("║  4. 🎫 View all trips                      ║");
    io:println("║  5. 💰 Sales report                        ║");
    io:println("║  6. ⚠️  Publish disruption                 ║");
    io:println("║  0. 🚪 Exit                                ║");
    io:println("╚════════════════════════════════════════════╝");
}

function handleCommand(string command) returns boolean|error {
    match command {
        "1" => {
            check handleCreateRoute();
        }
        "2" => {
            check handleCreateTrip();
        }
        "3" => {
            check handleViewRoutes();
        }
        "4" => {
            check handleViewAllTrips();
        }
        "5" => {
            check handleSalesReport();
        }
        "6" => {
            check handlePublishDisruption();
        }
        "0" => {
            return false; // Exit
        }
        _ => {
            io:println("❌ Invalid choice. Please select a valid number.");
        }
    }
    return true; // Continue running
}

function handleCreateRoute() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         🛣️  Create New Route               ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("\nEnter route name: ");
    string? name = io:readln();
    
    io:println("\n📋 Route Types:");
    io:println("  1. Bus");
    io:println("  2. Train");
    io:print("\n👉 Select route type (1-2): ");
    string? typeChoice = io:readln();
    
    string routeType = "bus";
    if typeChoice is string {
        match typeChoice.trim() {
            "1" => { routeType = "bus"; }
            "2" => { routeType = "train"; }
            _ => {
                io:println("❌ Invalid type. Using 'bus'.");
            }
        }
    }
    
    io:print("\nEnter stops (comma-separated, e.g., 'Central Station, Park Ave, Airport'): ");
    string? stopsStr = io:readln();

    if name is string && stopsStr is string {
        if name.trim() == "" || stopsStr.trim() == "" {
            io:println("❌ Route name and stops cannot be empty.");
            return;
        }

        string[] stops = regex:split(stopsStr, ",").map(s => s.trim());
        
        if stops.length() < 2 {
            io:println("❌ A route must have at least 2 stops.");
            return;
        }
        
        json schedule = {
            "weekdays": ["08:00", "17:00"],
            "weekends": ["10:00"]
        };
        
        json routePayload = {
            "name": name.trim(),
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
                    io:println("═══════════════════════════════════════════════════════════");
                    io:println(responseJson.toJsonString());
                    io:println("═══════════════════════════════════════════════════════════");
                } else {
                    io:println("✅ Route created successfully!");
                }
            } else {
                string|error payload = routeResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Route creation failed: ${payload}`);
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
    io:println("║         🚌 Create New Trip                 ║");
    io:println("╚════════════════════════════════════════════╝");
    
    // First, fetch and display available routes
    io:println("\n⏳ Fetching available routes...");
    RouteInfo[]|error routes = fetchRoutes();
    
    if routes is error {
        io:println(string`❌ Error fetching routes: ${routes.message()}`);
        io:println("💡 Please create routes first before creating trips.");
        return;
    }
    
    if routes.length() == 0 {
        io:println("❌ No routes available. Please create a route first.");
        return;
    }
    
    io:println("\n✅ Available Routes:");
    io:println("═══════════════════════════════════════════════════════════");
    foreach int i in 0..<routes.length() {
        RouteInfo r = routes[i];
        io:println(string`  [${i + 1}] ${r.name} (${r.routeType})`);
        io:println(string`      Route ID: ${r.routeId}`);
        io:println(string`      Stops: ${r.stopsCount} stops`);
        io:println("───────────────────────────────────────────────────────────");
    }
    
    io:print("\n👉 Select route number (or 0 to cancel): ");
    string? routeChoice = io:readln();
    
    if routeChoice is string && routeChoice.trim() == "0" {
        io:println("❌ Trip creation cancelled.");
        return;
    }
    
    string routeId = "";
    string routeName = "";
    
    if routeChoice is string {
        int|error routeIndex = int:fromString(routeChoice);
        if routeIndex is int && routeIndex > 0 && routeIndex <= routes.length() {
            RouteInfo selectedRoute = routes[routeIndex - 1];
            routeId = selectedRoute.routeId;
            routeName = selectedRoute.name;
            io:println(string`\n✅ Selected route: ${routeName}`);
        } else {
            io:println("❌ Invalid route selection.");
            return;
        }
    } else {
        io:println("❌ Invalid input.");
        return;
    }
    
    io:print("\nEnter Departure Time (YYYY-MM-DDTHH:MM:SSZ, e.g., 2024-12-20T08:00:00Z): ");
    string? departureTime = io:readln();
    io:print("Enter Arrival Time (YYYY-MM-DDTHH:MM:SSZ, e.g., 2024-12-20T09:30:00Z): ");
    string? arrivalTime = io:readln();
    io:print("Enter Vehicle ID (e.g., BUS-001): ");
    string? vehicleId = io:readln();

    if departureTime is string && arrivalTime is string && vehicleId is string {
        if departureTime.trim() == "" || arrivalTime.trim() == "" || vehicleId.trim() == "" {
            io:println("❌ All fields are required.");
            return;
        }

        json tripPayload = {
            "routeId": routeId,
            "departureTime": departureTime.trim(),
            "arrivalTime": arrivalTime.trim(),
            "vehicleId": vehicleId.trim()
        };
        
        io:println("\n⏳ Creating trip...");
        
        http:Response|error tripResponse = transportService->post("/transport/trips", tripPayload);
        
        if tripResponse is http:Response {
            int statusCode = tripResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = tripResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Trip created successfully!");
                    io:println("═══════════════════════════════════════════════════════════");
                    io:println(string`🛣️  Route: ${routeName}`);
                    io:println(responseJson.toJsonString());
                    io:println("═══════════════════════════════════════════════════════════");
                } else {
                    io:println("✅ Trip created successfully!");
                }
            } else {
                string|error payload = tripResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Trip creation failed: ${payload}`);
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

function handleViewRoutes() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         📋 All Routes                      ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching routes...");
    
    http:Response|error routesResponse = transportService->get("/transport/routes");
    
    if routesResponse is http:Response {
        int statusCode = routesResponse.statusCode;
        
        if statusCode == 200 {
            json|error responseJson = routesResponse.getJsonPayload();
            if responseJson is json {
                if responseJson is json[] && responseJson.length() > 0 {
                    io:println("\n✅ Available Routes:");
                    io:println("═══════════════════════════════════════════════════════════");
                    foreach json route in responseJson {
                        string routeId = check route.routeId.ensureType();
                        string name = check route.name.ensureType();
                        string routeType = check route.routeType.ensureType();
                        json stops = check route.stops;
                        boolean active = check route.active.ensureType();
                        
                        io:println(string`📍 ${name} (${routeType})`);
                        io:println(string`   ID: ${routeId}`);
                        io:println(string`   Status: ${active ? "✅ Active" : "❌ Inactive"}`);
                        io:println(string`   Stops: ${stops.toJsonString()}`);
                        io:println("───────────────────────────────────────────────────────────");
                    }
                } else {
                    io:println("\n📭 No routes found.");
                    io:println("💡 Create a route to get started!");
                }
            } else {
                io:println("❌ Invalid response format");
            }
        } else {
            string|error payload = routesResponse.getTextPayload();
            if payload is string {
                io:println(string`❌ Failed to fetch routes: ${payload}`);
            } else {
                io:println(string`❌ Failed to fetch routes with status code: ${statusCode}`);
            }
        }
    } else {
        io:println("❌ Error connecting to Transport Service.");
        io:println("💡 Make sure the service is running on http://localhost:9094");
        io:println(string`Error details: ${routesResponse.message()}`);
    }
}

function handleViewAllTrips() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         🎫 All Trips                       ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching all trips...");
    
    http:Response|error routesResponse = transportService->get("/transport/routes");
    
    if routesResponse is http:Response {
        if routesResponse.statusCode == 200 {
            json|error routesJson = routesResponse.getJsonPayload();
            if routesJson is json && routesJson is json[] {
                boolean hasTrips = false;
                
                foreach json routeJson in routesJson {
                    string routeId = check routeJson.routeId.ensureType();
                    string routeName = check routeJson.name.ensureType();
                    
                    http:Response|error tripsResponse = transportService->get(string`/transport/trips/route/${routeId}`);
                    
                    if tripsResponse is http:Response && tripsResponse.statusCode == 200 {
                        json|error tripsJson = tripsResponse.getJsonPayload();
                        if tripsJson is json && tripsJson is json[] && tripsJson.length() > 0 {
                            if !hasTrips {
                                io:println("\n✅ Available Trips:");
                                io:println("═══════════════════════════════════════════════════════════");
                                hasTrips = true;
                            }
                            
                            io:println(string`\n🛣️  Route: ${routeName}`);
                            foreach json trip in tripsJson {
                                string tripId = check trip.tripId.ensureType();
                                string departureTime = check trip.departureTime.ensureType();
                                string arrivalTime = check trip.arrivalTime.ensureType();
                                string vehicleId = check trip.vehicleId.ensureType();
                                string status = check trip.status.ensureType();
                                
                                io:println(string`   🚌 Trip ID: ${tripId}`);
                                io:println(string`      Vehicle: ${vehicleId}`);
                                io:println(string`      Departure: ${departureTime}`);
                                io:println(string`      Arrival: ${arrivalTime}`);
                                io:println(string`      Status: ${status}`);
                                io:println("   ───────────────────────────────────────────────────────");
                            }
                        }
                    }
                }
                
                if !hasTrips {
                    io:println("\n📭 No trips found.");
                    io:println("💡 Create trips to get started!");
                }
            }
        }
    } else {
        io:println("❌ Error connecting to Transport Service.");
        io:println(string`Error details: ${routesResponse.message()}`);
    }
}

function handleSalesReport() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         💰 Sales Report                    ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Generating report...");
    
    http:Response|error salesReportResponse = adminService->get("/admin/reports/sales");
    
    if salesReportResponse is http:Response {
        int statusCode = salesReportResponse.statusCode;
        
        if statusCode == 200 {
            json|error responseJson = salesReportResponse.getJsonPayload();
            if responseJson is json {
                io:println("\n✅ Sales Report:");
                io:println("═══════════════════════════════════════════════════════════");
                io:println(responseJson.toJsonString());
                io:println("═══════════════════════════════════════════════════════════");
            } else {
                io:println("❌ Invalid response format");
            }
        } else if statusCode == 404 {
            io:println("\n📭 No sales data available yet.");
        } else {
            string|error payload = salesReportResponse.getTextPayload();
            if payload is string {
                io:println(string`❌ Failed to generate report: ${payload}`);
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
    io:println("║       ⚠️  Publish Disruption               ║");
    io:println("╚════════════════════════════════════════════╝");
    
    // Fetch and display available routes
    io:println("\n⏳ Fetching routes...");
    RouteInfo[]|error routes = fetchRoutes();
    
    if routes is error {
        io:println(string`❌ Error fetching routes: ${routes.message()}`);
        return;
    }
    
    if routes.length() == 0 {
        io:println("❌ No routes available.");
        return;
    }
    
    io:println("\n✅ Available Routes:");
    io:println("═══════════════════════════════════════════════════════════");
    foreach int i in 0..<routes.length() {
        RouteInfo r = routes[i];
        io:println(string`  [${i + 1}] ${r.name} (${r.routeType})`);
        io:println(string`      Route ID: ${r.routeId}`);
        io:println("───────────────────────────────────────────────────────────");
    }
    
    io:print("\n👉 Select route number (or 0 to cancel): ");
    string? routeChoice = io:readln();
    
    if routeChoice is string && routeChoice.trim() == "0" {
        io:println("❌ Disruption publishing cancelled.");
        return;
    }
    
    string routeId = "";
    string routeName = "";
    
    if routeChoice is string {
        int|error routeIndex = int:fromString(routeChoice);
        if routeIndex is int && routeIndex > 0 && routeIndex <= routes.length() {
            RouteInfo selectedRoute = routes[routeIndex - 1];
            routeId = selectedRoute.routeId;
            routeName = selectedRoute.name;
            io:println(string`\n✅ Selected route: ${routeName}`);
        } else {
            io:println("❌ Invalid route selection.");
            return;
        }
    } else {
        io:println("❌ Invalid input.");
        return;
    }
    
    io:print("\nEnter disruption message: ");
    string? message = io:readln();
    
    io:println("\n📋 Severity Levels:");
    io:println("  1. LOW");
    io:println("  2. MEDIUM");
    io:println("  3. HIGH");
    io:print("\n👉 Select severity (1-3): ");
    string? severityChoice = io:readln();
    
    string severity = "MEDIUM";
    if severityChoice is string {
        match severityChoice.trim() {
            "1" => { severity = "LOW"; }
            "2" => { severity = "MEDIUM"; }
            "3" => { severity = "HIGH"; }
            _ => {
                io:println("❌ Invalid severity. Using 'MEDIUM'.");
            }
        }
    }

    if message is string {
        if message.trim() == "" {
            io:println("❌ Message cannot be empty.");
            return;
        }

        json disruptionPayload = {
            "routeId": routeId,
            "message": message.trim(),
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
                    io:println("═══════════════════════════════════════════════════════════");
                    io:println(string`🛣️  Route: ${routeName}`);
                    io:println(string`⚠️  Severity: ${severity}`);
                    io:println(string`📝 Message: ${message}`);
                    io:println("═══════════════════════════════════════════════════════════");
                } else {
                    io:println("✅ Disruption published successfully!");
                }
            } else {
                string|error payload = disruptionResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Failed to publish disruption: ${payload}`);
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
        io:println("❌ Message is required for publishing a disruption.");
    }
}

// Helper types and functions
type RouteInfo record {
    string routeId;
    string name;
    string routeType;
    int stopsCount;
};

function fetchRoutes() returns RouteInfo[]|error {
    http:Response|error routesResponse = transportService->get("/transport/routes");
    
    if routesResponse is http:Response {
        if routesResponse.statusCode == 200 {
            json|error routesJson = routesResponse.getJsonPayload();
            if routesJson is json && routesJson is json[] {
                RouteInfo[] routes = [];
                foreach json routeJson in routesJson {
                    string routeId = check routeJson.routeId.ensureType();
                    string name = check routeJson.name.ensureType();
                    string routeType = check routeJson.routeType.ensureType();
                    json stops = check routeJson.stops;
                    int stopsCount = stops is json[] ? stops.length() : 0;
                    
                    RouteInfo route = {
                        routeId: routeId,
                        name: name,
                        routeType: routeType,
                        stopsCount: stopsCount
                    };
                    routes.push(route);
                }
                return routes;
            }
        }
    }
    return error("Failed to fetch routes");
}