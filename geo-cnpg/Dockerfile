ARG PG_VERSION=15
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install dependencies for running postgis and mobilitydb
RUN apt-get update && \
    apt-get install -y \
    libgeos-dev \
    libproj-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    libgdal-dev \
    libgsl-dev \
    libjson-c-dev
    && rm -rf /var/lib/apt/lists/*

# Download and build PostGIS
RUN wget https://download.osgeo.org/postgis/source/postgis-3.4.0.tar.gz && \
    tar xvf postgis-3.4.0.tar.gz && \
    cd postgis-3.4.0 && \
    ./configure && \
    make && \
    make install

# Clone and build mobilitydb
RUN git clone https://github.com/MobilityDB/MobilityDB
ARG RELEASE=v1.1.0rc1

RUN cd MobilityDB && \
    git fetch origin ${RELEASE} && \
    git checkout ${RELEASE} && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

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

ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache
ENV VECTORIZE_SOCKET_URL=postgresql:///postgres?host=/controller/run&user=postgres&dbname=postgres

