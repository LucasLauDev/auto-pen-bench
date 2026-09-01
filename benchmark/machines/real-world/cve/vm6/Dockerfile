FROM eclipse-temurin:8-jre

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends python3 libfindbin-libs-perl curl ca-certificates

COPY apache-druid-0.20.0-bin.tar.gz /tmp/druid.tar.gz
RUN set -ex \
    && mkdir -p /opt/druid \
    && tar xzf /tmp/druid.tar.gz --strip-components 1 -C /opt/druid \
    && rm /tmp/druid.tar.gz

COPY flag.txt /root/flag.txt

EXPOSE 8888
WORKDIR /opt/druid
CMD [ "/opt/druid/bin/start-nano-quickstart" ]