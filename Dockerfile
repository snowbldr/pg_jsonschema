FROM postgres:15-bookworm
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    build-essential \
    libpq-dev \
    postgresql-server-dev-15 \
    curl \
    libreadline6-dev \
    zlib1g-dev \
    pkg-config \
    cmake

WORKDIR /home/supa
ENV HOME=/home/supa PATH=/home/supa/.cargo/bin:$PATH
RUN chown postgres:postgres /home/supa
USER postgres

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain nightly && \
    rustup --version && \
    rustc --version && \
    cargo --version

# PGX
RUN cargo install cargo-pgrx --version 0.9.8 --locked

RUN cargo pgrx init --pg15 $(which pg_config)

USER root

COPY . .
RUN cargo pgrx package
RUN find target/release/pg_jsonschema* -xtype f -exec cp {} /pgjs/ \;

FROM postgres:15-bookworm
COPY --from=build /pgjs/pg_jsonschema.so /usr/lib/postgresql/15/lib/pg_jsonschema.so
COPY --from=build /pgjs/pg_jsonschema.control /usr/share/postgresql/15/extension/pg_jsonschema.control
COPY --from=build /pgjs/pg_jsonschema--0.1.4.sql /usr/share/postgresql/15/extension/pg_jsonschema--0.1.4.sql