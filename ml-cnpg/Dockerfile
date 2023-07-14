FROM quay.io/tembo/tembo-pg-cnpg:f857ab0
USER root

WORKDIR /

COPY requirements.txt .

# Install dependencies for running pgml
RUN set -eux;\
  apt-get update; \
  apt-get upgrade -y; \
  apt-get install -y \
    libopenblas-base \
  ; \
  apt-get autoremove -y; \
  apt-get clean; \
	rm -rf /var/lib/apt/lists/*;

# Trunk Install Needed Extensions
RUN set -eux; \
  trunk install postgresml --version 2.7.1; \
  trunk install pgvector --version 0.4.2; \
  trunk install hstore_plpython3u; \
  trunk install jsonb_plpython3u; \
  trunk install ltree_plpython3u; \
  trunk install pg_embedding;

# cache all extensions
RUN set -eux; \
      cp -r $(pg_config --pkglibdir)/* /tmp/pg_pkglibdir; \
      cp -r $(pg_config --sharedir)/* /tmp/pg_sharedir;

# Revert the postgres user to id 26
RUN usermod -u 26 postgres
USER 26

# Install Python dependencies
ENV PATH=/var/lib/postgresql/.local/bin:$PATH
RUN set -eux; \
  pip3 install -r requirements.txt;

ENV TRANSFORMERS_CACHE=/var/lib/postgresql/data/tembo/huggingface
