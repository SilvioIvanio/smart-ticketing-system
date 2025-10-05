# Use official Ballerina image as base
FROM ballerina/ballerina:2201.8.5

# Set working directory
WORKDIR /app

# Copy all project files
COPY . .

# Build the Ballerina project
RUN bal build

# Expose the service port
EXPOSE 9090

# Run the service when container starts
CMD bal run
