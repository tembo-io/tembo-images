Tembo PostgreSQL
================

You have shelled into an instance of Tembo Postgres. All of persistent files
live here in `/var/lib/postgresql`. Here's a description of subdirectories and
their purposes:

*   `data`: The directory in which the Docker entrypoint initializes
    a cluster and which [CloudNativePG] mounts as a persistent volume.
*   `data/pgdata`: The data directory initialized by the Docker entrypoint and
    [CloudNativePG].
*   `tembo`: The directory that [Tembo Cloud] mounts as the persistent volume
    for the database and extensions.
*   `tembo/pgdata`: The data directory initialized by [Tembo Cloud].
*   `tembo/share`: The directory for architecture-independent support files
    used by Postgres. This is the directory used by `pg_config --sharedir` to
    install non-binary extension files. Its files are copied from
    `/tmp/pg_sharedir` when the Tembo operator initializes the volume.
*   `tembo/${PG_MAJOR}/lib`: A directory for extension shared library files
    compiled for a specific major version of Postgres.
*   `tembo/${OS_NAME}/lib`: A directory for OS shared library files.
*   `tembo/${OS_NAME}/etc`: The home of the library loading cache, updated
    by `ldconfig` when new files are installed into
    `tembo/${OS_NAME}/lib`. The canonical cache file, `/etc/ld.so.cache`,
    is a symlink into this directory.


Other useful locations around the system:

*   `/usr/lib/postgresql`: The base directory for Postgres itself.
*   `/usr/local/bin/docker-entrypoint.sh`: The docker entrypoint script, which
    initializes and starts a Postgres cluster in `/var/lib/postgresql/data/pgdata`.
*   `/etc/ld.so.conf.d/postgres.conf`: Configures the library loader to look
    for library files in the Postgres library directory (`pg_config --libdir`).
*   `/etc/ld.so.conf.d/tembo.conf`: Configures the library loader to look
    for library files in `/var/lib/postgresql/tembo/${OS_NAME}/lib`.

  [CloudNativePG]: https://cloudnative-pg.io
  [Tembo Cloud]: https://tembo.io/docs/product/cloud/overview "Tembo Cloud Overview"
