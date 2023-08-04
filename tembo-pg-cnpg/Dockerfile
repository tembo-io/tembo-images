FROM rust:1.70-bookworm as builder

ARG TRUNK_VER=0.8.0

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse 
RUN cargo install --version $TRUNK_VER pg-trunk

FROM quay.io/coredb/coredb-pg-base:latest
USER root

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
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26