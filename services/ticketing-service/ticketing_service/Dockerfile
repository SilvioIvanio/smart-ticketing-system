FROM ballerina/jre11:v1

WORKDIR /home/ballerina

# Copy the built JAR file
COPY target/bin/*.jar ./

# Expose the service port
EXPOSE 9090

# Run the JAR file
CMD java -jar *.jar
