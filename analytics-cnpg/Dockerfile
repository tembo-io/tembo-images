ARG PG_VERSION=16
ARG TAG=latest

FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG} AS build
USER root
WORKDIR /work


# Install build dependencies for parquet_s3_fdw and its dependent libraries
RUN apt-get update && apt-get install -y \
    automake \
    bison \
    build-essential \
    ccache \
    cmake \
    flex \
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
    pkg-config \
    protobuf-compiler \
    xsltproc \
    zlib1g-dev

# Clone and build Tembo's fork of parquet_s3_fdw (required for pg_tier).
RUN git clone https://github.com/tembo-io/tembo_parquet_s3_fdw.git \
    && (cd tembo_parquet_s3_fdw && git checkout v1.1.4) \
    && make -C tembo_parquet_s3_fdw USE_PGXS=1 install DESTDIR="$PWD/target"

# Copy the files to the final image.
FROM quay.io/tembo/standard-cnpg:${PG_VERSION}-${TAG}
USER root
COPY --from=build /work/target/./ /

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
