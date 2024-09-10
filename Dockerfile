ARG VERSION=8.15.1

FROM docker.elastic.co/elasticsearch/elasticsearch:${VERSION} AS baseline

FROM openjdk:21-jdk-buster AS patch

ARG VERSION
ENV VERSION=${VERSION}

WORKDIR /patch

COPY --from=baseline /usr/share/elasticsearch/lib /usr/share/elasticsearch/lib
COPY --from=baseline /usr/share/elasticsearch/modules/x-pack-core /usr/share/elasticsearch/modules/x-pack-core

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y zip

COPY patch.sh .
RUN bash patch.sh

FROM baseline

COPY --from=patch /patch/x-pack-core-* /usr/share/elasticsearch/modules/x-pack-core/
