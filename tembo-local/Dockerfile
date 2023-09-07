FROM quay.io/tembo/standard-cnpg:latest

USER root

RUN apt-get update && \
    apt-get install -y vim && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
ENV PGDATA /var/lib/postgresql/data2
RUN mkdir -p $PGDATA
RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
USER postgres
RUN pg_ctl init
RUN mkdir -p $PGDATA/extra-configs
RUN mkdir -p $PGDATA/startup-scripts
# Set permissive authentication
# This image is intended for local testing
RUN echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf
COPY postgresql.conf ${PGDATA}/postgresql.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV PGHOST=localhost
ENV PGPORT=5432
ENV PGDATABASE=postgres
ENV PGUSER=postgres

CMD ["entrypoint.sh"]
