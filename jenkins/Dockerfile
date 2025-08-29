FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/jenkins /var/cache/jenkins \
 && chown -R jenkins:jenkins /var/log/jenkins /var/cache/jenkins

USER jenkins
ENV JAVA_OPTS="-Xmx8192m"
