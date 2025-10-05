#!/bin/bash

echo "Building all services..."

cd services/passenger-service/passenger_service
echo "Building Passenger Service..."
bal build
cd ../../..

cd services/ticketing-service/ticketing_service
echo "Building Ticketing Service..."
bal build
cd ../../..

cd services/payment-service/payment_service
echo "Building Payment Service..."
bal build
cd ../../..

cd services/transport-service/transport_service
echo "Building Transport Service..."
bal build
cd ../../..

cd services/notification-service/notification_service
echo "Building Notification Service..."
bal build
cd ../../..

cd services/admin-service/admin_service
echo "Building Admin Service..."
bal build
cd ../../..

echo "All services built successfully!"
