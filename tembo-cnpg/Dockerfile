# syntax=docker/dockerfile:1.7-labs
FROM quay.io/tembo/ubuntu:24.04 AS build
ARG PG_VERSION 17.4
ARG PG_MAJOR=${PG_VERSION%%.*}
ARG PG_PREFIX=/usr/lib/postgresql/${PG_MAJOR}
ARG PG_HOME_DIR=/var/lib/postgresql
ARG DATA_ROOT_DIR=${PG_HOME_DIR}/data/tembo
ARG PG_LIB_DIR=${DATA_ROOT_DIR}/${PG_MAJOR}/lib

WORKDIR /work

# Upgrade to the latest packages and install dependencies.
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    locales \
    libreadline-dev \
    zlib1g-dev \
    build-essential \
    python3-dev \
    tcl-dev \
    libxslt1-dev \
    libperl-dev \
    libpam0g-dev \
    libssl-dev \
    xz-utils \
    libnss-wrapper \
    llvm \
    clang \
    icu-devtools \
    pkg-config \
    libgss-dev \
    libkrb5-dev \
    uuid-dev \
    gettext \
    liblz4-dev \
    libsystemd-dev \
    libselinux1-dev \
    libzstd-dev \
    flex \
    bison;

ADD https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.bz2 .

RUN tar jxf postgresql-${PG_VERSION}.tar.bz2

RUN cd postgresql-${PG_VERSION} \
    && ./configure \
        CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer" \
        LDFLAGS="-Wl,-z,relro -Wl,-z,now" \
        --prefix="${PG_PREFIX}" \
        --datarootdir="${DATA_ROOT_DIR}" \
        --libdir="${PG_LIB_DIR}" \
        --with-perl \
        --with-python \
        --with-tcl \
        --with-pam \
        --with-libxml \
        --with-libxslt \
        --with-openssl \
        --enable-nls \
        --enable-thread-safety \
        --enable-debug \
        --disable-rpath \
        --with-uuid=e2fs \
        --with-gnu-ld \
        --with-gssapi \
        --with-pgport=5432 \
        --with-system-tzdata=/usr/share/zoneinfo \
        --with-icu \
        --with-llvm \
        --with-lz4 \
        --with-zstd \
        --with-systemd \
        --with-selinux \
    && make -j$(nproc) \
    && make install

# Build the base image.
FROM quay.io/tembo/ubuntu:24.04
ARG PG_VERSION 17.4
ARG PG_MAJOR=${PG_VERSION%%.*}
ARG PG_PREFIX=/usr/lib/postgresql/${PG_MAJOR}
ARG PG_HOME_DIR=/var/lib/postgresql
ARG DATA_ROOT_DIR=${PG_HOME_DIR}/data/tembo
ARG PG_LIB_DIR=${DATA_ROOT_DIR}/${PG_MAJOR}/lib
ARG TEMBO_LIB_DIR=DATA_ROOT_DIR/lib

# Copy the PostgreSQL files from build.
COPY --parents --from=build /var/lib/./postgresql /var/lib/
COPY --parents --from=build /usr/lib/./postgresql /usr/lib/

# Upgrade to the latest packages and install dependencies.
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        locales \
        locales-all \
        ssl-cert \
        ca-certificates \
        tzdata \
        libssl3 \
        libgssapi-krb5-2 \
        libicu74 \
        libllvm19 \
        libxml2 \
        libxslt1.1 \
        libreadline8 \
        libpython3.12 \
        libtcl8.6 \
        libperl5.38 \
        xz-utils \
        libgss3 \
        libkrb5-3 \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    # Set up en_US.UTF-8
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    # Set the postgres user's permissions
    && groupadd -r postgres --gid=999 \
    && useradd -r -g postgres --uid=999 --home-dir=${PG_HOME_DIR} --shell=/bin/bash postgres \
    && mkdir -p ${PG_HOME_DIR} \
    && chown -R postgres:postgres ${PG_HOME_DIR} \
    # Configure ldd to find additional shared libraries in TEMBO_LIB_DIR and
    # and Postgres versioned libraries in PG_LIB_DIR.
    && echo "${PG_LIB_DIR}" > /etc/ld.so.conf.d/postgres.conf \
    && echo "${TEMBO_LIB_DIR}" > /etc/ld.so.conf.d/tembo.conf \
    && mkdir -p "${TEMBO_LIB_DIR}/lib" \
    && ldconfig

WORKDIR ${PG_HOME_DIR}
ENV TZ=Etc/UTC, LANG=en_US.utf8, PATH=$PATH:${PG_PREFIX}/bin
STOPSIGNAL SIGINT
USER postgres
CMD ["postgres"]
