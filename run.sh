#!/usr/bin/env bash
set -euo pipefail

IMG_NAME=jenkins-master
CONTAINER_NAME=jenkins-master
VOLUME_NAME=jenkins_home

# --- helper: ตรวจสอบว่า Orbstack กำลังทำงาน ---
check_orbstack() {
  if [ -d "$HOME/.orbstack" ]; then
    echo "[INFO] Orbstack detected. Using .orbstack/docker.sock"
    return 0  # ใช้ Orbstack
  else
    echo "[INFO] No Orbstack detected. Using default docker.sock"
    return 1  # ไม่ใช้ Orbstack
  fi
}

# กำหนดค่าเริ่มต้นสำหรับ USER_FLAG และ GROUP_ADD
USER_FLAG=""
GROUP_ADD=""

echo "[1/6] Build Jenkins image..."
docker build -t "${IMG_NAME}" -f master/Dockerfile master

echo "[2/6] Create named volume (if not exists)..."
docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1 || docker volume create "${VOLUME_NAME}"

echo "[3/6] Remove old container (if exists)..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

# --- ตรวจสอบ Orbstack และ mount docker.sock ตามสถานการณ์ ---
DOCKER_SOCK_MOUNT=""
if check_orbstack; then
  DOCKER_SOCK_MOUNT="-v $HOME/.orbstack/run/docker.sock:/var/run/docker.sock"
else
  DOCKER_SOCK_MOUNT="-v /var/run/docker.sock:/var/run/docker.sock"
fi

echo "[4/6] Start Jenkins container..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8080 -p 50000:50000 \
  -v "${VOLUME_NAME}:/var/jenkins_home" \
  ${DOCKER_SOCK_MOUNT} \
  ${USER_FLAG} \
  ${GROUP_ADD} \
  "${IMG_NAME}"

echo "[5/6] Waiting for initial admin password..."
until docker exec "${CONTAINER_NAME}" test -f /var/jenkins_home/secrets/initialAdminPassword; do
  sleep 2
done

echo "------------------------------------------------------------"
echo "Jenkins is up at:  http://localhost:8080"
echo -n "InitialAdminPassword: "
docker exec "${CONTAINER_NAME}" cat /var/jenkins_home/secrets/initialAdminPassword
echo
echo "------------------------------------------------------------"
