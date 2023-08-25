# Postgres Docker Image for Tembo's Standard Stack

Contains a Dockerfile with Postgres 15.3, with trunk, barman-cloud and all extension dependencies installed.

## Versioning

The version of the Docker image can be configured in the `Cargo.toml` file in this directory. We may wrap postgres in our CoreDB distribution, but for the time being this crate is just a placeholder to allow for versioning.
