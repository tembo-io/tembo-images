# syntax=docker/dockerfile:1.7-labs
ARG BASE
ARG OS_NAME
ARG PG_VERSION
ARG PG_MAJOR=${PG_VERSION%%.*}
ARG PG_PREFIX=/usr/lib/postgresql
ARG PG_HOME=/var/lib/postgresql
ARG DATA_VOLUME=${PG_HOME}/data

# Tembo-specific volume mount, sharedir, dynamic_library_path target, and
# System LLD dir.
ARG TEMBO_SHARE_DIR=${DATA_VOLUME}/share
ARG TEMBO_PG_MOD_DIR=${DATA_VOLUME}/mod
ARG TEMBO_LD_LIB_DIR=${DATA_VOLUME}/lib

# Set rpath to search the Postgres lib directory, then the Tembo Postgres lib
# directory, where Trunk-installed extension libraries will live, and the
# Tembo OS lib directory, where Tembox-installed third-party libraries will
# live. https://lekensteyn.nl/rpath.html
ARG TEMBO_RPATH=${PG_PREFIX}/lib:${TEMBO_PG_MOD_DIR}:${TEMBO_LD_LIB_DIR}

##############################################################################
# Build PostgreSQL.
FROM ${BASE} AS build
ARG PG_VERSION PG_PREFIX TEMBO_SHARE_DIR TEMBO_RPATH TARGETARCH
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

# Download and install the latest trunk release.
RUN set -ex; \
    tag="$(curl -sLH 'Accept: application/json' https://github.com/tembo-io/trunk/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')"; \
    curl -L https://github.com/tembo-io/trunk/releases/download/$tag/trunk-$tag-linux-${TARGETARCH}.tar.gz \
    | tar zxf - --strip-components=1 -C /usr/local/bin trunk-$tag-linux-${TARGETARCH}/trunk; \
    trunk --version

# Download and install the latest tembox release.
RUN set -ex; \
    tag="$(curl -sLH 'Accept: application/json' https://github.com/tembo-io/tembo-packaging/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')"; \
    curl -L https://github.com/tembo-io/tembo-packaging/releases/download/$tag/tembox-$tag-linux-${TARGETARCH}.tar.gz \
    | tar zxf - --strip-components=1 -C /usr/local/bin tembox-$tag-linux-${TARGETARCH}/tembox; \
    tembox --version

##############################################################################
# Install additional stuff for the dev image.
FROM build AS dev-install
ARG PG_PREFIX PG_HOME TEMBO_LD_LIB_DIR TEMBO_PG_MOD_DIR

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
    mkdir -p "${TEMBO_LD_LIB_DIR}" "${TEMBO_PG_MOD_DIR}"; \
    groupadd -r postgres --gid=999 && \
	useradd -r -g postgres --uid=26 --home-dir=${PG_HOME} --shell=/bin/bash postgres && \
    chown -R postgres:postgres ${PG_HOME};

# Add the README, entrypoint and sync scripts.
COPY CONTAINER_README.md "${PG_HOME}/README.md"
COPY docker-entrypoint.sh /usr/local/bin/
COPY sync-volume.sh /tmp/

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
ARG PACKAGES TEMBO_LD_LIB_DIR TEMBO_PG_MOD_DIR PG_PREFIX PG_HOME

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
    xz-utils \
    libgss3 \
    libkrb5-3 \
    media-types \
    netbase \
    libexpat1 \
    libsasl2-2 \
    libgsl27 \
    ${PACKAGES}

# Copy the PostgreSQL files, trunk, and tembox.
COPY --link --from=build --parents /var/lib/./postgresql /var/lib/
COPY --link --from=build --parents /usr/lib/./postgresql /usr/lib/
COPY --link --from=build /usr/local/bin/trunk /usr/local/bin/tembox /usr/local/bin/

# Clean up and finish configuration.
ENV PATH=${PG_PREFIX}/bin:$PATH
RUN set -xe; \
    apt-get clean -y; \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
    mkdir -p "${TEMBO_LD_LIB_DIR}" "${TEMBO_PG_MOD_DIR}"; \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*;

# Add the README, entrypoint script, and sync script.
COPY CONTAINER_README.md "${PG_HOME}/README.md"
COPY docker-entrypoint.sh /usr/local/bin/
COPY sync-volume.sh /tmp/

# Create the Postgres user and set its uid to what CNPG expects.
RUN groupadd -r postgres --gid=999 && \
	useradd -r -g postgres --uid=26 --home-dir=${PG_HOME} --shell=/bin/bash postgres && \
    chown -R postgres:postgres ${PG_HOME};

##############################################################################
# Build the postgres image as a single layer.
FROM scratch AS postgres
ARG PG_PREFIX PG_HOME

COPY --link --from=install / /
WORKDIR ${PG_HOME}
ENV TZ=Etc/UTC LANG=en_US.utf8 PATH=${PG_PREFIX}/bin:$PATH
USER 26
ENTRYPOINT ["docker-entrypoint.sh"]
