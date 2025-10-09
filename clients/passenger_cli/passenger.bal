import ballerina/io;
import ballerina/http;

// Client endpoints for the services
final http:Client passengerService = check new ("http://localhost:9090");
final http:Client ticketingService = check new ("http://localhost:9091");

// Global variable to store logged-in user ID
string? loggedInUserId = ();

public function main() returns error? {
    io:println("=================================================");
    io:println("Smart Ticketing System - Passenger CLI");
    io:println("=================================================");

    boolean running = true;
    while running {
        io:println("\nAvailable commands:");
        io:println("  1. register - Register a new passenger");
        io:println("  2. login    - Log in as an existing passenger");
        if loggedInUserId is string {
            io:println("  3. buy_ticket - Purchase a new ticket");
            io:println("  4. view_tickets - View your purchased tickets");
        }
        io:println("  5. exit     - Exit the application");
        io:print("\nEnter command: ");

        string? command = io:readln();

        if command is string {
            match command.trim() {
                "register" => {
                    check handleRegister();
                }
                "login" => {
                    check handleLogin();
                }
                "buy_ticket" => {
                    string? userId = loggedInUserId;
                    if userId is string {
                        check handleBuyTicket(userId);
                    } else {
                        io:println("Please log in to buy a ticket.");
                    }
                }
                "view_tickets" => {
                    string? userId = loggedInUserId;
                    if userId is string {
                        check handleViewTickets(userId);
                    } else {
                        io:println("Please log in to view tickets.");
                    }
                }
                "exit" => {
                    running = false;
                    io:println("Exiting Passenger CLI. Goodbye!");
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

function handleRegister() returns error? {
    io:println("\n--- Register New Passenger ---");
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
        do {
            http:Response registerResponse = check passengerService->post("/passenger/register", registerPayload);
            json responseJson = check registerResponse.getJsonPayload();
            io:println("Registration successful:");
            io:println(responseJson.toJsonString());
        } on fail error err {
            io:println(string`Error during registration: ${err.message()}`);
        }
    } else {
        io:println("All fields are required for registration.");
    }
}

function handleLogin() returns error? {
    io:println("\n--- Passenger Login ---");
    io:print("Enter email: ");
    string? email = io:readln();
    io:print("Enter password: ");
    string? password = io:readln();

    if email is string && password is string {
        json loginPayload = {
            "email": email,
            "password": password
        };
        do {
            http:Response loginResponse = check passengerService->post("/passenger/login", loginPayload);
            json loginJson = check loginResponse.getJsonPayload();
            string userId = check loginJson.userId.ensureType();
            loggedInUserId = userId;
            io:println("Login successful:");
            io:println(loginJson.toJsonString());
            io:println(string`👤 Logged in User ID: ${userId}`);
        } on fail error err {
            io:println(string`Error during login: ${err.message()}`);
            loggedInUserId = (); // Clear userId on failed login
        }
    } else {
        io:println("Email and password are required for login.");
    }
}

function handleBuyTicket(string userId) returns error? {
    io:println("\n--- Purchase Ticket ---");
    io:print("Enter Trip ID (e.g., TRIP-12345): ");
    string? tripId = io:readln();
    io:print("Enter Ticket Type (e.g., single, daily): ");
    string? ticketType = io:readln();
    io:print("Enter Price (e.g., 7.50): ");
    string? priceStr = io:readln();

    if tripId is string && ticketType is string && priceStr is string {
        decimal|error price = decimal:fromString(priceStr);
        if price is error {
            io:println("Invalid price format. Please enter a valid number.");
            return;
        }
        json ticketPayload = {
            "userId": userId,
            "tripId": tripId,
            "ticketType": ticketType,
            "price": price
        };
        do {
            http:Response ticketResponse = check ticketingService->post("/ticketing/tickets", ticketPayload);
            json ticketJson = check ticketResponse.getJsonPayload();
            string ticketId = check ticketJson.ticketId.ensureType();
            io:println("Ticket purchase successful:");
            io:println(ticketJson.toJsonString());
            io:println(string`🎫 Purchased Ticket ID: ${ticketId}`);
        } on fail error err {
            io:println(string`Error during ticket purchase: ${err.message()}`);
        }
    } else {
        io:println("All fields are required for ticket purchase.");
    }
}

function handleViewTickets(string userId) returns error? {
    io:println("\n--- View My Tickets ---");
    do {
        http:Response userTicketsResponse = check passengerService->get(string`/passenger/tickets/${userId}`);
        json responseJson = check userTicketsResponse.getJsonPayload();
        io:println("Your tickets:");
        io:println(responseJson.toJsonString());
    } on fail error err {
        io:println(string`Error viewing tickets: ${err.message()}`);
    }
}