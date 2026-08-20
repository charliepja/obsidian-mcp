FROM elixir:1.20-otp-29-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
      build-essential git \
    && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

COPY . /app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

RUN mix compile
RUN mix release

# ---

FROM ubuntu:noble AS runtime

WORKDIR /app

RUN apt-get update && \
    apt-get install -y libncurses6 locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

COPY --from=builder /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app/_build/prod/rel/personal_mcp ./

EXPOSE 4000

ENTRYPOINT ["./bin/personal_mcp"]
CMD ["start"]
