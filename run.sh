#!/usr/bin/env bash
set -euo pipefail

IMG_NAME=jenkins-master
CONTAINER_NAME=jenkins-master
VOLUME_NAME=jenkins_home

echo "[1/5] Build Jenkins image..."
docker build -t ${IMG_NAME} -f master/Dockerfile master

echo "[2/5] Create named volume (if not exists)..."
docker volume inspect ${VOLUME_NAME} >/dev/null 2>&1 || docker volume create ${VOLUME_NAME}

echo "[3/5] Remove old container (if exists)..."
docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true

# ดึง GID ของ docker.sock จากโฮสต์ เพื่อให้ jenkins user เข้าถึงได้
DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

echo "[4/5] Start Jenkins container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 8080:8080 -p 50000:50000 \
  -v ${VOLUME_NAME}:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --user 1000:1000 \
  --group-add ${DOCKER_SOCK_GID} \
  ${IMG_NAME}

echo "[5/5] Waiting for initial admin password..."
until docker exec ${CONTAINER_NAME} test -f /var/jenkins_home/secrets/initialAdminPassword; do
  sleep 2
done

echo "------------------------------------------------------------"
echo "Jenkins is up at:  http://localhost:8080"
echo -n "InitialAdminPassword: "
docker exec ${CONTAINER_NAME} cat /var/jenkins_home/secrets/initialAdminPassword
echo
echo "------------------------------------------------------------"
