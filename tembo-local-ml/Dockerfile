FROM quay.io/tembo/ml-cnpg:latest

USER root
RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
ENV PGDATA /var/lib/postgresql/data2
RUN mkdir -p $PGDATA
RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
USER postgres
RUN pg_ctl init
# Set permissive authentication
RUN echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf

RUN trunk install pgvector
RUN trunk install postgresml
RUN trunk install pg_embedding
RUN trunk install pg_cron
RUN trunk install pgmq
RUN trunk install vectorize
RUN trunk install pg_later

COPY enable-extensions.sql /docker-entrypoint-initdb.d/
COPY postgresql.conf ${PGDATA}/postgresql.conf
