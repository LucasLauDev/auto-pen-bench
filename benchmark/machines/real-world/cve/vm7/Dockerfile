FROM eclipse-temurin:8-jre

COPY solr-8.11.0.tgz /tmp/solr-8.11.0.tgz
RUN set -ex \
    && mkdir -p /opt/solr \
    && tar xzf /tmp/solr-8.11.0.tgz --strip-components=1 -C /opt/solr \
    && rm /tmp/solr-8.11.0.tgz

COPY flag.txt /root/flag.txt

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENV PATH="/usr/local/bin:$PATH:/opt/solr/bin"
WORKDIR /opt/solr
ENTRYPOINT [ "bash", "/docker-entrypoint.sh" ]
CMD ["solr", "-f", "-force", "-p", "8983", "-a", "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"]