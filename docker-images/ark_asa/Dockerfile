FROM ubuntu:22.04

# Accept PUID and PGID environment variables to allow runtime specification
ARG PUID=1000
ARG PGID=1000

# Set a default timezone, can be overridden at runtime
ENV TZ=UTC
ENV PUID=${PUID}
ENV PGID=${PGID}

# Install necessary packages
RUN set -ex; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    jq curl wget tar unzip nano gzip iproute2 procps software-properties-common dbus \
    lib32gcc-s1 libglib2.0-0 libglib2.0-0:i386 libvulkan1 libvulkan1:i386 \
    libnss3 libnss3:i386 libgconf-2-4 libgconf-2-4:i386 \
    libfontconfig1 libfontconfig1:i386 libfreetype6 libfreetype6:i386 \
    libcups2 libcups2:i386; \
    # Cleanup to keep the image lean
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Create the steam group and user 
RUN set -ex; \
    groupadd -g ${PGID} steam && \
    useradd -d /home/steam -u ${PUID} -g steam -G users -m steam; \
    mkdir /home/steam/arkserver

# Setup working directory
WORKDIR /opt/steamcmd
RUN set -ex; \
    wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf -

# Setup the Proton GE
WORKDIR /usr/local/bin
RUN set -ex; \
    curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | grep .tar.gz)"; \
    tar -xzf GE-Proton*.tar.gz --strip-components=1; \
    rm GE-Proton*.*

# Setup machine-id for Proton
RUN set -ex; \
    rm -f /etc/machine-id; \
    dbus-uuidgen --ensure=/etc/machine-id; \
    rm /var/lib/dbus/machine-id; \
    dbus-uuidgen --ensure

WORKDIR /tmp/
# Setup rcon-cli
RUN set -ex; \
    wget -qO- https://github.com/itzg/rcon-cli/releases/download/1.6.3/rcon-cli_1.6.3_linux_amd64.tar.gz | tar xvz && \
    mv rcon-cli /usr/local/bin/rcon-cli && \
    chmod +x /usr/local/bin/rcon-cli

# Install tini
ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN set -ex; \
    chown -R steam:steam /home/steam; \
    chown -R steam:steam /home/steam/arkserver; \
    chown -R steam:steam /opt/steamcmd

COPY --chown=pok:pok entrypoint.sh /opt/entrypoint.sh
# COPY --chown=pok:pok defaults/ /home/pok/defaults/
RUN  chmod +x /opt/entrypoint.sh

# update steam client
RUN /opt/steamcmd/steamcmd.sh +quit

USER steam
WORKDIR /home/steam
# Use tini as the entrypoint  
ENTRYPOINT ["/tini", "--", "/opt/entrypoint.sh"]