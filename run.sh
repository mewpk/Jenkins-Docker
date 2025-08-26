#!/usr/bin/env bash
set -euo pipefail

IMG_NAME="jenkins-master"
CONTAINER_NAME="jenkins-master"
VOLUME_NAME="jenkins_home"

echo "[1/6] Build Jenkins image..."
docker build -t "${IMG_NAME}" -f master/Dockerfile master

echo "[2/6] Create named volume (if not exists)..."
docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1 || docker volume create "${VOLUME_NAME}"

echo "[3/6] Remove old container (if exists)..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true


# --- Start Jenkins container ---
echo "[4/6] Start Jenkins container..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8080 -p 50000:50000 \
  -v "${VOLUME_NAME}:/var/jenkins_home" \
  "${IMG_NAME}"

echo "[5/6] Waiting for initial admin password..."
for i in {1..30}; do
  if docker exec "${CONTAINER_NAME}" test -f /var/jenkins_home/secrets/initialAdminPassword; then
    break
  fi
  echo "Waiting for Jenkins to generate the initialAdminPassword (Attempt $i/30)..."
  sleep 5
done

echo "------------------------------------------------------------"
echo "Jenkins is up at:  http://localhost:8080"
echo -n "InitialAdminPassword: "
docker exec "${CONTAINER_NAME}" cat /var/jenkins_home/secrets/initialAdminPassword
echo
echo "------------------------------------------------------------"
