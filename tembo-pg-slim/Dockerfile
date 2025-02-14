# vim:set ft=dockerfile:
FROM quay.io/coredb/ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG ALTDIR=/var/lib/postgresql/data/tembo
ENV TZ=Etc/UTC
ENV PGDATA /var/lib/postgresql/data
ARG PG_VERSION 15
ARG PG_TAG REL_15_11
ENV PATH $PATH:/usr/lib/postgresql/$PG_VERSION/bin

# Get latest package updates
RUN set -eux; \
      apt-get update; \
      apt-get upgrade -y

# Set the postgres user's permissions
RUN set -eux; \
      groupadd -r postgres --gid=999; \
      useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; \
      mkdir -p /var/lib/postgresql; \
      chown -R postgres:postgres /var/lib/postgresql; \
      apt-get install -y curl ca-certificates gnupg lsb-release lbzip2 git

STOPSIGNAL SIGINT

RUN set -eux; \
      apt-get update; \
      apt-get install -y --no-install-recommends \
      locales \
    ; \
    rm -rf /var/lib/apt/lists/*; \
	  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN mkdir /docker-entrypoint-initdb.d

RUN set -eux; \
      apt-get update && apt-get install -y \
          libreadline-dev \
          zlib1g-dev \
          libpq-dev \
          build-essential \
          python3-dev \
          tcl-dev \
          libxslt1-dev \
          libperl-dev \
          libpam0g-dev \
          libreadline-dev \
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
	    vim \
          flex \
          bison; \
      apt-get autoremove -y; \
      apt-get clean -y; \
      rm -rf /var/lib/apt/lists/*

ENV CFLAGS "-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer"
ENV LDFLAGS "-Wl,-z,relro -Wl,-z,now"
RUN git clone --depth 1 --branch ${PG_TAG} https://git.postgresql.org/git/postgresql.git; \
    cd postgresql; \
    ./configure --prefix=/usr/lib/postgresql/${PG_VERSION} \
        --datarootdir=${ALTDIR} \
        --libdir=${ALTDIR}/${PG_VERSION}/lib \
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

# Remove libpq-dev provided from Ubuntu repos and set the newly-compiled one to system path
RUN set -eux; \
    apt-get purge -y libpq-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN echo "${ALTDIR}/${PG_VERSION}/lib" > /etc/ld.so.conf.d/postgres.conf && \
    ldconfig

WORKDIR /
RUN rm -rf /postgresql

RUN mkdir -p /var/run/postgresql && chmod 775 /var/run/postgresql
RUN mkdir -p /usr/share/postgresql/${PG_MAJOR}/extension && chmod 775 /usr/share/postgresql/${PG_MAJOR}/extension

USER postgres
CMD ["postgres"]
