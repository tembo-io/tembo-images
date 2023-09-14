FROM rust:1.70-bookworm as builder

ARG TRUNK_VER=0.10.5

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse 
RUN cargo install --version $TRUNK_VER pg-trunk

FROM quay.io/tembo/tembo-pg-slim:15.3.0-tembo-pg-slim.1-cd62faf
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

# Install duckdb libs
RUN wget https://github.com/duckdb/duckdb/releases/download/v0.8.1/libduckdb-linux-amd64.zip && \
    unzip libduckdb-linux-amd64.zip && \
    cp libduckdb.so /usr/lib/x86_64-linux-gnu/ && \
    rm -rf libduckdb-linux-amd64.zip libduckdb.so

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
RUN trunk install pg_stat_statements

# Install auto_explain
RUN trunk install auto_explain

# cache pg_stat_statements and auto_explain and pg_stat_kcache to temp directory
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
