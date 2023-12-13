FROM archlinux:latest as zwift-base

RUN echo -e " \n\
[multilib] \n\
Include = /etc/pacman.d/mirrorlist \n\
" >> /etc/pacman.conf

RUN pacman -Syuu --noconfirm && \
	pacman -S --noconfirm sudo mesa pipewire-pulse wine winetricks wget

RUN useradd -m user && \
    gpasswd -a user wheel && \
	echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
COPY pulse-client.conf /etc/pulse/client.conf

RUN yes | pacman -Scc

USER user
WORKDIR /home/user

FROM rust:1.74 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone --branch v0.1.0 --depth 1 https://github.com/quietvoid/runfromprocess-rs.git .
RUN cargo build --target x86_64-pc-windows-gnu --release

FROM zwift-base

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint

COPY zwift-auth.sh /bin/zwift-auth
RUN sudo chmod +x /bin/zwift-auth

COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /home/user/runfromprocess-rs.exe
RUN sudo chmod +x /home/user/runfromprocess-rs.exe
RUN sudo chown user:user /home/user/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]
