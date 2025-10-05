import ballerina/time;

// Represents a user in the system
public type User record {|
    string userId;           // Unique ID
    string username;         // Display name
    string email;           // Email address
    string passwordHash;    // Encrypted password
    string role;            // "passenger", "admin", or "validator"
    time:Utc createdAt;     // When account was created
    time:Utc updatedAt;     // Last update time
|};

// Data needed to register a new user
public type UserRegistration record {|
    string username;
    string email;
    string password;
|};

// Data needed to log in
public type UserLogin record {|
    string email;
    string password;
|};

// Represents a ticket
public type Ticket record {|
    string ticketId;
    string userId;
    string tripId;
    string ticketType;      // "single", "multi", or "pass"
    string status;          // "CREATED", "PAID", "VALIDATED", "EXPIRED"
    decimal price;
    time:Utc validFrom;
    time:Utc validUntil;
    int ridesRemaining?;    // Optional: for multi-ride tickets
|};
