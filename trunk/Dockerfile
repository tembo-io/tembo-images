# Build trunk.
FROM rust:1.85-bookworm AS build
ARG TRUNK_VER=0.16.1
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
RUN cargo install --version $TRUNK_VER pg-trunk

FROM scratch
COPY --from=build /usr/local/cargo/bin/trunk .

