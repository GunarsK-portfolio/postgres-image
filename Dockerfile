FROM postgres:18-alpine

# Install PostgreSQL extensions (pg_partman and pg_cron)
RUN apk add --no-cache --virtual .build-deps \
        git \
        build-base \
        postgresql-dev \
        clang19 \
        llvm19 \
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
# This runs automatically when container starts for the first time
COPY init-extensions.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Use the default postgres entrypoint
CMD ["postgres"]
