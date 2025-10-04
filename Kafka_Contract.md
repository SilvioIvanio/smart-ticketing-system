# Kafka Communication Contract - Smart Public Transport Ticketing System

This document defines the official topics and message schemas for the Smart Ticketing System. All services **MUST** adhere to these contracts to ensure system interoperability.

---

### 1. `ticket.requests`

*   **Purpose:** Sent by the `passenger-service` to initiate the purchase of a new ticket.
*   **Producer:** `passenger-service`
*   **Consumer:** `ticketing-service`
*   **Schema:**
    ```json
    {
      "userId": "string",
      "tripId": "string",
      "ticketType": "SINGLE_RIDE"
    }
    ```

---

### 2. `payment.requests`

*   **Purpose:** Sent by the `ticketing-service` to the `payment-service` to process a transaction for a newly created ticket.
*   **Producer:** `ticketing-service`
*   **Consumer:** `payment-service`
*   **Schema:**
    ```json
    {
      "ticketId": "string",
      "amount": "float",
      "userId": "string"
    }
    ```

---

### 3. `payment.events`

*   **Purpose:** An event published by the `payment-service` to announce the outcome of a payment transaction.
*   **Producer:** `payment-service`
*   **Consumers:** `ticketing-service`, `notification-service`
*   **Schema:**
    ```json
    {
      "ticketId": "string",
      "status": "CONFIRMED | FAILED",
      "transactionId": "string"
    }
    ```
    *Note: The `status` field must be either the string "CONFIRMED" or "FAILED".*

---

### 4. `schedule.events`

*   **Purpose:** An event published by the `admin-service` to announce a disruption or change to a transport schedule.
*   **Producer:** `admin-service`
*   **Consumer:** `notification-service`
*   **Schema:**
    ```json
    {
      "eventType": "TRIP_DELAYED | TRIP_CANCELLED",
      "tripId": "string",
      "details": "string"
    }
    ```
    *Note: The `eventType` field must be either the string "TRIP_DELAYED" or "TRIP_CANCELLED".*