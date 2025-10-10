import ballerina/http;
import ballerina/uuid;
import ballerina/crypto;
import ballerina/time;
import ballerina/log;
import ballerinax/mongodb;

configurable string mongoHost = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

service /passenger on new http:Listener(9090) {

    // FIXED: Now returns JSON with userId
    resource function post register(@http:Payload UserRegistration userData)
            returns json|http:Conflict|error {

        log:printInfo("Registration request received for: " + userData.email);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection users = check db->getCollection("users");

        // Check if user already exists
        stream<User, error?> existingStream = check users->find({email: userData.email});
        User[]? existing = check from User u in existingStream select u;

        if existing is User[] && existing.length() > 0 {
            log:printWarn("User already exists: " + userData.email);
            return http:CONFLICT;
        }

        byte[] hash = crypto:hashSha256(userData.password.toBytes());
        string passwordHash = hash.toBase16();

        User newUser = {
            userId: uuid:createType1AsString(),
            username: userData.username,
            email: userData.email,
            passwordHash: passwordHash,
            role: "passenger",
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        check users->insertOne(newUser);

        log:printInfo("User registered successfully: " + userData.email);
        
        // FIXED: Return JSON with userId instead of just http:CREATED
        return {
            "userId": newUser.userId,
            "username": newUser.username,
            "email": newUser.email,
            "message": "User registered successfully"
        };
    }

    resource function post login(@http:Payload UserLogin credentials)
            returns json|http:Unauthorized|error {

        log:printInfo("Login attempt for: " + credentials.email);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection users = check db->getCollection("users");

        stream<User, error?> userStream = check users->find({email: credentials.email});
        User[]? foundUsers = check from User u in userStream select u;

        if foundUsers is () || foundUsers.length() == 0 {
            log:printWarn("User not found: " + credentials.email);
            return http:UNAUTHORIZED;
        }

        User user = foundUsers[0];

        byte[] hash = crypto:hashSha256(credentials.password.toBytes());
        string passwordHash = hash.toBase16();

        if user.passwordHash != passwordHash {
            log:printWarn("Invalid password for: " + credentials.email);
            return http:UNAUTHORIZED;
        }

        log:printInfo("Login successful: " + credentials.email);

        return {
            "userId": user.userId,
            "username": user.username,
            "email": user.email,
            "role": user.role
        };
    }

    resource function get tickets/[string userId]() returns Ticket[]|error {

        log:printInfo("Fetching tickets for user: " + userId);

        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection tickets = check db->getCollection("tickets");

        stream<Ticket, error?> ticketStream = check tickets->find({userId: userId});
        Ticket[] userTickets = check from Ticket t in ticketStream select t;

        log:printInfo(string `Found ${userTickets.length()} tickets`);
        return userTickets;
    }

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