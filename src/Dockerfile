FROM rust:1.99.0-slim-trixie AS build-runfromprocess

ARG RUNFROMPROCESS_VERSION=a3d003c07d1bd11ff93c4cac96d2c3aa5deb8471

# Install prerequisites
# - mingw to cross-compile for windows
# - rust cross-compiler for windows
RUN DEBIAN_FRONTEND="noninteractive" apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y g++-mingw-w64-x86-64 \
 && rm -rf /var/lib/apt/lists/* \
 && rustup target add x86_64-pc-windows-gnu

# Build runfromprocess
WORKDIR /usr/src
ADD https://github.com/quietvoid/runfromprocess-rs.git#${RUNFROMPROCESS_VERSION} .
RUN cargo build --target x86_64-pc-windows-gnu --release

FROM archlinux:latest as zwift-base

RUN echo -e " \n\
[multilib] \n\
Include = /etc/pacman.d/mirrorlist \n\
" >> /etc/pacman.conf

RUN pacman -Syuu --noconfirm && \
	pacman -S --noconfirm base-devel git sudo wget which ncdu p7zip rsync \
		mesa vulkan-icd-loader vulkan-radeon pipewire-pulse wine gst-libav

RUN useradd -m user && \
    gpasswd -a user wheel && \
	echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure audio driver
COPY pulse-client.conf /etc/pulse/client.conf

RUN yes | pacman -Scc

USER user
WORKDIR /home/user

RUN git clone https://aur.archlinux.org/winetricks-git.git && \
	cd winetricks-git && \
	makepkg -si --noconfirm && \
	cd .. && rm -r winetricks-git

FROM zwift-base

ENV WINEDEBUG=fixme-all
ENV WINEPREFIX="/home/user/.wine"
ENV WINE_USER_HOME="${WINEPREFIX}/drive_c/users/user"
ENV ZWIFT_DATA_DIR="${WINE_USER_HOME}/AppData/Local/Zwift"
ENV ZWIFT_INSTALL_DIR="${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"
LABEL org.opencontainers.image.source="https://github.com/netbrain/zwift"
LABEL org.opencontainers.image.documentation="https://netbrain.github.io/zwift/"
LABEL org.opencontainers.image.licenses="Unlicense"

COPY --chmod=755 entrypoint.sh /bin/entrypoint
COPY --chmod=755 update_zwift.sh /bin/update_zwift.sh
COPY --chmod=755 run_zwift.sh /bin/run_zwift.sh
COPY --chmod=755 zwift-auth.sh /bin/zwift-auth
COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /bin/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]
