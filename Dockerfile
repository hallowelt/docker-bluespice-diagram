ARG BASE_IMAGE=alpine:3.20.3

FROM $BASE_IMAGE AS builder

ARG SHA256SUM_1=f799541380bfff2b674cefd86c5376d2d7d566b3a2e7c4579d2b491de8ec6c36
ARG SHA256SUM_2=89417f1e6e0b1498ea22d7ebb9ec3bed126719c0a1b9a1cb76ac31020027e6ee

RUN apk add --no-cache wget tar \
    && wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz \
    && echo "$SHA256SUM_1  apache-tomcat-10.1.34.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/tomcat \
    && tar xzf apache-tomcat-10.1.34.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm apache-tomcat-10.1.34.tar.gz

RUN wget https://github.com/jgraph/drawio/releases/download/v24.7.17/draw.war \
    && echo "$SHA256SUM_2  draw.war" | sha256sum -c - \
    && unzip draw.war /opt/tomcat/webapps/_diagram \
    && rm -rf draw.war


FROM $BASE_IMAGE AS main

ARG JAVA_OPTS="-Xverify:none"
ENV JAVA_OPTS=$JAVA_OPTS
ENV USER=tomcat
ARG UID=1000
ENV UID=$UID

COPY ./root-fs/usr/local/bin/startup.sh /usr/local/bin/

RUN apk add --no-cache openjdk21 \
    && addgroup -g $UID $USER \
    && adduser -G $USER -u $UID --disabled-password --gecos "" $USER \
    && chmod +x /usr/local/bin/startup.sh

COPY --from=builder --chown=tomcat:tomcat /opt/tomcat /opt/tomcat
EXPOSE 8080
USER $USER
ENTRYPOINT [ "/usr/local/bin/startup.sh" ]