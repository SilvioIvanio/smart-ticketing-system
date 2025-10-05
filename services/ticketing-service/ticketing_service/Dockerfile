FROM ballerina/ballerina:2201.8.5
WORKDIR /app
COPY . .
RUN bal build
EXPOSE 9091
CMD bal run
