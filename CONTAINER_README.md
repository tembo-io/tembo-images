Tembo PostgreSQL
================

You have shelled into an instance of Tembo Postgres. All of persistent files
live here in `/var/lib/postgresql`. Here's a description of subdirectories and
their purposes:

*   `data`: The directory in which the Docker entrypoint initializes
    a cluster and which [Tembo Cloud] mounts as a persistent volume.
*   `data/pgdata`: The data directory initialized by the Docker entrypoint and
    [Tembo Cloud].
*   `data/lib`: A directory for shared library files required by extensions.
*   `data/mod`: A directory for extension module library files.
*   `data/share`: The directory for architecture-independent support files
    used by Postgres. This is the directory used by `pg_config --sharedir` to
    install non-binary extension files.

Other useful locations around the system:

*   `/usr/lib/postgresql`: The base directory for Postgres itself.
*   `/usr/local/bin/docker-entrypoint.sh`: The docker entrypoint script, which
    initializes and starts a Postgres cluster in `/var/lib/postgresql/data/pgdata`.

  [CloudNativePG]: https://cloudnative-pg.io
  [Tembo Cloud]: https://tembo.io/docs/product/cloud/overview "Tembo Cloud Overview"
