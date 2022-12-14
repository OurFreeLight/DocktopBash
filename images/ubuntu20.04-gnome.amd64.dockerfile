ARG BASEIMAGE="ubuntu:20.04"
FROM ${BASEIMAGE}

ARG DOCKTOP_VERSION
ENV DOCKTOP_VERSION ${DOCKTOP_VERSION}

ARG DISPLAY=:1
ENV DISPLAY ${DISPLAY}
ENV VGL_DISPLAY ${DISPLAY}
ARG SCREEN_RESOLUTION="1024x768"
ENV SCREEN_RESOLUTION ${SCREEN_RESOLUTION}
ENV TVNC_WM "2d"

ARG TURBOVNC_VERSION="2.2.6"
ARG LIBJPEGTURBO_VERSION="2.1.0"
ARG VIRTUALGL_VERSION="2.6.90"

ARG HOST_DOCKER_GID
ENV HOST_DOCKER_GID=${HOST_DOCKER_GID}

ARG HOST_DOCKER_GROUP
ENV HOST_DOCKER_GROUP=${HOST_DOCKER_GROUP}

ARG LANG="en_US.UTF-8"
ENV LANG ${LANG}

ARG TIMEZONE
ENV TIMEZONE ${TIMEZONE}

RUN apt update && apt upgrade -y

# Setup locales
RUN DEBIAN_FRONTEND=noninteractive apt install -y \
        locales tzdata apt-utils software-properties-common && \
        echo "$LANG UTF-8" >> /etc/locale.gen && \
        locale-gen

RUN ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
        dpkg-reconfigure --frontend noninteractive tzdata

# Install core Ubuntu stuff
RUN DEBIAN_FRONTEND=noninteractive apt install -y procps psutils sudo nano systemd \
        at-spi2-core pulseaudio wget net-tools locales tar bzip2 ttf-ubuntu-font-family \
        ttf-wqy-zenhei fonts-noto-color-emoji libxt6 rsync xorg

RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xauth wget ca-certificates curl libsm6 x11-xkb-utils xkb-data python \
        python-numpy supervisor xfonts-base unzip net-tools procps wmctrl \ 
        whoopsie libwhoopsie0

RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libpulse0 pulseaudio alsa-utils avahi-utils fonts-liberation gnupg \
        ibus openssh-client

# Install Mate stuff
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ubuntu-desktop-minimal

# Install GL/Vulkan related stuff
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libgl1-mesa-glx libgl1-mesa-dri libglvnd0 libgl1 libglx0 \
        libegl1 libegl1-mesa libxext6 libx11-6 mesa-utils mesa-utils-extra \
        libvulkan1 vulkan-utils

# Finish NVIDIA related Vulkan install
RUN VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)'` && \
        mkdir -p /etc/vulkan/icd.d/ && \
        echo "{\n\
                \"file_format_version\" : \"1.0.0\",\n\
                \"ICD\": {\n\
                \"library_path\": \"libGLX_nvidia.so.0\",\n\
                \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
                }\n\
        }" > /etc/vulkan/icd.d/nvidia_icd.json
COPY ./scripts/ubuntu/nvidia-egl.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

# Install VirtualGL
RUN cd /tmp && \
    wget https://sourceforge.net/projects/virtualgl/files/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    wget https://sourceforge.net/projects/virtualgl/files/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb ./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    chmod +x /usr/lib/libvglfaker.so /usr/lib/libdlfaker.so && \
    chmod +x /usr/lib32/libvglfaker.so /usr/lib32/libdlfaker.so && \
    chmod +x /usr/lib/i386-linux-gnu/libvglfaker.so /usr/lib/i386-linux-gnu/libdlfaker.so

# Install TurboVNC stuff
RUN cd /tmp && \
    wget https://sourceforge.net/projects/libjpeg-turbo/files/${LIBJPEGTURBO_VERSION}/libjpeg-turbo-official_${LIBJPEGTURBO_VERSION}_amd64.deb && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./libjpeg-turbo-official_${LIBJPEGTURBO_VERSION}_amd64.deb && \
    wget https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
    echo -e "no-remote-connections\n\
no-httpd\n\
no-x11-tcp-connections\n\
no-pam-sessions\n\
" > /etc/turbovncserver-security.conf

COPY ./scripts/ubuntu/ /etc/docktop

RUN ln -s /etc/docktop/docktop /usr/bin/docktop

# Setup the user
ENV USER someone13
ARG USERPW="ncr252"
ARG VNCPW="vncpassword"

ENV PATH="/opt/TurboVNC/bin:/opt/VirtualGL/bin:${PATH}"

RUN useradd --create-home --shell /bin/bash -p "$(openssl passwd -1 ${USERPW})" --user-group --groups adm,audio,cdrom,dialout,dip,fax,floppy,input,lp,lpadmin,netdev,plugdev,scanner,ssh,sudo,tape,tty,video,render,voice $USER

RUN dbus-uuidgen > /var/lib/dbus/machine-id && \
        mkdir -p /var/run/dbus && \
        dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address

RUN mkdir /home/$USER/.vnc && \
    chown -R ${USER}:${USER} /home/$USER/.vnc

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home

ENV PULSE_SERVER "unix:/usr/pulse-socket"

ENTRYPOINT [ "/etc/docktop/root_entrypoint.sh" ]

WORKDIR /home/$USER
