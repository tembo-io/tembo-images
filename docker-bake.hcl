variable "registry" {
  default = "quay.io/tembo"
}

// Use the revision variable to identify the commit that generated the image.
variable "revision" {
  default = ""
}

now = timestamp()
authors = "Tembo"
url = "https://github.com/tembo-io/tembo-images"

target "default" {
  matrix = {
    # Keep up-to-date with the latest Postgres releases.
    pgVersion = [
      "14.17",
      "15.12",
      "16.8",
      "17.4"
    ]
    # Should always have the current and previous OS. Packages are OS
    # version-specific Apt packages installed by the Dockerfile.
    base = [
      {
        image = "quay.io/tembo/ubuntu:24.04",
        name = "noble"
        digest = "72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782"
        packages = "libicu74 libllvm19 libpython3.12 libperl5.38"
      },
      {
        image = "quay.io/tembo/ubuntu:22.04",
        name = "jammy"
        digest = "ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2"
        packages = "libicu70 libllvm15 libpython3.11 libperl5.34"
      },
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "postgres-${major(pgVersion)}-${base.name}"
  tags = tags(pgVersion, base.name)
  context = "."
  target = "postgres"
  args = {
    PG_VERSION = "${pgVersion}"
    BASE = "${base.image}@sha256:${base.digest}"
    UBUNTU_NAME = "${base.name}"
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
    "index,manifest:org.opencontainers.image.description=PostgreSQL ${pgVersion}",
    "index,manifest:org.opencontainers.image.documentation=${url}",
    "index,manifest:org.opencontainers.image.authors=${authors}",
    "index,manifest:org.opencontainers.image.licenses=PostgreSQL",
    "index,manifest:org.opencontainers.image.base.name=${base.image}",
    "index,manifest:org.opencontainers.image.base.digest=${base.digest}",
  ]
  labels = {
    "org.opencontainers.image.created" = "${now}",
    "org.opencontainers.image.url" = "${url}",
    "org.opencontainers.image.source" = "${url}",
    "org.opencontainers.image.version" = "${pgVersion}",
    "org.opencontainers.image.revision" = "${revision}",
    "org.opencontainers.image.vendor" = "${authors}",
    "org.opencontainers.image.title" = "PostgreSQL ${pgVersion}",
    "org.opencontainers.image.description" = "PostgreSQL ${pgVersion}",
    "org.opencontainers.image.documentation" = "${url}",
    "org.opencontainers.image.authors" = "${authors}",
    "org.opencontainers.image.licenses" = "PostgreSQL"
    "org.opencontainers.image.base.name" = "${base.image}",
    "org.opencontainers.image.base.digest" = "${base.digest}",
  }
}

# Extracts the tag part of an image name. For example, returns `24.04` for
# `quay.io/tembo/ubuntu:24.04`.
function tag {
  params = [ imageNameWithTag ]
  result = index(split(":", imageNameWithTag), 1)
}

# Returns the major of a PostgreSQL version. For example, returns `17` for
# `17.4`.
function major {
  params = [ version ]
  result = index(split(".",version),0)
}

# Creates the tags for the Postgres image. If the osName is "noble", it
# returns five tags. Otherwise it returns 3.
function tags {
  params = [ pgVersion, osName ]
  result = flatten([
    osName == "noble" ? [
      "${registry}/postgres:${major(pgVersion)}",
      "${registry}/postgres:${pgVersion}",
    ] : [],
    "${registry}/postgres:${major(pgVersion)}-${osName}",
    "${registry}/postgres:${pgVersion}-${osName}",
    "${registry}/postgres:${pgVersion}-${formatdate("YYYYMMDDhhmm", now)}-${osName}",
  ])
}
