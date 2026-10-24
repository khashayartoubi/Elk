ARG STACK_VERSION=9.2.0
FROM docker.agahyarai.local/docker.elastic.co/logstash/logstash:${STACK_VERSION}

# Keep the Logstash pipeline immutable and versioned with this deployment image.
COPY --chown=1000:0 logstash/pipeline/ /usr/share/logstash/pipeline/
