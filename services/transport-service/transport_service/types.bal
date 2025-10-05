import ballerina/time;

public type Route record {|
    string routeId;
    string name;
    string routeType;        // "bus" or "train"
    string[] stops;
    json schedule;
    boolean active;
    time:Utc createdAt;
|};

public type Trip record {|
    string tripId;
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    string status;           // "ON_TIME", "DELAYED", "CANCELLED"
    string vehicleId;
    time:Utc createdAt;
|};
