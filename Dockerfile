FROM hexpm/elixir:1.17.0-erlang-27.0-debian-bookworm-20240612-slim AS build

WORKDIR /app

RUN apt-get update && \
    apt-get install -y build-essential git && \
    rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib

RUN mix compile
RUN mix release

# ---

FROM debian:bookworm-slim AS runtime

WORKDIR /app

RUN apt-get update && \
    apt-get install -y libssl3 libncurses6 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app/_build/prod/rel/personal_mcp ./

EXPOSE 4000

CMD ["./bin/personal_mcp", "start"]
