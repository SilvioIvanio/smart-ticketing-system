FROM ballerina/jre11:v1
WORKDIR /home/ballerina
COPY target/bin/*.jar ./
# No specific port exposed (background services)
CMD java -jar *.jar
