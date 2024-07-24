ARG PG_VERSION=16
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install dependencies for running pgml
RUN  apt-get update \
  && apt-get install -y \
      libopenblas-base \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Trunk Install Needed Extensions
RUN set -eux; \
  trunk install hstore_plpython3u; \
  trunk install jsonb_plpython3u; \
  trunk install ltree_plpython3u;

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

RUN echo "deb [trusted=yes] https://apt.postgresml.org $(lsb_release -cs) main" > /etc/apt/sources.list.d/postgresml.list
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null      
ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive
ARG PG_VERSION=16
RUN apt-get update -y && apt-get install -y git postgresml-${PG_VERSION}

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26

ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache
ENV VECTORIZE_SOCKET_URL=postgresql:///postgres?host=/controller/run&user=postgres&dbname=postgres
