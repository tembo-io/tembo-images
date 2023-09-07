#!/bin/bash -i

set -e

# Start PostgreSQL in the background
postgres &

# Wait for PostgreSQL to start up
until pg_isready; do
    echo "Waiting for postgres to be ready..."
    sleep 1
done

# Loop through and execute each SQL file
for sql_file in $PGDATA/startup-scripts/*.sql; do
    [ -e "$sql_file" ] || continue
    psql -a -f "$sql_file"
done

# Move the PostgreSQL process to the foreground
fg
