# Tembo Postgres Docker Images

This repository contains the resources to build the Postgre Docker images for
[Tembo Cloud]. It builds images for the latest releases of Postgres 14–17 on
Ubuntu Noble (24.04) and Jimmy (22.04) for the ARM64 and AMD64 processors.

## Key Features

*   Simple entrypoint script to run a standalone in Docker an connect from
    inside the container:

    ```sh
    docker run --name tembo-postgres -d quay.io/tembo/postgres
    docker exec -it tembo-postgres psql
    ```

*   Based on the latest and previous LTS Ubuntu [Ubuntu Linux], currently
    24.04 LTS "Noble Numbat" and 22.04 LTS "Jammy Jellyfish".

*   Built for AMD64 (x86_64) and ARM64 (AArch64) processors.

*   Automatically rebuilt every Monday to ensure they remain up-to-date.

*   In addition to `quay.io/tembo/postgres`, als builds
    `quay.io/tembo/postgres-dev`, which contains the tooling to compile
    extensions, including compilers, Git, Curl, and more.

## Building

The easiest way to build and load the `postgres` and `postgres-dev` images
into Docker is to set up a temporary registry, push to it, then pull from it:

```sh
docker run -d -p 5001:5000 --restart=always --name registry registry:2
registry=localhost:5001 arch="$(uname -m)" pg_version=17.4 docker buildx bake --push
docker pull localhost:5001/postgres
docker pull localhost:5001/postgres-dev
```

Set these environment variables to modify the build behavior:

*   `registry`: The name of the registry to push to. Defaults to
    `quay.io/tembo`.
*   `revision`: Current Git commit SHA. Used for annotations, not really
    needed for testing, but can be set via `revision="$(git rev-parse HEAD)"`.
*   `pg`: The version of Postgres to build, in `$major.$minor` format.
*   `os`: The OS version to build on. Currently one of "noble" or "jammy".
*   `arch`: The CPU architecture to build for. Use `uname -m` to get a valid
    value.

## Running with Tembo Operator

To run the image locally with the Tembo Operator, you'll need:

*   [docker](https://www.docker.com)
*   [just](https://just.systems/man/en/packages.html)
*   [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
*   [Rust](https://www.rust-lang.org/tools/install)

1.  Start a local registry on port 5001:

    ```sh
    docker run -d -p 5001:5000 --restart=always --name registry registry:2
    ```

2.  Build Tembo Postgres and push it to the local registry:

    ```sh
    registry=localhost:5001 arch="$(uname -m)" docker buildx bake --push
    ```

3.  If you haven't already, clone the tembo repository and navigate to the
    `tembo-operator` directory.

    ```sh
    git clone https://github.com/tembo-io/tembo.git
    cd tembo/tembo-operator
    ```

4.  Run the following commands to start the Tembo Operator:

    ```sh
    just start-kind
    just run
    ```

5.  Edit `yaml/sample-standard.yaml` and set `image` to the image name:

    ```yaml
    image: localhost:5001/postgres:latest
    ```

6.  Load the image into the `kind` Kubernetes registry and create the cluster:

    ```sh
    kind load docker-image localhost:5001/postgres:17
    kubectl apply -f yaml/sample-standard.yaml
    ```

7.  To check for success, run:

    ```sh
    kubectl get pods
    ```

8.  Connect to the pod for further testing and exploration:

    ```sh
    kubectl exec -it -c postgres sample-standard-1 -- bash
    kubectl exec -it -c postgres sample-standard-1 -- psql
    ```

9.  When done, hit `ctrl+c ` to shut down the operator, then delete the `kind`
    cluster and the registry:

    ```sh
    kind delete cluster
    docker rm -f registry
    ```

## Details

### Tags

The tags include the Postgres version, OS name, and timestamp e.g.,

*   `postgres:17-jammy`
*   `postgres:17.4-jammy`
*   `postgres:17.4-jammy-202503041708`

Images built on the latest OS, also have the tags:

*   `postgres:17`
*   `postgres:17.4`

And an image built on the latest Postgres includes the tag:

*   `postgres:latest`

### Directories

*   `/var/lib/postgresql`: The home directory for the `postgres` user where
    all the potentially persistent data files and libraries live.

*   `/var/lib/postgresql/data`: The directory where the Docker entrypoint
    script initializes the database in the `pgdata` subdirectory, and where
    [Tembo Cloud] mounts a persistent volume and stores persistent data:
    *   `pgdata`: Tembo initializes and runs the cluster from this
        subdirectory.
    *   `mod`: Tembo stores extension module libraries this subdirectory.
    *   `share`: Tembo stores and extension data files in this subdirectory.
    *   `lib`: Tembo stores shared libraries required by extensions in this
        subdirectory.

*   `/usr/lib/postgresql`: The home of the PostgreSQL binaries, libraries, and
    header & locale files. Immutable in [Tembo Cloud].

### Cloud Native Postgres Support

Unfortunately, this image does not work on [CloudNativePG]. This is because it
currently stores files in `/var/lib/postgresql/data` that [CloudNativePG]
masks when it mounts the directory as a volume.

## Tasks

### Postgres Minor Release

*   Update the list under `jobs.bake.strategy.matrix.pg` in
    `.github/workflows/bake.yaml`.
*   Update the default value of the `pg` variable definition in
    `docker-bake.hcl`.

### Ubuntu Minor Release

*   Update the `digest` values in the `os_spec` variable definition in
    `docker-bake.hcl`.

### Postgres Major Release

*   Update the default value of the `pg` and `latest_pg` variable definitions
    in `docker-bake.hcl`.
*   Update the list under `jobs.bake.strategy.matrix.pg` in
    `.github/workflows/bake.yaml`.
*   Update the `LATEST_PG` constant in `manifest.js`.
*   Update examples in `README.md`.

### Ubuntu Major Release

*   Add a new object to the `os_spec` variable and update the the `os` and
    `latest_os` variable definitions in `docker-bake.hcl`.
*   Update the list under `jobs.bake.strategy.matrix.os` in
    `.github/workflows/bake.yaml`.
*   Update the `LATEST_OS` constant in `manifest.js`.
*   Update examples in `README.md`.

  [Tembo Cloud]: https://tembo.io/docs/product/cloud/overview "Tembo Cloud Overview"
  [CloudNativePG]: https://cloudnative-pg.io "CloudNativePG - PostgreSQL Operator for Kubernetes"
