# Build gosu with a current Go toolchain; Alpine's `go` package lags behind
# and carries Go stdlib CVEs, so build it here instead of via apk's go.
FROM golang:1.26.5-alpine AS gosu-builder
RUN apk add --no-cache git \
    && CGO_ENABLED=0 GOBIN=/usr/local/bin go install -ldflags="-s -w" github.com/tianon/gosu@1.19

FROM postgres:18-alpine

# Security update - CACHE_BUST is set by CI to force a fresh apk upgrade
ARG CACHE_BUST
# Update base packages to fix CVEs (e.g., zlib)
RUN apk upgrade --no-cache

# Install gettext for envsubst (required by init scripts that use environment variables)
RUN apk add --no-cache gettext

# Replace gosu with the version built on current Go (fixes Go stdlib CVEs)
RUN rm -f /usr/local/bin/gosu
COPY --from=gosu-builder /usr/local/bin/gosu /usr/local/bin/gosu
RUN gosu --version

# Install PostgreSQL extensions (pg_partman and pg_cron)
RUN apk add --no-cache --virtual .build-deps \
        git \
        build-base \
        postgresql-dev \
        clang21 \
        llvm21 \
    && cd /tmp \
    # Install pg_partman v5.3.0
    && git clone --branch v5.3.0 --depth 1 https://github.com/pgpartman/pg_partman.git \
    && cd pg_partman \
    && make \
    && make install \
    && cd /tmp \
    # Install pg_cron v1.6.7 for scheduled jobs
    && git clone --branch v1.6.7 --depth 1 https://github.com/citusdata/pg_cron.git \
    && cd pg_cron \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_partman /tmp/pg_cron \
    && apk del .build-deps

# Configure PostgreSQL to preload pg_cron
RUN echo "shared_preload_libraries = 'pg_cron'" >> /usr/local/share/postgresql/postgresql.conf.sample

# Copy extension initialization script
# Prefixed with 00- to ensure it runs before other init scripts (like 01-init-users.sh)
COPY 00-init-extensions.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Use the default postgres entrypoint
CMD ["postgres"]
