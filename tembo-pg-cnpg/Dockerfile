ARG PG_VERSION=15

FROM rust:1.78-bookworm as builder

ARG TRUNK_VER=0.12.25
ARG TAG=latest

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse 
RUN cargo install --version $TRUNK_VER pg-trunk

FROM quay.io/tembo/tembo-pg-slim:${PG_VERSION}-${TAG}

USER root

# PGDATA is set in tembo-pg-slim and used by dependents on this image.
RUN if [ -z "${PGDATA}" ]; then echo "PGDATA is not set"; exit 1; fi

# Install trunk
COPY --from=builder /usr/local/cargo/bin/trunk /usr/bin/trunk
COPY ./requirements.txt .

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
	  mkdir /tmp/pg_pkglibdir; \
	  mkdir /tmp/pg_sharedir; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26
