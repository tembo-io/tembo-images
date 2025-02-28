variable "registry" {
  default = "localhost:5001"
}

// Use the revision variable to identify the commit that generated the image
variable "revision" {
  default = ""
}

now = timestamp()
authors = "Tembo"
url = "https://github.com/tembo-io/tembo-images"

target "default" {
  matrix = {
    pgVersion = [
    #   "14.17",
    #   "15.12",
    #   "16.8",
      "17.4"
    ]
    tgt = ["postgres"]
    base = [
      {
        image = "quay.io/tembo/ubuntu:24.04",
        packages = "libicu74 libllvm19 libpython3.12 libperl5.38"
      }
    #   {
    #     image = "quay.io/tembo/ubuntu:22.04",
    #     packages = "libicu70 libllvm15 libpython3.11 libperl5.34"
    #   }
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "postgresql-${major(pgVersion)}-${major(tag(base.image))}"
  context = "."
  target = "${tgt}"
  args = {
    PG_VERSION = "${pgVersion}"
    BASE = "${base.image}"
    PACKAGES = "${base.packages}"
  }
#   attest = [
#     "type=provenance,mode=max",
#     "type=sbom"
#   ]
#   annotations = [
#     "index,manifest:org.opencontainers.image.created=${now}",
#     "index,manifest:org.opencontainers.image.url=${url}",
#     "index,manifest:org.opencontainers.image.source=${url}",
#     "index,manifest:org.opencontainers.image.version=${pgVersion}",
#     "index,manifest:org.opencontainers.image.revision=${revision}",
#     "index,manifest:org.opencontainers.image.vendor=${authors}",
#     "index,manifest:org.opencontainers.image.title=CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
#     "index,manifest:org.opencontainers.image.description=A ${tgt} PostgreSQL ${pgVersion} container image",
#     "index,manifest:org.opencontainers.image.documentation=https://github.com/cloudnative-pg/postgres-containers",
#     "index,manifest:org.opencontainers.image.authors=${authors}",
#     "index,manifest:org.opencontainers.image.licenses=Apache-2.0",
#     "index,manifest:org.opencontainers.image.base.name=docker.io/library/${tag(base)}",
#     "index,manifest:org.opencontainers.image.base.digest=${digest(base)}"
#   ]
#   labels = {
#     "org.opencontainers.image.created" = "${now}",
#     "org.opencontainers.image.url" = "${url}",
#     "org.opencontainers.image.source" = "${url}",
#     "org.opencontainers.image.version" = "${pgVersion}",
#     "org.opencontainers.image.revision" = "${revision}",
#     "org.opencontainers.image.vendor" = "${authors}",
#     "org.opencontainers.image.title" = "CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
#     "org.opencontainers.image.description" = "A ${tgt} PostgreSQL ${pgVersion} container image",
#     "org.opencontainers.image.documentation" = "${url}",
#     "org.opencontainers.image.authors" = "${authors}",
#     "org.opencontainers.image.licenses" = "Apache-2.0"
#     "org.opencontainers.image.base.name" = "docker.io/library/debian:${tag(base)}"
#     "org.opencontainers.image.base.digest" = "${digest(base)}"
#   }
}

function tag {
  params = [ imageNameWithTag ]
  result = index(split(":", imageNameWithTag), 1)
}

function major {
  params = [ version ]
  result = index(split(".",version),0)
}
