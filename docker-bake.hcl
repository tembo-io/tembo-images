# Variables to be specified externally.
variable "registry" {
  default = "quay.io/tembo"
  description = "The image registry."
}

variable "revision" {
  default = ""
  description = "The current Git commit SHA."
}

variable pg {
  default = "17.4"
  description = "Version of Postgres to build. Must be major.minor."
}

variable os {
  default = latest_os
  description = "OS to build, one of “noble” or “jammy”."
  validation {
    condition = contains(keys(os_spec), os)
    error_message = "os must be one of ${join(", ", keys(os_spec))}"
  }
}

variable arch {
  default = ""
  description = "CPU Architecture to build."
  validation {
    condition = contains(keys(arch_for), arch)
    error_message = "arch must be one of ${join(", ", keys(arch_for))}"
  }
}

# Internal variables.
variable latest_os {
  default = "noble"
  description = "Defines the current latest OS name."
}

variable latest_pg {
  default = "17"
  description = "Defines the current latest PostgreSQL major version."
}

variable os_spec {
  description = "Info about the base OS images. Update the config to support new releases."
  default = {
    noble = {
      image = "quay.io/tembo/ubuntu:24.04",
      digest = "72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782"
      packages = "libicu74 libllvm19 libpython3.12 libperl5.38"
    },
    jammy = {
      image = "quay.io/tembo/ubuntu:22.04",
      digest = "ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2"
      packages = "libicu70 libllvm15 libpython3.11 libperl5.34"
    }
  }
}

variable arch_for {
  description = "Simple map of common `uname -m` architecture names to the canonical name."
  default = {
    amd64 = "amd64"
    x86_64 = "amd64"
    x64 = "amd64"
    x86-64 = "amd64"
    arm64 = "arm64"
    aarch64 = "arm64"
  }
}

# Values to use in the targets.
now = timestamp()
authors = "Tembo"
url = "https://github.com/tembo-io/tembo-images"

target "default" {
  matrix = {}
  platforms = ["linux/${arch_for[arch]}"]
  dockerfile = "Dockerfile"
  name = "postgres-${replace(pg, ".", "_")}-${arch_for[arch]}-${os}"
  tags = tags(pg, os)
  context = "."
  target = "postgres"
  args = {
    PG_VERSION = "${pg}"
    BASE = "${os_spec[os].image}@sha256:${os_spec[os].digest}"
    OS_NAME = "${os}"
    PACKAGES = "${os_spec[os].packages}"
  }
  annotations = [
    "index,manifest:org.opencontainers.image.created=${now}",
    "index,manifest:org.opencontainers.image.url=${url}",
    "index,manifest:org.opencontainers.image.source=${url}",
    "index,manifest:org.opencontainers.image.version=${pg}",
    "index,manifest:org.opencontainers.image.revision=${revision}",
    "index,manifest:org.opencontainers.image.vendor=${authors}",
    "index,manifest:org.opencontainers.image.title=Tembo PostgreSQL ${pg}",
    "index,manifest:org.opencontainers.image.description=PostgreSQL ${pg}",
    "index,manifest:org.opencontainers.image.documentation=${url}",
    "index,manifest:org.opencontainers.image.authors=${authors}",
    "index,manifest:org.opencontainers.image.licenses=PostgreSQL",
    "index,manifest:org.opencontainers.image.base.name=${os_spec[os].image}",
    "index,manifest:org.opencontainers.image.base.digest=${os_spec[os].digest}",
  ]
  labels = {
    "org.opencontainers.image.created" = "${now}",
    "org.opencontainers.image.url" = "${url}",
    "org.opencontainers.image.source" = "${url}",
    "org.opencontainers.image.version" = "${pg}",
    "org.opencontainers.image.revision" = "${pg}",
    "org.opencontainers.image.vendor" = "${authors}",
    "org.opencontainers.image.title" = "PostgreSQL ${pg}",
    "org.opencontainers.image.description" = "PostgreSQL ${pg}",
    "org.opencontainers.image.documentation" = "${url}",
    "org.opencontainers.image.authors" = "${authors}",
    "org.opencontainers.image.licenses" = "PostgreSQL"
    "org.opencontainers.image.base.name" = "${os_spec[os].image}",
    "org.opencontainers.image.base.digest" = "${os_spec[os].digest}",
  }
}

# Returns the major of a PostgreSQL version. For example, returns `17` for
# `17.4`.
function major {
  params = [ version ]
  result = index(split(".",version), 0)
}

# Creates the tags for the Postgres image. If `os_name` is the same as
# `latest_os`, it returns five tags, plus "latest" if `pg` is the same as
# `latest_pg`. Otherwise it returns three. These are the standard tags, but we
# don't actually use this configuration currently, because the build process
# in .github/workflows/bake.yaml requires building amd64 and arm64 images
# separately and pushing them by their SHAs and then joining them into
# multi-platform images in manifest.js as a second step. But the pattern here
# and in manifest.js should be the same.
function tags {
  params = [ pg, os_name ]
  result = flatten([
    os_name == latest_os ? flatten([
      major(pg) == latest_pg ? ["${registry}/postgres:latest"] : [],
      "${registry}/postgres:${major(pg)}",
      "${registry}/postgres:${pg}",
    ]) : [],
    "${registry}/postgres:${major(pg)}-${os_name}",
    "${registry}/postgres:${pg}-${os_name}",
    "${registry}/postgres:${pg}-${os_name}-${formatdate("YYYYMMDDhhmm", now)}",
  ])
}
