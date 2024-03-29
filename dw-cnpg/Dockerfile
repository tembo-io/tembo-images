ARG PG_VERSION=15
ARG TAG=latest

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

# Clone and build AWS SDK for C++
RUN git clone https://github.com/aws/aws-sdk-cpp.git && \
    cd aws-sdk-cpp && \
    git checkout 1.9.263 && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake -DBUILD_ONLY="s3;core;config;sts;cognito-identity;transfer;identity-management" -DAUTORUN_UNIT_TESTS=OFF -DCMAKE_CXX_FLAGS=-Wno-error=deprecated-declarations .. && \
    make -j$(nproc) && \
    make install && \
    cd ../../ && rm -rf aws-sdk-cpp

# Clone and build Apache Arrow
RUN git clone https://github.com/apache/arrow.git && \
    cd arrow && \
    git checkout apache-arrow-7.0.1 && \
    cd cpp && \
    mkdir build && cd build && \
    cmake -DARROW_PARQUET=ON -DARROW_S3=ON -DARROW_WITH_SNAPPY=ON .. && \ 
    make -j$(nproc) && \
    make install && \
    cd ../../ && rm -rf arrow

# Clone and build parquet_s3_fdw
RUN git clone https://github.com/pgspider/parquet_s3_fdw.git && \
    cd parquet_s3_fdw && \
    git checkout v1.1.0 && \
    make USE_PGXS=1 install && \
    cd .. && rm -rf parquet_s3_fdw

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
