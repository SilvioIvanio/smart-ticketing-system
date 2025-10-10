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

type DisruptionRequest record {|
    string routeId;
    string message;
    string severity; // LOW, MEDIUM, HIGH
|};

service / on new http:Listener(9095) {
    
    // Get notifications for specific user
    resource function get notifications/[string userId]() returns Notification[]|error {
        log:printInfo("Fetching notifications for user: " + userId);
        
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection notifications = check db->getCollection("notifications");
        
        stream<Notification, error?> notificationStream = check notifications->find({userId: userId});
        Notification[] userNotifications = check from Notification n in notificationStream select n;
        
        log:printInfo(string `Found ${userNotifications.length()} notifications for user ${userId}`);
        return userNotifications;
    }

    // Get all notifications (for admin/testing)
    resource function get notifications/all() returns Notification[]|error {
        log:printInfo("Fetching all notifications");
        
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection notifications = check db->getCollection("notifications");
        
        stream<Notification, error?> notificationStream = check notifications->find();
        Notification[] allNotifications = check from Notification n in notificationStream select n;
        
        log:printInfo(string `Found ${allNotifications.length()} total notifications`);
        return allNotifications;
    }
    
    // Mark notification as read
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

    // ✅ FIXED: Publish disruption - broadcasts to ALL passengers
    resource function post disruptions(@http:Payload DisruptionRequest request) returns json|error {
        log:printInfo(string `Received disruption for route: ${request.routeId}, severity: ${request.severity}`);
        
        // Get all registered users from passenger service
        http:Client passengerClient = check new ("http://passenger-service:9090");
        http:Response|error usersResp = passengerClient->get("/passenger/all");
        
        string[] userIds = [];
        
        if usersResp is http:Response && usersResp.statusCode == 200 {
            json|error usersJson = usersResp.getJsonPayload();
            if usersJson is json[] {
                foreach json user in usersJson {
                    string|error userId = user.userId.ensureType();
                    if userId is string {
                        userIds.push(userId);
                    }
                }
                log:printInfo(string `Got ${userIds.length()} users from passenger service`);
            }
        } else {
            log:printWarn("Could not fetch users from passenger service, getting from existing notifications");
            
            // Fallback: Get unique user IDs from existing notifications
            mongodb:Database db = check mongoClient->getDatabase(dbName);
            mongodb:Collection notifications = check db->getCollection("notifications");
            
            stream<Notification, error?> allNotifications = check notifications->find();
            
            check from Notification notif in allNotifications
                do {
                    if !userIds.some(id => id == notif.userId) {
                        userIds.push(notif.userId);
                    }
                };
            
            log:printInfo(string `Got ${userIds.length()} users from notifications`);
        }
        
        // Create notification for each user
        mongodb:Database db = check mongoClient->getDatabase(dbName);
        mongodb:Collection notifications = check db->getCollection("notifications");
        
        int notificationCount = 0;
        foreach string userId in userIds {
            Notification notification = {
                notificationId: uuid:createType1AsString(),
                userId: userId,
                notificationType: "DISRUPTION",
                message: string `⚠️ ${request.severity} disruption on route ${request.routeId}: ${request.message}`,
                status: "unread",
                createdAt: time:utcNow()
            };
            
            check notifications->insertOne(notification);
            notificationCount += 1;
            log:printInfo(string `Created disruption notification for user: ${userId}`);
        }
        
        log:printInfo(string `Created ${notificationCount} disruption notifications`);
        
        return {
            "message": "Disruption published and notifications created",
            "routeId": request.routeId,
            "severity": request.severity,
            "notifiedUsers": notificationCount
        };
    }
    
    // Health check
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
    // This is called from Kafka - for trip status changes
    // Not used for disruptions anymore (disruptions use /disruptions endpoint)
    string|error tripId = data.tripId.ensureType();
    string|error status = data.status.ensureType();

    if tripId is string && status is string {
        string message = string `🚌 Trip ${tripId} is now ${status}`;
        log:printInfo("SCHEDULE NOTIFICATION: " + message);
        io:println("\n" + message + "\n");
    }
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

// Helper function to publish to Kafka
function publishToKafka(string topic, json payload) returns error? {
    kafka:ProducerConfiguration producerConfig = {
        clientId: "notification-producer",
        acks: "all",
        retryCount: 3
    };
    
    kafka:Producer producer = check new (kafkaBootstrap, producerConfig);
    
    string message = payload.toJsonString();
    check producer->send({
        topic: topic,
        value: message.toBytes()
    });
    
    check producer->'flush();
    check producer->close();
    
    log:printInfo(string `Published event to Kafka topic: ${topic}`);
}