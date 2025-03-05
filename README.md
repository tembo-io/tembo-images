# Tembo Postgres Docker Images

This repository contains the resources to build the Postgre Docker images for
[Tembo Cloud]. It builds images for the latest releases of Postgres 14–17 on
Ubuntu Noble (24.04) and Jimmy (22.04) for the ARM64 and AMD64 processors.

## Key Features

*   Simple entrypoint script to run a standalone in Docker an connect from
    inside the container:

    ```sh
    docker run --name tembo-postgres -d localhost:5001/postgres:17
    docker exec -it tembo-postgres psql
    ```

*   Runs in [CloudNativePG]; just set the `imageName` key in the `spec`
    section of the `Cluster` manifest:

    ```yaml
    apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    metadata:
      # [...]
    spec:
      imageName: quay.io/tembo/postgres:17
      #[...]
    ```

*   Based on the latest and previous LTS Ubuntu [Ubuntu Linux], currently
    24.04 LTS "Noble Numbat" and 22.04 LTS "Jammy Jellyfish".

*   Built for AMD64 (x86_64) and ARM64 (AArch64) processors.

*   Automatically rebuilt every Monday to ensure they remain up-to-date.

  [Tembo Cloud]: https://tembo.io/docs/product/cloud/overview "Tembo Cloud Overview"
  [CloudNativePG]: https://cloudnative-pg.io "CloudNativePG - PostgreSQL Operator for Kubernetes"

### Directories

*   `/var/lib/postgresql`: The home directory for the `postgres` user where
    all the potentially persistent data files and libraries live.

*   `/var/lib/postgresql/data`: The default data directory where the Docker
    entrypoint script and [CloudNativePG] store the data files in a `pgdata`
    subdirectory. Mount a volume to this directory for data persistence.

*   `/var/lib/postgresql/tembo`: The directory where [Tembo Cloud] mounts a
    persistent volume and stores persistent data:
    *   Tembo initializes and runs the cluster from the `pgdata` subdirectory.
    *   Given a Postgres major version, e.g., `17`, the Tembo stores extension
        shared libraries in `17/lib` and extension data files in `17/share`.
    *   Given an Ubuntu code name, such as `noble`, Tembo stores shared system
        libraries required by extensions in `noble/lib`.

*   `/usr/lib/postgresql`: The home of the PostgreSQL binaries, libraries, and
    header & locale files. Immutable in [CloudNativePG] and [Tembo Cloud].

## Building

```sh
docker buildx bake
```

## Running with Tembo Operator

To run the image locally, you'll need:

*   [just](https://just.systems/man/en/packages.html)
*   [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
*   [Rust](https://www.rust-lang.org/tools/install)

1.  Start a local registry on port 5001:

    ```sh
    docker run -d -p 5001:5000 --restart=always --name registry registry:2
    ```

2.  Build Tembo Postgres and push it to the local registry:

    ```sh
    registry=localhost:5001 docker buildx bake
    docker push localhost:5001/postgres:17-noble
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
    image: localhost:5001/postgres:17-noble
    ```

6.  Connect to your local docker registry and kind kubernetes cluster

    ```sh
    kind load docker-image localhost:5001/postgres:17-noble
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
