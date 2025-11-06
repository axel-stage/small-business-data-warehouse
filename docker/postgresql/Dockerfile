# -------------------------------
# Dockerfile for PostgreSQL
# -------------------------------
ARG IMAGE=postgres:16.3

FROM $IMAGE

ARG TODAY=$(date +%Y-%m-%d)

LABEL author="dataengineer24"
LABEL description="PostgreSQL with pgtap extension"
LABEL version="1.0"
LABEL build-date=${TODAY}

USER root

# install pgtab for postgresql unit testing
RUN apt update && \
    apt install -y --no-install-recommends \
    postgresql-16-pgtap && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# copy in the entrypoint script which runs after container start
COPY entrypoint-postgres.sh /docker-entrypoint-initdb.d/entrypoint-postgres.sh