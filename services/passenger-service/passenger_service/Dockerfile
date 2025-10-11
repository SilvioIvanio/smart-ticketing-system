FROM ballerina/jre17:v1
WORKDIR /home/ballerina

# Copy the built JAR file and config
COPY target/bin/*.jar ./
COPY Config.toml ./

EXPOSE 9090
CMD java -jar *.jar
