FROM eclipse-temurin:8-jdk

ENV DOCKER=true
ENV TZ=Asia/Shanghai
ENV DOLPHINSCHEDULER_HOME=/opt/dolphinscheduler

RUN apt update && apt install -y sudo && rm -rf /var/lib/apt/lists/*

WORKDIR ${DOLPHINSCHEDULER_HOME}

COPY build/release-bin.tar.gz ${DOLPHINSCHEDULER_HOME}/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz

RUN tar -zxvf apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz --strip-components=1 && \
    rm -f apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz && \
    rm -rf /opt/dolphinscheduler/plugins && \
    mkdir -p /opt/dolphinscheduler/plugins

EXPOSE 12345 25333

CMD ["/bin/bash", "/opt/dolphinscheduler/api-server/bin/start.sh"]
