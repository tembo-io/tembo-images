FROM quay.io/tembo/ml-cnpg:latest

USER root
RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
ENV PGDATA /var/lib/postgresql/data2
RUN mkdir -p $PGDATA
RUN chown -R postgres:postgres $PGDATA && \
    chmod -R 0700 $PGDATA
RUN mkdir -p /controller/run
RUN chown -R postgres:postgres /controller/run
USER postgres
RUN pg_ctl init
# Set permissive authentication


RUN trunk install pgvector --version 0.4.4
RUN trunk install postgresml --version 2.7.1
RUN trunk install pg_embedding --version 0.1.0
RUN trunk install pg_cron --version 1.5.2
RUN trunk install pgmq --version 0.14.2
RUN trunk install pg_later --version 0.0.8
RUN trunk install vectorize --version 0.0.2

RUN echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf

COPY enable-extensions.sql /docker-entrypoint-initdb.d/
COPY postgresql.conf ${PGDATA}/postgresql.conf
