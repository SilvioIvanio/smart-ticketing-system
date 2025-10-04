# Smart Public Transport Ticketing System - Database Schema

This document defines the official MongoDB collections and document schemas. All services that interact with the database **MUST** adhere to these structures.

- **Database Name:** `ticketing_db`

---

### 1. `users` collection

*   **Purpose:** Stores passenger and administrator account information.
*   **Managed by:** `passenger-service` (for creation), other services may read.
*   **Schema:**
    ```json
    {
      "_id": "string (The user's unique ID, can be an email or a UUID)",
      "name": "string",
      "email": "string",
      "passwordHash": "string"
    }
    ```

---

### 2. `tickets` collection

*   **Purpose:** Stores the state and lifecycle of every ticket purchased.
*   **Managed by:** `ticketing-service`
*   **Schema:**
    ```json
    {
      "_id": "string (A unique UUID for the ticket)",
      "userId": "string (References the _id in the users collection)",
      "tripId": "string (Identifies the specific trip this ticket is for)",
      "status": "CREATED | PAID | VALIDATED | EXPIRED",
      "purchaseDate": "string (ISO 8601 format, e.g., '2025-10-04T10:00:00Z')"
    }
    ```
    *Note: The `status` field must be one of the four specified string values.*

---

### 3. `routes` collection

*   **Purpose:** Stores all transport routes and their scheduled trips.
*   **Managed by:** `transport-service` and `admin-service`.
*   **Schema:**
    ```json
    {
      "_id": "string (A unique UUID for the route)",
      "name": "string (e.g., 'Windhoek-Katutura Circle')",
      "transportType": "BUS | TRAIN",
      "trips": [
        {
          "tripId": "string (A unique UUID for this specific trip)",
          "departureTime": "string (e.g., '08:30')",
          "vehicleId": "string (e.g., 'BUS-101')"
        }
      ]
    }
    ```
    *Note: The `trips` field is an array of trip objects embedded within the route document.*