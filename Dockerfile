FROM ubuntu:22.04

# Install runtime dependencies: fortune-mod, cowsay, and netcat (used by wisecow.sh)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fortune-mod \
        fortunes-min \
        cowsay \
        netcat-openbsd \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# cowsay/fortune binaries live in /usr/games on Debian/Ubuntu
ENV PATH="/usr/games:${PATH}"

WORKDIR /app

COPY wisecow.sh .
RUN chmod +x wisecow.sh

# Run as a non-root user for security
RUN useradd -m wisecow && chown -R wisecow:wisecow /app
USER wisecow

EXPOSE 4499

ENTRYPOINT ["./wisecow.sh"]
