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
      "14.17",
      "15.12",
      "16.8",
      "17.4"
    ]
    tgt = [
        {
            name = "postgres"
            info = ""
        },
        {
            name = "postgres-cloud"
            info = " for Tembo Cloud"
        },
    ]
    base = [
      {
        image = "quay.io/tembo/ubuntu:24.04",
        name = "oracular"
        packages = "libicu74 libllvm19 libpython3.12 libperl5.38"
      },
      {
        image = "quay.io/tembo/ubuntu:22.04",
        name = "jammy"
        packages = "libicu70 libllvm15 libpython3.11 libperl5.34"
      },
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "${tgt.name}-${major(pgVersion)}-${base.name}"
  tags = [
    "${registry}/${tgt.name}-${major(pgVersion)}-${base.name}",
    "${registry}/${tgt.name}-${pgVersion}-${base.name}",
    "${registry}/${tgt.name}-${formatdate("YYYYMMDDhhmm", now)}-${base.name}",
  ]
  context = "."
  target = "${tgt.name}"
  args = {
    PG_VERSION = "${pgVersion}"
    BASE = "${base.image}"
    PACKAGES = "${base.packages}"
  }
  annotations = [
    "index,manifest:org.opencontainers.image.created=${now}",
    "index,manifest:org.opencontainers.image.url=${url}",
    "index,manifest:org.opencontainers.image.source=${url}",
    "index,manifest:org.opencontainers.image.version=${pgVersion}",
    "index,manifest:org.opencontainers.image.revision=${revision}",
    "index,manifest:org.opencontainers.image.vendor=${authors}",
    "index,manifest:org.opencontainers.image.title=Tembo PostgreSQL ${pgVersion}",
    "index,manifest:org.opencontainers.image.description=PostgreSQL ${pgVersion}${tgt.info}",
    "index,manifest:org.opencontainers.image.documentation=${url}",
    "index,manifest:org.opencontainers.image.authors=${authors}",
    "index,manifest:org.opencontainers.image.licenses=PostgreSQL",
    "index,manifest:org.opencontainers.image.base.name=${base.image}"
    # "index,manifest:org.opencontainers.image.base.digest=${digest(base)}"
  ]
  labels = {
    "org.opencontainers.image.created" = "${now}",
    "org.opencontainers.image.url" = "${url}",
    "org.opencontainers.image.source" = "${url}",
    "org.opencontainers.image.version" = "${pgVersion}",
    "org.opencontainers.image.revision" = "${revision}",
    "org.opencontainers.image.vendor" = "${authors}",
    "org.opencontainers.image.title" = "PostgreSQL ${pgVersion}${tgt.info}",
    "org.opencontainers.image.description" = "PostgreSQL ${pgVersion}${tgt.info}",
    "org.opencontainers.image.documentation" = "${url}",
    "org.opencontainers.image.authors" = "${authors}",
    "org.opencontainers.image.licenses" = "PostgreSQL"
    "org.opencontainers.image.base.name" = "${base.image}"
    # "org.opencontainers.image.base.digest" = "${digest(base)}"
  }
}

function tag {
  params = [ imageNameWithTag ]
  result = index(split(":", imageNameWithTag), 1)
}

function major {
  params = [ version ]
  result = index(split(".",version),0)
}
