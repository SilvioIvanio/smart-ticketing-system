FROM ballerina/jre11:v1
WORKDIR /home/ballerina

# Copy the built JAR file and config
COPY target/bin/*.jar ./
COPY Config.toml ./

CMD java -jar *.jar
