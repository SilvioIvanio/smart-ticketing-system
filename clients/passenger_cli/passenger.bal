import ballerina/io;
import ballerina/http;

// Client endpoints for the services
final http:Client passengerService = check new ("http://localhost:9090");
final http:Client ticketingService = check new ("http://localhost:9091");
final http:Client transportService = check new ("http://localhost:9094");

// Global variable to store logged-in user ID
string? loggedInUserId = ();

public function main() returns error? {
    io:println("=================================================");
    io:println("Smart Ticketing System - Passenger CLI");
    io:println("=================================================");

    boolean running = true;
    while running {
        io:println("\n╔════════════════════════════════════════════╗");
        io:println("║          Available Commands                ║");
        io:println("╠════════════════════════════════════════════╣");
        io:println("║  1. Register new passenger                 ║");
        io:println("║  2. Login                                  ║");
        if loggedInUserId is string {
            io:println("║  3. Buy ticket                             ║");
            io:println("║  4. View my tickets                        ║");
        }
        io:println("║  0. Exit                                   ║");
        io:println("╚════════════════════════════════════════════╝");
        io:print("\n👉 Enter your choice: ");

        string? command = io:readln();

        if command is string {
            match command.trim() {
                "1" => {
                    check handleRegister();
                }
                "2" => {
                    check handleLogin();
                }
                "3" => {
                    string? userId = loggedInUserId;
                    if userId is string {
                        check handleBuyTicket(userId);
                    } else {
                        io:println("❌ Please log in first to buy a ticket.");
                    }
                }
                "4" => {
                    string? userId = loggedInUserId;
                    if userId is string {
                        check handleViewTickets(userId);
                    } else {
                        io:println("❌ Please log in first to view tickets.");
                    }
                }
                "0" => {
                    running = false;
                    io:println("\n👋 Exiting Passenger CLI. Goodbye!");
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

function handleRegister() returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║       Register New Passenger               ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter username: ");
    string? username = io:readln();
    io:print("Enter email: ");
    string? email = io:readln();
    io:print("Enter password: ");
    string? password = io:readln();

    if username is string && email is string && password is string {
        json registerPayload = {
            "username": username,
            "email": email,
            "password": password
        };
        
        io:println("\n⏳ Registering user...");
        
        http:Response|error registerResponse = passengerService->post("/passenger/register", registerPayload);
        
        if registerResponse is http:Response {
            int statusCode = registerResponse.statusCode;
            
            if statusCode == 201 || statusCode == 200 {
                json|error responseJson = registerResponse.getJsonPayload();
                if responseJson is json {
                    io:println("\n✅ Registration successful!");
                    io:println(responseJson.toJsonString());
                } else {
                    io:println("✅ Registration successful!");
                }
            } else {
                string|error payload = registerResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Registration failed (Status ${statusCode}): ${payload}`);
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
    io:println("║            Passenger Login                 ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:print("Enter email: ");
    string? email = io:readln();
    io:print("Enter password: ");
    string? password = io:readln();

    if email is string && password is string {
        json loginPayload = {
            "email": email,
            "password": password
        };
        
        io:println("\n⏳ Logging in...");
        
        http:Response|error loginResponse = passengerService->post("/passenger/login", loginPayload);
        
        if loginResponse is http:Response {
            int statusCode = loginResponse.statusCode;
            
            if statusCode == 200 || statusCode == 201 {
                json|error loginJson = loginResponse.getJsonPayload();
                if loginJson is json {
                    string|error userId = loginJson.userId.ensureType();
                    if userId is string {
                        loggedInUserId = userId;
                        io:println("\n✅ Login successful!");
                        io:println(loginJson.toJsonString());
                        io:println(string`👤 Logged in as User ID: ${userId}`);
                    } else {
                        io:println("❌ Invalid response format: missing userId");
                    }
                } else {
                    io:println("❌ Invalid response format");
                }
            } else {
                string|error payload = loginResponse.getTextPayload();
                if payload is string {
                    io:println(string`❌ Login failed (Status ${statusCode}): ${payload}`);
                } else {
                    io:println(string`❌ Login failed with status code: ${statusCode}`);
                }
                loggedInUserId = ();
            }
        } else {
            io:println("❌ Error connecting to Passenger Service.");
            io:println("💡 Make sure the service is running on http://localhost:9090");
            io:println(string`Error details: ${loginResponse.message()}`);
            loggedInUserId = ();
        }
    } else {
        io:println("❌ Email and password are required for login.");
    }
}

function handleBuyTicket(string userId) returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║           Purchase Ticket                  ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching available trips...");
    Trip[]|error availableTrips = fetchAvailableTrips();

    if availableTrips is error {
        io:println(string`❌ Error fetching trips: ${availableTrips.message()}`);
        return;
    }

    if availableTrips.length() == 0 {
        io:println("❌ No trips available at the moment. Please try again later.");
        return;
    }

    io:println("\nAvailable Trips:");
    foreach int i in 0..<availableTrips.length() {
        Trip t = availableTrips[i];
        io:println(string`  [${i + 1}] Route: ${t.routeName}, Vehicle: ${t.vehicleId}, Departure: ${t.departureTime}, Arrival: ${t.arrivalTime}, Trip ID: ${t.tripId}`);
    }

    io:print("\nEnter the number of the trip you want to purchase a ticket for: ");
    string? tripChoiceStr = io:readln();

    if tripChoiceStr is string {
        int|error tripIndex = int:fromString(tripChoiceStr);
        if tripIndex is int && tripIndex > 0 && tripIndex <= availableTrips.length() {
            Trip selectedTrip = availableTrips[tripIndex - 1];
            string tripId = selectedTrip.tripId;

            io:print("Enter Ticket Type (single/daily/weekly): ");
            string? ticketType = io:readln();
            io:print("Enter Price: ");
            string? priceStr = io:readln();

            if ticketType is string && priceStr is string {
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
                
                io:println("\n⏳ Creating ticket...");
                
                http:Response|error ticketResponse = ticketingService->post("/ticketing/tickets", ticketPayload);
                
                if ticketResponse is http:Response {
                    int statusCode = ticketResponse.statusCode;
                    
                    if statusCode == 201 || statusCode == 200 {
                        json|error ticketJson = ticketResponse.getJsonPayload();
                        if ticketJson is json {
                            string|error ticketId = ticketJson.ticketId.ensureType();
                            io:println("\n✅ Ticket purchase successful!");
                            io:println(ticketJson.toJsonString());
                            if ticketId is string {
                                io:println(string`🎫 Ticket ID: ${ticketId}`);
                            }
                        } else {
                            io:println("✅ Ticket created successfully!");
                        }
                    } else {
                        string|error payload = ticketResponse.getTextPayload();
                        if payload is string {
                            io:println(string`❌ Ticket purchase failed (Status ${statusCode}): ${payload}`);
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
                io:println("❌ Ticket type and price are required.");
            }
        } else {
            io:println("❌ Invalid trip selection.");
        }
    } else {
        io:println("❌ Invalid input.");
    }
    return;
}

function handleViewTickets(string userId) returns error? {
    io:println("\n╔════════════════════════════════════════════╗");
    io:println("║           View My Tickets                  ║");
    io:println("╚════════════════════════════════════════════╝");
    
    io:println("\n⏳ Fetching tickets...");
    
    http:Response|error userTicketsResponse = passengerService->get(string`/passenger/tickets/${userId}`);
    
    if userTicketsResponse is http:Response {
        int statusCode = userTicketsResponse.statusCode;
        
        if statusCode == 200 {
            json|error responseJson = userTicketsResponse.getJsonPayload();
            if responseJson is json {
                io:println("\n✅ Your tickets:");
                io:println(responseJson.toJsonString());
            } else {
                io:println("❌ Invalid response format");
            }
        } else {
            string|error payload = userTicketsResponse.getTextPayload();
            if payload is string {
                io:println(string`❌ Failed to fetch tickets (Status ${statusCode}): ${payload}`);
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

// Define record types for Route and Trip
type Route record {
    string routeId;
    string name;
    string routeType;
    string[] stops;
    json schedule;
    boolean active;
    string createdAt;
};

type Trip record {
    string tripId;
    string routeId;
    string routeName;
    string departureTime;
    string arrivalTime;
    string status;
    string vehicleId;
    string createdAt;
};

function fetchAvailableTrips() returns Trip[]|error {
    io:println("\n⏳ Fetching routes...");
    http:Response|error routesResponse = transportService->get("/transport/routes");

    if routesResponse is http:Response {
        if routesResponse.statusCode == 200 {
            json|error routesJson = routesResponse.getJsonPayload();
            if routesJson is json && routesJson is json[] {
                Route[] allRoutes = check routesJson.cloneWithType();
                Trip[] allTrips = [];

                foreach Route r in allRoutes {
                    io:println(string`⏳ Fetching trips for route: ${r.name} (${r.routeId})...`);
                    http:Response|error tripsResponse = transportService->get(string`/transport/trips/route/${r.routeId}`);
                    if tripsResponse is http:Response {
                        if tripsResponse.statusCode == 200 {
                            json|error tripsJson = tripsResponse.getJsonPayload();
                            if tripsJson is json && tripsJson is json[] {
                                Trip[] routeTrips = check tripsJson.cloneWithType();
                                foreach Trip t in routeTrips {
                                    Trip updatedTrip = t;
                                    updatedTrip.routeName = r.name;
                                    allTrips.push(updatedTrip);
                                }
                            } else {
                                io:println(string`❌ Invalid trips response format for route ${r.routeId}`);
                            }
                        } else {
                            io:println(string`❌ Failed to fetch trips for route ${r.routeId} (Status ${tripsResponse.statusCode})`);
                        }
                    } else {
                        io:println(string`❌ Error connecting to Transport Service for trips of route ${r.routeId}: ${tripsResponse.message()}`);
                    }
                }
                return allTrips;
            } else {
                return error("Invalid routes response format");
            }
        } else {
            return error(string`Failed to fetch routes (Status ${routesResponse.statusCode})`);
        }
    } else {
        return error(string`Error connecting to Transport Service for routes: ${routesResponse.message()}`);
    }
}
