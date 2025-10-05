import ballerina/http;
import ballerina/uuid;
import ballerina/crypto;
import ballerina/time;
import ballerina/log;

// MongoDB imports - you'll need to add these dependencies
import ballerinax/mongodb;

// Configuration values (from Config.toml)
configurable string mongoHost = ?;
configurable string dbName = ?;

// Create MongoDB client
mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

// Main HTTP service running on port 9090
service /passenger on new http:Listener(9090) {

    // Endpoint: POST /passenger/register
    // Purpose: Create a new user account
    resource function post register(@http:Payload UserRegistration userData)
            returns http:Created|http:Conflict|error {

        log:printInfo("Registration request received for: " + userData.email);

        // Connect to database
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection users = check db->getCollection("users");

        // Check if user already exists
        stream<User, error?> existingStream = check users->find({email: userData.email});
        User[]? existing = check from User u in existingStream select u;

        if existing is User[] && existing.length() > 0 {
            log:printWarn("User already exists: " + userData.email);
            return http:CONFLICT;
        }

        // Hash the password for security
        byte[] hash = crypto:hashSha256(userData.password.toBytes());
        string passwordHash = hash.toBase16();

        // Create new user record
        User newUser = {
            userId: uuid:createType1AsString(),
            username: userData.username,
            email: userData.email,
            passwordHash: passwordHash,
            role: "passenger",
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        // Save to database
        check users->insertOne(newUser);

        log:printInfo("User registered successfully: " + userData.email);
        return http:CREATED;
    }

    // Endpoint: POST /passenger/login
    // Purpose: Authenticate user and return user info
    resource function post login(@http:Payload UserLogin credentials)
            returns json|http:Unauthorized|error {

        log:printInfo("Login attempt for: " + credentials.email);

        // Connect to database
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection users = check db->getCollection("users");

        // Find user by email
        stream<User, error?> userStream = check users->find({email: credentials.email});
        User[]? foundUsers = check from User u in userStream select u;

        if foundUsers is () || foundUsers.length() == 0 {
            log:printWarn("User not found: " + credentials.email);
            return http:UNAUTHORIZED;
        }

        User user = foundUsers[0];

        // Verify password
        byte[] hash = crypto:hashSha256(credentials.password.toBytes());
        string passwordHash = hash.toBase16();

        if user.passwordHash != passwordHash {
            log:printWarn("Invalid password for: " + credentials.email);
            return http:UNAUTHORIZED;
        }

        log:printInfo("Login successful: " + credentials.email);

        // Return user information (without password)
        return {
            "userId": user.userId,
            "username": user.username,
            "email": user.email,
            "role": user.role
        };
    }

    // Endpoint: GET /passenger/tickets/{userId}
    // Purpose: Get all tickets for a user
    resource function get tickets/[string userId]() returns Ticket[]|error {

        log:printInfo("Fetching tickets for user: " + userId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        stream<Ticket, error?> ticketStream = check tickets->find({userId: userId});
        Ticket[] userTickets = check from Ticket t in ticketStream select t;

        log:printInfo(string `Found ${userTickets.length()} tickets`);
        return userTickets;
    }

    // Endpoint: GET /passenger/profile/{userId}
    // Purpose: Get user profile information
    resource function get profile/[string userId]() returns User|http:NotFound|error {

        log:printInfo("Fetching profile for user: " + userId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection users = check db->getCollection("users");

        stream<User, error?> userStream = check users->find({userId: userId});
        User[]? foundUsers = check from User u in userStream select u;

        if foundUsers is () || foundUsers.length() == 0 {
            log:printWarn("User not found: " + userId);
            return http:NOT_FOUND;
        }

        return foundUsers[0];
    }
}
