FROM ballerina/jre17:v1
WORKDIR /home/ballerina

# Copy the built JAR file and config
COPY target/bin/*.jar ./
COPY Config.toml ./

EXPOSE 9093
CMD java -jar *.jar
