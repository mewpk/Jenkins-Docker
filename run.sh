docker build -t jenkins-master -f master/Dockerfile .
docker build -t jenkins-data -f data/Dockerfile .
docker run --name=jenkins-data jenkins-data
docker run -p 8080:8080 -p 50000:50000 --name=jenkins-master --volumes-from=jenkins-data -d jenkins-master
docker ps -a