import ballerina/io;
import ballerina/http;

// Client endpoints for the services
final http:Client passengerService = check new ("http://localhost:9090");
final http:Client ticketingService = check new ("http://localhost:9091");
final http:Client transportService = check new ("http://localhost:9094");

// Global variables to store logged-in user information
string? loggedInUserId = ();
string? loggedInUsername = ();
string? loggedInEmail = ();

public function main() returns error? {
    io:println("\n");
    io:println("═══════════════════════════════════════════════════");
    io:println("    🚌 Smart Ticketing System - Passenger App 🚊   ");
    io:println("═══════════════════════════════════════════════════");

    boolean running = true;
    while running {
        if loggedInUserId is string {
            // Logged-in menu
            showLoggedInMenu();
        } else {
            // Logged-out menu
            showLoggedOutMenu();
        }

        io:print("\n👉 Enter your choice: ");
        string? command = io:readln();

        if command is string {
            if loggedInUserId is string {
                // Handle logged-in commands
                running = check handleLoggedInCommand(command.trim());
            } else {
                // Handle logged-out commands
                running = check handleLoggedOutCommand(command.trim());
            }
        } else {
            io:println("❌ Invalid input. Please try again.");
        }
    }
    
    io:println("\n👋 Thank you for using Smart Ticketing System. Goodbye!\n");
    return;
}

function showLoggedOutMenu() {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║          🔓 Welcome Guest                   ║");
    io:println("╠════════════════════════════════════════════╣");
    io:println("║  1. 📝 Register new account                ║");
    io:println("║  2. 🔐 Login to your account               ║");
    io:println("║  0. 🚪 Exit                                ║");
    io:println("╚════════════════════════════════════════════╝");
}

function showLoggedInMenu() {
    string username = loggedInUsername ?: "User";
    string email = loggedInEmail ?: "";
    
    io:println("\n╔════════════════════════════════════════════╗");
    io:println(string `║  👤 Logged in as: ${padRight(username, 24)}║`);
    if email != "" {
        io:println(string `║  📧 ${padRight(email, 37)}║`);
    }
    io:println("╠════════════════════════════════════════════╣");
    io:println("║  1. 🎫 Purchase ticket                     ║");
    io:println("║  2. 📋 View my tickets                     ║");
    io:println("║  3. 🔓 Logout                              ║");
    io:println("║  0. 🚪 Exit                                ║");
    io:println("╚════════════════════════════════════════════╝");
}

// Helper function to pad strings for menu alignment
function padRight(string str, int length) returns string {
    int currentLength = str.length();
    if currentLength >= length {
        return str.substring(0, length);
    }
    string padding = "";
    int i = 0;
    while i < (length - currentLength) {
        padding = padding + " ";
        i = i + 1;
    }
    return str + padding;
}

function handleLoggedOutCommand(string command) returns boolean|error {
    match command {
        "1" => {
            check handleRegister();
        }
        "2" => {
            check handleLogin();
        }
        "0" => {
            return false; // Exit
        }
        _ => {
            io:println("❌ Invalid choice. Please select 1, 2, or 0.");
        }
    }
    return true; // Continue running
}

function handleLoggedInCommand(string command) returns boolean|error {
    match command {
        "1" => {
            string? userId = loggedInUserId;
            if userId is string {
                check handleBuyTicket(userId);
            }
        }
        "2" => {
            string? userId = loggedInUserId;
            if userId is string {
                check handleViewTickets(userId);
            }
        }
        "3" => {
            handleLogout();
        }
        "0" => {
            return false; // Exit
        }
        _ => {
            io:println("❌ Invalid choice. Please select 1, 2, 3, or 0.");
        }
    }
    return true; // Continue running
}

function handleLogout() {
    string username = loggedInUsername ?: "User";
    loggedInUserId = ();
    loggedInUsername = ();
    loggedInEmail = ();
    io:println("\n✅ Successfully logged out. See you soon, " + username + "!");
}

function handleRegister() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         📝 Register New Account            ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter username: ");
    string? username = io:readln();
    io:print("Enter email: ");
    string? email = io:readln();
    io:print("Enter password: ");
    string? password = io:readln();

    if username is string && email is string && password is string {
        if username.trim() == "" || email.trim() == "" || password.trim() == "" {
            io:println("❌ All fields are required and cannot be empty.");
            return;
        }

        json registerPayload = {
            "username": username.trim(),
            "email": email.trim(),
            "password": password
        };
        
        io:println("\n⏳ Creating your account...");
        
        http:Response|error registerResponse = passengerService->post("/passenger/register", registerPayload);
        
        if registerResponse is http:Response {
            int statusCode = registerResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = registerResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Registration successful!");
                    io:println("🎉 Welcome to Smart Ticketing System!");
                    io:println("\n💡 You can now login with your credentials.");
                } else {
                    io:println("✅ Registration successful! You can now login.");
                }
            } else {
                string|error payload = registerResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Registration failed: ${payload}`);
                } else {
                    io:println(string`❌ Registration failed with status code: ${statusCode}`);
                }
            }
        } else {
            io:println("❌ Error connecting to Passenger Service.");
            io:println("💡 Make sure the service is running on http://localhost:9090");
            io:println(string`Error details: ${registerResponse.message()}`);
        }
    } else {
        io:println("❌ All fields are required for registration.");
    }
}

function handleLogin() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║         🔐 Login to Your Account           ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter email: ");
    string? email = io:readln();
    io:print("Enter password: ");
    string? password = io:readln();

    if email is string && password is string {
        if email.trim() == "" || password.trim() == "" {
            io:println("❌ Email and password cannot be empty.");
            return;
        }

        json loginPayload = {
            "email": email.trim(),
            "password": password
        };
        
        io:println("\n⏳ Authenticating...");
        
        http:Response|error loginResponse = passengerService->post("/passenger/login", loginPayload);
        
        if loginResponse is http:Response {
            int statusCode = loginResponse.statusCode;
            
            if statusCode == 200 || statusCode == 201 {
                json|error loginJson = loginResponse.getJsonPayload();
                if loginJson is json {
                    string|error userId = loginJson.userId.ensureType();
                    string|error username = loginJson.username.ensureType();
                    string|error userEmail = loginJson.email.ensureType();
                    
                    if userId is string {
                        loggedInUserId = userId;
                        loggedInUsername = username is string ? username : "User";
                        loggedInEmail = userEmail is string ? userEmail : "";
                        
                        string displayName = loggedInUsername ?: "User";
                        io:println("\n✅ Login successful!");
                        io:println(string `🎉 Welcome back, ${displayName}!`);
                    } else {
                        io:println("❌ Invalid response format: missing userId");
                    }
                } else {
                    io:println("❌ Invalid response format");
                }
            } else {
                string|error payload = loginResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Login failed: ${payload}`);
                } else {
                    io:println("❌ Login failed. Please check your credentials.");
                }
                loggedInUserId = ();
                loggedInUsername = ();
                loggedInEmail = ();
            }
        } else {
            io:println("❌ Error connecting to Passenger Service.");
            io:println("💡 Make sure the service is running on http://localhost:9090");
            io:println(string`Error details: ${loginResponse.message()}`);
            loggedInUserId = ();
            loggedInUsername = ();
            loggedInEmail = ();
        }
    } else {
        io:println("❌ Email and password are required for login.");
    }
}

function handleBuyTicket(string userId) returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║           🎫 Purchase Ticket               ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching available trips...");
    TripInfo[]|error availableTrips = fetchAvailableTrips();

    if availableTrips is error {
        io:println(string`❌ Error fetching trips: ${availableTrips.message()}`);
        return;
    }

    if availableTrips.length() == 0 {
        io:println("❌ No trips available at the moment. Please try again later.");
        return;
    }

    io:println("\n✅ Available Trips:");
    io:println("═══════════════════════════════════════════════════════════");
    foreach int i in 0..<availableTrips.length() {
        TripInfo t = availableTrips[i];
        io:println(string`  [${i + 1}] ${t.routeName}`);
        io:println(string`      🚌 Vehicle: ${t.vehicleId}`);
        io:println(string`      🕐 Departure: ${t.departureTime}`);
        io:println(string`      🕑 Arrival: ${t.arrivalTime}`);
        io:println(string`      🆔 Trip ID: ${t.tripId}`);
        io:println("───────────────────────────────────────────────────────────");
    }

    io:print("\n👉 Select trip number (or 0 to cancel): ");
    string? tripChoiceStr = io:readln();

    if tripChoiceStr is string && tripChoiceStr.trim() == "0" {
        io:println("❌ Ticket purchase cancelled.");
        return;
    }

    if tripChoiceStr is string {
        int|error tripIndex = int:fromString(tripChoiceStr);
        if tripIndex is int && tripIndex > 0 && tripIndex <= availableTrips.length() {
            TripInfo selectedTrip = availableTrips[tripIndex - 1];
            string tripId = selectedTrip.tripId;

            io:println("\n📋 Ticket Types:");
            io:println("  1. Single (One-way)");
            io:println("  2. Daily Pass");
            io:println("  3. Weekly Pass");
            io:print("\n👉 Select ticket type (1-3): ");
            string? typeChoice = io:readln();
            
            string ticketType = "single";
            if typeChoice is string {
                match typeChoice.trim() {
                    "1" => { ticketType = "single"; }
                    "2" => { ticketType = "daily"; }
                    "3" => { ticketType = "weekly"; }
                    _ => {
                        io:println("❌ Invalid ticket type. Using 'single'.");
                    }
                }
            }

            io:print("Enter Price: ");
            string? priceStr = io:readln();

            if priceStr is string {
                decimal|error price = decimal:fromString(priceStr);
                if price is error {
                    io:println("❌ Invalid price format. Please enter a valid number.");
                    return;
                }
                
                json ticketPayload = {
                    "userId": userId,
                    "tripId": tripId,
                    "ticketType": ticketType,
                    "price": price
                };
                
                io:println("\n⏳ Processing your ticket purchase...");
                
                http:Response|error ticketResponse = ticketingService->post("/ticketing/tickets", ticketPayload);
                
                if ticketResponse is http:Response {
                    int statusCode = ticketResponse.statusCode;
                    
                    if statusCode == 201 || statusCode == 200 {
                        json|error ticketJson = ticketResponse.getJsonPayload();
                        if ticketJson is json {
                            string|error ticketId = ticketJson.ticketId.ensureType();
                            io:println("\n✅ Ticket purchased successfully!");
                            io:println("═══════════════════════════════════════════════════════════");
                            if ticketId is string {
                                io:println(string`🎫 Ticket ID: ${ticketId}`);
                            }
                            io:println(string`🚌 Route: ${selectedTrip.routeName}`);
                            io:println(string`📝 Type: ${ticketType}`);
                            io:println(string`💰 Price: $${price}`);
                            io:println("═══════════════════════════════════════════════════════════");
                        } else {
                            io:println("✅ Ticket created successfully!");
                        }
                    } else {
                        string|error payload = ticketResponse.getTextPayload();
                        if payload is string {
                            io:println(string`❌ Ticket purchase failed: ${payload}`);
                        } else {
                            io:println(string`❌ Ticket purchase failed with status code: ${statusCode}`);
                        }
                    }
                } else {
                    io:println("❌ Error connecting to Ticketing Service.");
                    io:println("💡 Make sure the service is running on http://localhost:9091");
                    io:println(string`Error details: ${ticketResponse.message()}`);
                }
            } else {
                io:println("❌ Price is required.");
            }
        } else {
            io:println("❌ Invalid trip selection.");
        }
    } else {
        io:println("❌ Invalid input.");
    }
}

function handleViewTickets(string userId) returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║           📋 My Tickets                    ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching your tickets...");
    
    http:Response|error userTicketsResponse = passengerService->get(string`/passenger/tickets/${userId}`);
    
    if userTicketsResponse is http:Response {
        int statusCode = userTicketsResponse.statusCode;
        
        if statusCode == 200 {
            json|error responseJson = userTicketsResponse.getJsonPayload();
            if responseJson is json {
                io:println("\n✅ Your Tickets:");
                io:println("═══════════════════════════════════════════════════════════");
                io:println(responseJson.toJsonString());
                io:println("═══════════════════════════════════════════════════════════");
            } else {
                io:println("❌ Invalid response format");
            }
        } else if statusCode == 404 {
            io:println("\n📭 You don't have any tickets yet.");
            io:println("💡 Purchase a ticket to get started!");
        } else {
            string|error payload = userTicketsResponse.getTextPayload();
            if payload is string {
                io:println(string`❌ Failed to fetch tickets: ${payload}`);
            } else {
                io:println(string`❌ Failed to fetch tickets with status code: ${statusCode}`);
            }
        }
    } else {
        io:println("❌ Error connecting to Passenger Service.");
        io:println("💡 Make sure the service is running on http://localhost:9090");
        io:println(string`Error details: ${userTicketsResponse.message()}`);
    }
}

// Simplified record type for displaying trip information
type TripInfo record {
    string tripId;
    string routeName;
    string departureTime;
    string arrivalTime;
    string vehicleId;
};

function fetchAvailableTrips() returns TripInfo[]|error {
    http:Response|error routesResponse = transportService->get("/transport/routes");

    if routesResponse is http:Response {
        if routesResponse.statusCode == 200 {
            json|error routesJson = routesResponse.getJsonPayload();
            if routesJson is json {
                if routesJson is json[] {
                    TripInfo[] allTrips = [];

                    foreach json routeJson in routesJson {
                        string routeId = check routeJson.routeId.ensureType();
                        string routeName = check routeJson.name.ensureType();
                        
                        http:Response|error tripsResponse = transportService->get(string`/transport/trips/route/${routeId}`);
                        
                        if tripsResponse is http:Response {
                            if tripsResponse.statusCode == 200 {
                                json|error tripsJson = tripsResponse.getJsonPayload();
                                if tripsJson is json {
                                    if tripsJson is json[] {
                                        foreach json tripJson in tripsJson {
                                            string tripId = check tripJson.tripId.ensureType();
                                            string departureTime = check tripJson.departureTime.ensureType();
                                            string arrivalTime = check tripJson.arrivalTime.ensureType();
                                            string vehicleId = check tripJson.vehicleId.ensureType();
                                            
                                            TripInfo trip = {
                                                tripId: tripId,
                                                routeName: routeName,
                                                departureTime: departureTime,
                                                arrivalTime: arrivalTime,
                                                vehicleId: vehicleId
                                            };
                                            allTrips.push(trip);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return allTrips;
                } else {
                    return error("Routes response is not an array");
                }
            } else {
                return error("Invalid routes response format");
            }
        } else {
            return error(string`Failed to fetch routes (Status ${routesResponse.statusCode})`);
        }
    } else {
        return error(string`Error connecting to Transport Service: ${routesResponse.message()}`);
    }
}