FROM jenkins/jenkins:lts

USER root

# ติดตั้ง Docker CLI และเครื่องมือพื้นฐาน
RUN apt-get update && \
    apt-get install -y docker.io git curl && \
    rm -rf /var/lib/apt/lists/*

# โฟลเดอร์เสริม (ถ้าต้องการ)
RUN mkdir -p /var/log/jenkins /var/cache/jenkins \
 && chown -R jenkins:jenkins /var/log/jenkins /var/cache/jenkins

# หมายเหตุ: เรื่องสิทธิ์เข้าถึง docker.sock จะจัดการตอนรัน (ดูสคริปต์ด้านล่าง)
USER jenkins
ENV JAVA_OPTS="-Xmx8192m"
