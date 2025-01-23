<p align="center">
  <img src="https://github.com/tembo-io/trunk/assets/8935584/905ef1f3-10ff-48b5-90af-74af74ebb1b1" width=25% height=25%>
</p>

# Trunk

[![Latest quay.io image tags](https://img.shields.io/github/v/tag/jupyterhub/docker-image-cleaner?include_prereleases&label=quay.io)](https://quay.io/repository/tembo/trunk)

This OCI contains a single file, `/trunk`, compiled from [the source]. Useful to add
to another image:

```Dockerfile
FROM quay.io/tembo/trunk:latest AS trunk
FROM ubuntu:22.04
COPY --from=trunk /trunk /usr/bin/trunk
RUN trunk --version
```

  [the source]: https://github.com/tembo-io/trunk/
