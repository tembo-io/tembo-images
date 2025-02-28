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
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

ARG ARROW_VERSION=19.0.0
RUN wget "https://github.com/apache/arrow/releases/download/apache-arrow-${ARROW_VERSION}/apache-arrow-${ARROW_VERSION}.tar.gz" \
    && tar zxf "apache-arrow-${ARROW_VERSION}.tar.gz" \
    && cd "apache-arrow-${ARROW_VERSION}/cpp" \
    && cmake -S . -B build -DARROW_PARQUET=ON -DARROW_S3=ON -DARROW_WITH_SNAPPY=ON \
    && cmake --build build  \
    && cmake --install build \
    && cd ../.. && rm -rf "apache-arrow-${ARROW_VERSION}*"

# Download and install GDAL.
ARG GDAL_VERSION=3.10.1
RUN wget https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
    && tar xvf "gdal-${GDAL_VERSION}.tar.gz" \
    && cmake -S "gdal-${GDAL_VERSION}" -B "gdal-${GDAL_VERSION}/build" \
    && cmake --build "gdal-${GDAL_VERSION}/build" \
    && cmake --build "gdal-${GDAL_VERSION}/build" --target install \
    && rm -rf "gdal-${GDAL_VERSION}*"

# Install PostGIS and clone and build MobilityDB
RUN /usr/bin/trunk install postgis --version 3.5.0 \
    && git clone --depth 1 --branch v1.2.0 https://github.com/MobilityDB/MobilityDB \
    && cmake -S MobilityDB -B MobilityDB/build \
    && make -C MobilityDB/build -j8 install \
    && rm -rf MobilityDB

# cache all extensions
RUN set -eux; \
    ldconfig; \
    cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
