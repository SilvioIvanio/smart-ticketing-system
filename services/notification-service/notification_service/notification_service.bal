import ballerina/log;
import ballerina/io;
import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerinax/kafka;
import ballerinax/mongodb;

configurable string kafkaBootstrap = ?;
configurable string mongoHost = ?;
configurable string dbName = ?;

mongodb:Client mongoClient = check new ({
    connection: mongoHost
});

type Notification record {
    string notificationId;
    string userId;
    string message;
    string notificationType;
    string status;
    time:Utc createdAt;
};

service / on new http:Listener(9095) {
    
    resource function get notifications/[string userId]() returns Notification[]|error {
        log:printInfo("Fetching notifications for user: " + userId);
        
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection notifications = check db->getCollection("notifications");
        
        stream<Notification, error?> notificationStream = check notifications->find({userId: userId});
        Notification[] userNotifications = check from Notification n in notificationStream select n;
        
        log:printInfo(string `Found ${userNotifications.length()} notifications`);
        return userNotifications;
    }
    
    resource function put notifications/[string notificationId]/read() returns json|error {
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection notifications = check db->getCollection("notifications");
        
        _ = check notifications->updateOne(
            {notificationId: notificationId},
            {"$set": {"status": "read"}}
        );
        
        return {
            "success": true,
            "message": "Notification marked as read"
        };
    }
    
    resource function get health() returns string {
        return "Notification Service is running";
    }
}

listener kafka:Listener scheduleListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["schedule.updates"]
});

listener kafka:Listener validationListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["ticket.validated"]
});

listener kafka:Listener paymentListener = check new (kafkaBootstrap, {
    groupId: "notification-service-group",
    topics: ["payments.processed"]
});

service kafka:Service on scheduleListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendScheduleNotification(payload);
        }
    }
}

service kafka:Service on validationListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendValidationNotification(payload);
        }
    }
}

service kafka:Service on paymentListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                     kafka:AnydataConsumerRecord[] records) returns error? {
        foreach var rec in records {
            json payload = check rec.value.ensureType();
            check sendPaymentNotification(payload);
        }
    }
}

function sendScheduleNotification(json data) returns error? {
    string tripId = check data.tripId;
    string status = check data.status;

    string message = string `🚌 Trip ${tripId} is now ${status}`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
    
    check storeNotification("all", message, "disruption");
}

function sendValidationNotification(json data) returns error? {
    string ticketId = check data.ticketId;
    string userId = check data.userId;

    string message = string `✅ Ticket ${ticketId} validated successfully`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
    
    check storeNotification(userId, message, "validation");
}

function sendPaymentNotification(json data) returns error? {
    string ticketId = check data.ticketId;
    string status = check data.status;
    
    string userId = "unknown";
    if data.userId is string {
        userId = check data.userId;
    }

    string emoji = status == "SUCCESS" ? "💳" : "❌";
    string message = string `${emoji} Payment for ticket ${ticketId}: ${status}`;

    log:printInfo("NOTIFICATION: " + message);
    io:println("\n" + message + "\n");
    
    check storeNotification(userId, message, "payment");
}

function storeNotification(string userId, string message, string notificationType) returns error? {
    mongodb:Database db = check mongoClient->getDatabase(dbName);
    mongodb:Collection notifications = check db->getCollection("notifications");
    
    Notification notification = {
        notificationId: uuid:createType1AsString(),
        userId: userId,
        message: message,
        notificationType: notificationType,
        status: "unread",
        createdAt: time:utcNow()
    };
    
    check notifications->insertOne(notification);
    log:printInfo("Notification stored for user: " + userId);
}