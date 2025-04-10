#!/usr/bin/env bash
set -Eeo pipefail

# Starts a simply-configured server with default authentication that trusts
# local connections from inside the container.

export PGDATA=${PGDATA:-/var/lib/postgresql/data/pgdata}

main() {
    if [ "${1:-postgres}" != 'postgres' ]; then
	    exec "$@"
    fi

    if [ "$(id -u)" = '0' ]; then
		cat >&2 <<-'EOE'
			Error: Postgres cannot be run by root. Please restart the container
                   with specifying a user, or run another application on startup.
		EOE
		exit 1
    fi

    # Initialize the database.
    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA" || :

	if [ ! -s "$PGDATA/PG_VERSION" ]; then
        opts=(
            -D "$PGDATA"
            -U postgres
            -c listen_addresses='*'
            -c dynamic_library_path="\$libdir:/var/lib/postgresql/data/mod"
            --auth trust
            --encoding UNICODE
        )

        if [ "$(pg_config --version | perl -ne '/(\d+)/ & print $1')" -ge 17 ]; then
            # Prefer builtin C.UTF-8.
            opts+=(--locale-provider builtin --builtin-locale C.UTF-8)
        else
            # Default to en_US.UTF-8.
            opts+=(--locale en_US.UTF-8)
        fi

        initdb "${opts[@]}"
	fi

    # Start the server. Logs go to STDOUT.
    postgres
}

main "$@"
