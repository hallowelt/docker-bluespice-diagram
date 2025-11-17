ARG BASE_IMAGE=alpine:3.20.3

FROM $BASE_IMAGE AS builder

ARG SHA512SUM_1=a46c8e37d4767b56a16dbdd8e81b80f25ad2edd5fba68b5099b9165cfffbe32bc923a601db8bb5cba50e8b1047a7906eb8c30ca176e1c0b8dfd85fbb9c54c6c2
ARG SHA512SUM_2=15f60e7918ec8c735e566defccab84b7d913f1d2518f48ae43985191a6b7d06da729107d0d3c58aa59651863018366443388960f1826b2546d4e6c59291abb7c

RUN apk add --no-cache wget tar \
    && wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.49/bin/apache-tomcat-10.1.49.tar.gz \
    || wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.49/bin/apache-tomcat-10.1.49.tar.gz \
    && echo "$SHA512SUM_1  apache-tomcat-10.1.49.tar.gz" | sha512sum -c - \
    && mkdir -p /opt/tomcat \
    && tar xzf apache-tomcat-10.1.49.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm apache-tomcat-10.1.49.tar.gz

RUN wget https://github.com/jgraph/drawio/releases/download/v29.0.3/draw.war \
    && echo "$SHA512SUM_2  draw.war" | sha512sum -c - \
        && rm -fr /opt/tomcat/webapps/* \
    && unzip draw.war -d /opt/tomcat/webapps/_diagram \
    && wget https://app.diagrams.net/js/extensions.min.js -O /opt/tomcat/webapps/_diagram/js/extensions.min.js \
    && ln -sf /opt/tomcat/webapps/_diagram /opt/tomcat/webapps/ROOT \
    && rm -rf draw.war


FROM $BASE_IMAGE AS main

ARG JAVA_OPTS="-Xverify:none"
ENV JAVA_OPTS=$JAVA_OPTS
ENV USER=tomcat
ARG UID=1000
ENV UID=$UID

RUN apk add --no-cache openjdk21 \
    && addgroup -g $UID $USER \
    && adduser -G $USER -u $UID --disabled-password --gecos "" $USER

COPY --from=builder --chown=tomcat:tomcat /opt/tomcat /opt/tomcat
EXPOSE 8080
USER $USER
ENTRYPOINT ["/opt/tomcat/bin/catalina.sh","run" ]
