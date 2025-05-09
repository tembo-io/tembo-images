ARG PG_VERSION=15
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install dependencies for running pgml
RUN  apt-get update \
  && apt-get install -y libopenblas-base \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Trunk Install Needed Extensions
RUN set -eux; \
  trunk install hstore_plpython3u; \
  trunk install jsonb_plpython3u; \
  trunk install ltree_plpython3u;

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26

# Install Python dependencies
ENV PATH=/var/lib/postgresql/.local/bin:$PATH
COPY --chown=postgres:postgres requirements.txt .
COPY --chown=postgres:postgres requirements-xformers.txt .
RUN set -eux; \
  pip3 install -r requirements.txt; \
  pip3 install -r requirements-xformers.txt --no-dependencies;

ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache
ENV VECTORIZE_SOCKET_URL=postgresql:///postgres?host=/controller/run&user=postgres&dbname=postgres
