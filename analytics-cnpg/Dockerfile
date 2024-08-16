ARG PG_VERSION=16
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install build dependencies for parquet_s3_fdw and its dependent libraries
RUN apt-get update && apt-get install -y \
    git \
    g++ \
    cmake \
    ninja-build \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build parquet_s3_fdw
RUN git clone https://github.com/duckdb/duckdb && \
    cd duckdb && \
    GEN=ninja make

RUN git clone https://github.com/duckdb/pg_duckdb.git \
    cd pg_duckdb && \
    make install

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
