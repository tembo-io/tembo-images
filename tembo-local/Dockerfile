FROM quay.io/tembo/standard-cnpg:latest

USER root

# Existing commands
RUN apt-get update && \
    apt-get install -y vim openssl && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Set up the environment for the data directory
ENV PGDATA /var/lib/postgresql/data2
RUN mkdir -p $PGDATA && \
    chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA

# Generate self-signed certificate
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/CN=*.local.tembo.io" \
    -keyout /var/lib/postgresql/server.key \
    -out /var/lib/postgresql/server.crt && \
    chown postgres:postgres /var/lib/postgresql/server.* && \
    chmod 600 /var/lib/postgresql/server.key

USER postgres

# Initialize the database
RUN pg_ctl -c init

# Other setup (if any)
RUN mkdir -p $PGDATA/extra-configs
RUN mkdir -p $PGDATA/startup-scripts

# Set permissive authentication (for local testing)
RUN echo "hostssl all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf

# Copy configuration files
COPY postgresql.conf ${PGDATA}/postgresql.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set environment variables
ENV PGHOST=localhost
ENV PGPORT=5432
ENV PGDATABASE=postgres
ENV PGUSER=postgres

# Entry point
CMD ["entrypoint.sh"]
