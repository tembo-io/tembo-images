FROM quay.io/tembo/standard-cnpg:15.3.0-1-795fc99
USER root

ARG PGML_VERSION=2.8.2

WORKDIR /

# Install dependencies for running pgml
RUN  apt-get update \
  && apt-get install -y \
    bison \
    build-essential \
    clang \
    cmake \
    flex \
    libclang-dev \
    libopenblas-dev \
    libpython3-dev \
    libreadline-dev \
    libssl-dev \
    pkg-config \
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

# install pgml
RUN echo "deb [trusted=yes] https://apt.postgresml.org $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list
RUN apt-get update && apt-get install -y postgresql-pgml-15=2.8.1

# RUN git clone https://github.com/postgresml/postgresml && \
#   cd postgresml && \
#   git submodule update --init --recursive && \
#   make && \
#   make install && \
#   cd .. && \
#   rm -rf postgresml

ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache
ENV VECTORIZE_SOCKET_URL=postgresql:///postgres?host=/controller/run&user=postgres&dbname=postgres
