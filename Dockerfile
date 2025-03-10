# syntax=docker/dockerfile:1.7-labs
ARG BASE
ARG OS_NAME
ARG PG_VERSION
ARG PG_MAJOR=${PG_VERSION%%.*}
ARG PG_PREFIX=/usr/lib/postgresql
ARG PG_HOME=/var/lib/postgresql
ARG CNPG_VOLUME=${PG_HOME}/data

# Tembo-specific volume mount, sharedir, dynamic_library_path target, and
# System LLD dir.
ARG TEMBO_VOLUME=${PG_HOME}/tembo
ARG TEMBO_SHARE_DIR=${TEMBO_VOLUME}/share
ARG TEMBO_PG_LIB_DIR=${TEMBO_VOLUME}/${PG_MAJOR}/lib
ARG TEMBO_LD_LIB_DIR=${TEMBO_VOLUME}/${OS_NAME}/lib

# Set rpath to search the Postgres lib directory, then the Tembo Postgres lib
# directory, where Trunk-installed extension libraries will live, and the
# Tembo OS lib directory, where Trunk-installed third-party libraries will
# live. https://lekensteyn.nl/rpath.html
ARG TEMBO_RPATH=${PG_PREFIX}/lib:${TEMBO_PG_LIB_DIR}:${TEMBO_LD_LIB_DIR}

##############################################################################
# Build trunk.
FROM rust:1.83-bookworm AS trunk
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
RUN cargo install pg-trunk

##############################################################################
# Build PostgreSQL.
FROM ${BASE} AS build
ARG PG_VERSION PG_PREFIX TEMBO_SHARE_DIR TEMBO_RPATH
WORKDIR /work

# Upgrade to the latest packages and install dependencies.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update; apt-get upgrade -y && apt-get install -y \
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
    bison

# Download and unpack the PostgreSQL source.
ADD https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.bz2 .
RUN tar jxf postgresql-${PG_VERSION}.tar.bz2
WORKDIR /work/postgresql-${PG_VERSION}

# Compile and install PostgreSQL.
RUN set -ex; \
    ./configure \
        CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -Wl,-rpath,${TEMBO_RPATH}" \
        LDFLAGS="-Wl,-z,relro -Wl,-z,now" \
        --prefix="${PG_PREFIX}" \
        --datarootdir="${TEMBO_SHARE_DIR}" \
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
    make install; \
    make -C contrib/auto_explain install; \
    make -C contrib/pg_stat_statements install;

##############################################################################
# Install additional stuff for the dev image.
FROM build AS dev-install
ARG PG_PREFIX PG_HOME TEMBO_LD_LIB_DIR TEMBO_PG_LIB_DIR CNPG_VOLUME

ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    apt-get install --no-install-recommends -y \
        git \
        chrpath \
        cmake \
        jq \
        curl \
        wget; \
    apt-get clean -y; \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*; \
    mkdir -p "${TEMBO_LD_LIB_DIR}" "${TEMBO_PG_LIB_DIR}" "${CNPG_VOLUME}"; \
    groupadd -r postgres --gid=999 && \
	useradd -r -g postgres --uid=26 --home-dir=${PG_HOME} --shell=/bin/bash postgres && \
    chown -R postgres:postgres ${PG_HOME};

# Add the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/

##############################################################################
# Build the postgres-dev image as a single layer.
FROM scratch AS postgres-dev
ARG PG_PREFIX PG_HOME

COPY --link --from=dev-install / /
WORKDIR ${PG_HOME}
ENV TZ=Etc/UTC LANG=en_US.utf8 PATH=${PG_PREFIX}/bin:$PATH
USER 26
ENTRYPOINT ["docker-entrypoint.sh"]

##############################################################################
# Install the dependencies necessary for the base image.
FROM ${BASE} AS install
ARG CNPG_VOLUME PACKAGES TEMBO_LD_LIB_DIR TEMBO_PG_LIB_DIR PG_PREFIX PG_HOME

# Copy the PostgreSQL files and trunk.
COPY --link --from=build --parents /var/lib/./postgresql /var/lib/
COPY --link --from=build --parents /usr/lib/./postgresql /usr/lib/
COPY --link --from=trunk /usr/local/cargo/bin/trunk /usr/local/bin/trunk

# Upgrade to the latest packages and install dependencies.
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

# Clean up and finish configuration.
ENV PATH=${PG_PREFIX}/bin:$PATH
RUN set -xe; \
    apt-get clean -y; \
    # Set up en_US.UTF-8
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
    mkdir -p "${TEMBO_LD_LIB_DIR}" "${TEMBO_PG_LIB_DIR}" "${CNPG_VOLUME}"; \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*; \
    # Stash away sharedir and etc so the Tembo operator can copy them back
    # when it initializes the pod. (We should be able to do it during pod
    # initialization without a temp copy: https://stackoverflow.com/a/72269316/79202)
    cp -lr "$(pg_config --sharedir)" /tmp/pg_sharedir;

# Add the README.
COPY CONTAINER_README.md "${PG_HOME}/README.md"

# Create the Postgres user and set its uid to what CNPG expects.
RUN groupadd -r postgres --gid=999 && \
	useradd -r -g postgres --uid=26 --home-dir=${PG_HOME} --shell=/bin/bash postgres && \
    chown -R postgres:postgres ${PG_HOME};

# Add the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/

##############################################################################
# Build the postgres image as a single layer.
FROM scratch AS postgres
ARG PG_PREFIX PG_HOME

COPY --link --from=install / /
WORKDIR ${PG_HOME}
ENV TZ=Etc/UTC LANG=en_US.utf8 PATH=${PG_PREFIX}/bin:$PATH
USER 26
ENTRYPOINT ["docker-entrypoint.sh"]
