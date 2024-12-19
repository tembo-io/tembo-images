ARG PG_VERSION=15
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install dependencies for running postgis and mobilitydb
RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    libgeos-dev \
    libproj-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    libgsl-dev \
    libjson-c-dev \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/OSGeo/gdal/releases/download/v3.6.0/gdal-3.6.0.tar.gz && \
    tar xvf gdal-3.6.0.tar.gz && \
    cd gdal-3.6.0 && \
    mkdir build && cd build && \
    cmake .. && \
    cmake --build . && \
    cmake --build . --target install

# Download and build PostGIS
RUN wget https://download.osgeo.org/postgis/source/postgis-3.4.0.tar.gz && \
    tar xvf postgis-3.4.0.tar.gz && \
    cd postgis-3.4.0 && \
    ./configure && \
    make && \
    make install

# Clone and build mobilitydb
RUN git clone https://github.com/MobilityDB/MobilityDB && \
    cd MobilityDB && \
    git checkout v1.2.0rc1 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
