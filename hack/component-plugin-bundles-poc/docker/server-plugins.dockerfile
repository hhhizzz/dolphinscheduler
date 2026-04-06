FROM eclipse-temurin:8-jdk

ENV TZ=Asia/Shanghai
ENV DOLPHINSCHEDULER_HOME=/opt/dolphinscheduler

WORKDIR ${DOLPHINSCHEDULER_HOME}

COPY build/staging-bin.tar.gz ${DOLPHINSCHEDULER_HOME}/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz
COPY docker/prune-server-plugins.sh /usr/local/bin/prune-server-plugins.sh

RUN tar -zxvf apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz --strip-components=1 && \
    rm -f apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz && \
    bash /usr/local/bin/prune-server-plugins.sh

CMD ["/bin/bash", "-lc", "find /opt/dolphinscheduler/plugins -maxdepth 2 -type f | sort"]
