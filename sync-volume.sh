#!/bin/bash

set -e

# CNPG mounts this persistent volume to store data. Tembo also stores
# extension files and dependent libraries here. On Pod initialization, Tembo
# mounts the persistent volume to another location and passes it to this
# script. The script copies the data the image put into the src into the dst
# directory, so that when CNPG mounts the volume all the data from this Docker
# image will be present in the persistent volume.

src=/var/lib/postgresql/data

migrate() {
    # Migrate libraries, modules, and shared files to their new locations.
    pushd "${1}"
    pgv="$(pg_config --version | perl -ne '/(\d+)/ && print $1')"
    if [ -d "tembo/$pgv/lib" ]; then
        # In old Tembo images, all Postgres libdir and pkglibdir files were
        # here. Remove the files burned into the image.
        if [ -d "tembo/$pgv/lib/bitcode" ]; then
            for file in /usr/lib/postgresql/lib/bitcode/*; do
                rm -rf "tembo/$pgv/lib/bitcode/$(basename "$file")"
            done
        fi
        for file in /usr/lib/postgresql/lib/*; do
            bn="$(basename "$file")"
            if [ "$bn" != "bitcode" ]; then
                rm -rf "tembo/$pgv/lib/$bn"
            fi
        done
        # Move likely dependent lib files to lib.
        mkdir -p lib
        mv "tembo/$pgv/lib/lib"* lib/
        # Move the remaining files, mostly extension modules, to mod.
        mv "tembo/$pgv/lib" mod
        rmdir "tembo/$pgv"
    fi

    # The rest of the tembo directory is sharedir; rename it.
    mv tembo share
    popd
}

main() {
    dst="${1-/var/lib/postgresql/init}"
    # If the tembo directory managed by old images exists, migrate its files.
    if [ -d "$dst/tembo" ]; then migrate "$dst"; fi;
    # Update core modules and extensions on the volume.
    cp -p --recursive --update "$src/"* "$dst/"
}

main "$@"
