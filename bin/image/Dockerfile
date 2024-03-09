FROM archlinux:latest as wine64-base

RUN pacman -Syuu --noconfirm && \
	pacman -S --noconfirm base-devel git wget sudo openssl-1.1

RUN useradd -m user && \
    gpasswd -a user wheel && \
	echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user
WORKDIR /home/user
ENV MAKEOPTS "-j20"
ENV MAKEFLAGS "-j20"

ARG PARU_VERSION=2.0.3
RUN wget https://github.com/Morganamilo/paru/releases/download/v$PARU_VERSION/paru-v$PARU_VERSION-x86_64.tar.zst && \
	sudo tar xf paru-v$PARU_VERSION-x86_64.tar.zst -C /usr/bin paru
RUN git clone https://aur.archlinux.org/wine-wow64.git
RUN cd wine-wow64 && paru -U --noconfirm

FROM archlinux:latest as zwift-base

RUN echo -e " \n\
[multilib] \n\
Include = /etc/pacman.d/mirrorlist \n\
" >> /etc/pacman.conf

COPY --from=wine64-base /home/user/wine-wow64/wine-wow64-*-x86_64.pkg.tar.zst /opt/wine-wow64.tar.zst
RUN pacman -Syuu --noconfirm && \
	pacman -S --noconfirm sudo wget which ncdu mesa pipewire-pulse && \
	pacman -U --noconfirm /opt/wine-wow64.tar.zst && \
	rm -f /opt/wine-wow64.tar.zst && \
	sudo pacman -S --noconfirm winetricks

RUN useradd -m user && \
    gpasswd -a user wheel && \
	echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY pulse-client.conf /etc/pulse/client.conf

RUN yes | pacman -Scc

USER user
WORKDIR /home/user

FROM rust:1.77 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup set profile minimal && \
	rustup target add x86_64-pc-windows-gnu && \
	rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone --branch v0.1.0 --depth 1 https://github.com/quietvoid/runfromprocess-rs.git .
RUN cargo build --target x86_64-pc-windows-gnu --release

FROM zwift-base

COPY zwift.verb /home/user/zwift.verb
COPY wayland.reg /home/user/wayland.reg

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint

COPY zwift-auth.sh /bin/zwift-auth
RUN sudo chmod +x /bin/zwift-auth

COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /home/user/runfromprocess-rs.exe
RUN sudo chmod +x /home/user/runfromprocess-rs.exe
RUN sudo chown user:user /home/user/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]
