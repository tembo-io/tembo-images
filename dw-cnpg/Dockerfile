ARG PG_VERSION=15
ARG TAG=4252623

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root

WORKDIR /

# Install build dependencies for parquet_s3_fdw and its dependent libraries
RUN apt-get update && apt-get install -y \
    automake \
    bison \
    build-essential \
    ccache \
    cmake \
    flex \
    g++ \
    git \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libevent-dev \
    libprotobuf-dev \
    libprotoc-dev \
    libreadline-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    libxml2-utils \
    libxslt-dev \
    make \
    pkg-config \
    protobuf-compiler \
    xsltproc \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build parquet_s3_fdw
RUN git clone https://github.com/tembo-io/tembo_parquet_s3_fdw.git && \
    cd tembo_parquet_s3_fdw && \
    git checkout v1.1.4 && \
    make USE_PGXS=1 install && \
    cd .. && rm -rf tembo_parquet_s3_fdw

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
