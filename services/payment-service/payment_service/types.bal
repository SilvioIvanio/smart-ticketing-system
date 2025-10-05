import ballerina/time;

public type Payment record {|
    string paymentId;
    string ticketId;
    string userId;
    decimal amount;
    string status;           // "PENDING", "SUCCESS", "FAILED"
    string paymentMethod;    // "card", "mobile", "cash"
    time:Utc createdAt;
    time:Utc? processedAt;
|};
