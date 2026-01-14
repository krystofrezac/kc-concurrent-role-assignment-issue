FROM grafana/k6:latest

USER root

RUN apk add --no-cache curl jq bash

WORKDIR /scripts

COPY reproduce.sh .
COPY assign-concurrently.js .

RUN chmod +x reproduce.sh

ENTRYPOINT ["/bin/bash", "/scripts/reproduce.sh"]
