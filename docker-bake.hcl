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
      packages = "libicu74 libaio1t64 libgdbm-compat4t64"
    },
    jammy = {
      image = "quay.io/tembo/ubuntu:22.04",
      digest = "ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2"
      packages = "libicu70 libaio1 libgdbm-compat4"
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
  matrix = {
    tgt = [
      "postgres",
      "postgres-dev",
    ],
  }
  target = "${tgt}"
  platforms = ["linux/${arch_for[arch]}"]
  context = "."
  dockerfile = "Dockerfile"
  name = "${replace(tgt, "-", "_")}-${replace(pg, ".", "_")}-${arch_for[arch]}-${os}"
  # Push by SHA only.
  set = "output=type=image,push-by-digest=true,push=true"
  tags = ["${registry}/${tgt}"]
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
    "index,manifest:org.opencontainers.image.title=${title_for(tgt, pg)}",
    "index,manifest:org.opencontainers.image.description=${title_for(tgt, pg)}",
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
    "org.opencontainers.image.title" = "${title_for(tgt, pg)}",
    "org.opencontainers.image.description" = "${title_for(tgt, pg)}",
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

# Returns the title of the target image.
function title_for {
  params = [ tgt, pgv ]
  result = "Tembo PostgreSQL ${pgv}${tgt == "postgres" ? "" : " for Development"}"
}
