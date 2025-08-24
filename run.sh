#!/bin/bash

echo "Building Jenkins master image..."
docker build -t jenkins-master -f master/Dockerfile .

echo "Building Jenkins data image..."
docker build -t jenkins-data -f data/Dockerfile .

echo "Creating Jenkins data container..."
docker run --name=jenkins-data jenkins-data

echo "Starting Jenkins master container..."
docker run -p 8080:8080 -p 50000:50000 --name=jenkins-master --volumes-from=jenkins-data -d jenkins-master

echo "Listing all containers..."
docker ps -a

echo "Fetching Jenkins initial admin password..."
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword