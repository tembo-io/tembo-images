# syntax=docker/dockerfile:1.7-labs
ARG BASE
ARG PG_VERSION=17.4
ARG PG_PREFIX=/usr/lib/postgresql
ARG TEMBO_VOLUME=/var/lib/postgresql/tembo
ARG CNPG_VOLUME=/var/lib/postgresql/data
ARG TEMBO_LIB_DIR=${TEMBO_VOLUME}/lib

##############################################################################
# Build trunk.
FROM rust:1.83-bookworm AS trunk
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
RUN cargo install pg-trunk

##############################################################################
# Build PostgreSQL.
FROM ${BASE} AS build
ARG PG_VERSION PG_PREFIX TEMBO_VOLUME
WORKDIR /work

# Upgrade to the latest packages and install dependencies.
ENV DEBIAN_FRONTEND=noninteractive
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
    bison \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools

ADD https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.bz2 .

RUN tar jxf postgresql-${PG_VERSION}.tar.bz2

WORKDIR /work/postgresql-${PG_VERSION}

RUN set -ex; \
    ./configure \
        CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer" \
        LDFLAGS="-Wl,-z,relro -Wl,-z,now" \
        --prefix="${PG_PREFIX}" \
        --datarootdir="${TEMBO_VOLUME}/share" \
        --docdir="${PG_PREFIX}/doc" \
        --htmldir="${PG_PREFIX}/html" \
        --localedir="${PG_PREFIX}/locale" \
        --mandir="${PG_PREFIX}/man" \
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
        --with-selinux; \
    make -j$(nproc); \
    make install

##############################################################################
# Build the base image.
FROM ${BASE} AS install
ARG PG_VERSION TEMBO_VOLUME CNPG_VOLUME PACKAGES TEMBO_LIB_DIR PG_PREFIX

# Copy the PostgreSQL files and trunk.
COPY --link --from=build --parents /var/lib/./postgresql /var/lib/
COPY --link --from=build --parents /usr/lib/./postgresql /usr/lib/
COPY --link --from=trunk /usr/local/cargo/bin/trunk /usr/local/bin/trunk

# Upgrade to the latest packages and install dependencies.
ARG PACKAGES
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
    locales \
    locales-all \
    ssl-cert \
    ca-certificates \
    tzdata \
    libssl3 \
    libgssapi-krb5-2 \
    libxml2 \
    libxslt1.1 \
    libreadline8 \
    libtcl8.6 \
    xz-utils \
    libgss3 \
    libkrb5-3 \
    ${PACKAGES}

# Create the Postgres user and set its uid to what CNPG expects.
RUN groupadd -r postgres --gid=999 && \
	useradd -r -g postgres --uid=26 --home-dir=${CNPG_VOLUME} --shell=/bin/bash postgres && \
    mkdir -p ${CNPG_VOLUME}; \
    chown -R postgres:postgres ${CNPG_VOLUME};

# Add the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/

# Clean up cache and finish configuration.
ENV PATH=${PG_PREFIX}/bin:$PATH
RUN set -xe; \
    apt-get clean -y; \
    # Set up en_US.UTF-8
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
    # Configure ldd to find additional shared libraries in TEMBO_LIB_DIR and
    # and Postgres versioned libraries in PG_LIB_DIR.
    printf "%s\n" "$(pg_config --libdir)" > /etc/ld.so.conf.d/postgres.conf; \
    printf "${TEMBO_LIB_DIR}\n" > /etc/ld.so.conf.d/tembo.conf; \
    mkdir -p "${TEMBO_VOLUME}"; \
    chown -R postgres:postgres ${TEMBO_VOLUME}; \
    mkdir -p "${TEMBO_LIB_DIR}"; \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*; \
    ldconfig;

##############################################################################
# Build the postgres image as a single layer.
FROM scratch AS postgres
ARG PG_PREFIX TEMBO_VOLUME CNPG_VOLUME

COPY --link --from=install / /
WORKDIR ${CNPG_VOLUME}
ENV TZ=Etc/UTC LANG=en_US.utf8 PATH=${PG_PREFIX}/bin:$PATH CNPG_VOLUME=${CNPG_VOLUME}
STOPSIGNAL SIGINT
USER 26
ENTRYPOINT ["docker-entrypoint.sh"]

##############################################################################
# Install extras for Tembo Cloud.
FROM build AS build-cloud
ENV PATH=${PG_PREFIX}/bin:$PATH

RUN set -ex; \
    # Build and install auto_explain and pg_stat_statements.
    make -C contrib/auto_explain install; \
    make -C contrib/pg_stat_statements install; \
    cp -lr $(pg_config --sharedir) /tmp/pg_sharedir;

##############################################################################
# Add the Tembo Cloud extras.
FROM postgres AS postgres-cloud

COPY --link --from=build-cloud --parents /var/lib/./postgresql /var/lib/
COPY --link --from=build-cloud /tmp /tmp/

WORKDIR ${TEMBO_VOLUME}
