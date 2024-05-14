ARG PG_VERSION=15
ARG TAG=latest

FROM rust:1.74-bookworm as builder

ARG TRUNK_VER=0.12.21

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse 
RUN cargo install --version $TRUNK_VER pg-trunk

FROM quay.io/tembo/tembo-pg-slim:${PG_VERSION}-${TAG}

USER root

# Install trunk
COPY --from=builder /usr/local/cargo/bin/trunk /usr/bin/trunk
COPY ./requirements.txt .

# Install extension dependencies
RUN set -eux; \
      apt-get update && apt-get install -y \
          libmysqlclient-dev \
          libgeos-dev \
          libproj-dev \
          libjson-c-dev \
          libjson-perl \
          libprotobuf-c-dev \
          libxml2-dev \
          libboost-serialization1.74-dev \
          libhiredis-dev \
          libsybdb5 \
          r-base-core \
          openssl \
          libpcre2-8-0 \
          libgroonga0 \
          libopenblas0-pthread \
          libcurl4 \
          libsodium23 \
          libgcc-s1 \
          librdkafka1 \
          libgdal30 \
          libcrypt1 \
          liburiparser1 \
          libfreetype6 \
          libgomp1 \
          libssl3 \
          libsfcgal1 \
          openjdk-11-jdk \
          libaio1 \
          wget \
          libbson-dev \
          cmake \
      ; \
      apt-get autoremove -y; \
      apt-get clean -y; \
      rm -rf /var/lib/apt/lists/*

# Create a symlink for libjvm.so
RUN ln -s /usr/lib/jvm/java-11-openjdk-amd64/lib/server/libjvm.so /usr/lib/x86_64-linux-gnu/libjvm.so

# Install Oracle Instant Client libraries
RUN curl -o instantclient-basiclite-linux.x64-19.20.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/1920000/instantclient-basiclite-linux.x64-19.20.0.0.0dbru.zip && \
    unzip instantclient-basiclite-linux.x64-19.20.0.0.0dbru.zip && \
    cp instantclient_19_20/libclntsh.so.19.1 instantclient_19_20/libnnz19.so instantclient_19_20/libclntshcore.so.19.1 /usr/lib/x86_64-linux-gnu/ && \
    rm -rf instantclient_19_20 && \
    rm instantclient-basiclite-linux.x64-19.20.0.0.0dbru.zip

# Install barman-cloud
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install --upgrade pip; \
# TODO: Remove --no-deps once https://github.com/pypa/pip/issues/9644 is solved
	pip3 install --no-deps -r requirements.txt; \
  apt-get autoremove -y; \
  apt-get clean; \
	rm -rf /var/lib/apt/lists/*;

# Install pg_stat_statements
RUN /usr/bin/trunk install pg_stat_statements

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

# Install auto_explain
RUN /usr/bin/trunk install auto_explain

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

# cache pg_stat_statements and auto_explain and pg_stat_kcache to temp directory
RUN set -eux; \
	    mkdir /tmp/pg_pkglibdir; \
	    mkdir /tmp/pg_sharedir; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir

# cache all extensions
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV XDG_CACHE_HOME=/var/lib/postgresql/data/tembo/.cache

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
