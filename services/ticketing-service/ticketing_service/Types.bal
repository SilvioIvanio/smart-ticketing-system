import ballerina/time;

// Ticket stored in database
public type Ticket record {|
    string ticketId;
    string userId;
    string tripId;
    string ticketType;
    string status;
    decimal price;
    time:Utc validFrom;
    time:Utc validUntil;
    int ridesRemaining?;
    time:Utc createdAt;
    time:Utc updatedAt;
|};

// Message sent to Kafka when ticket is created
public type TicketRequest record {|
    string ticketId;
    string userId;
    string tripId;
    string ticketType;
    decimal price;
    string status;
|};

// Request to validate a ticket
public type TicketValidation record {|
    string ticketId;
    string validatorId;
    time:Utc validatedAt;
|};

// Message from payment service
public type PaymentProcessed record {|
    string paymentId;
    string ticketId;
    string status;
    time:Utc timestamp;
|};
