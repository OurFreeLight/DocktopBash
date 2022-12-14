ARG BASEIMAGE="ubuntu:22.04"
FROM ${BASEIMAGE}

ARG DOCKTOP_VERSION
ENV DOCKTOP_VERSION ${DOCKTOP_VERSION}
ENV TVNC_WM "mate-session"

ARG TURBOVNC_VERSION="2.2.6"
ARG LIBJPEGTURBO_VERSION="2.1.2"
ARG VIRTUALGL_VERSION="2.6.90"

ARG HOST_DOCKER_GID
ENV HOST_DOCKER_GID=${HOST_DOCKER_GID}

ARG HOST_DOCKER_GROUP
ENV HOST_DOCKER_GROUP=${HOST_DOCKER_GROUP}

ARG LANG="en_US.UTF-8"
ENV LANG ${LANG}

ARG TIMEZONE
ENV TIMEZONE ${TIMEZONE}

RUN dpkg --add-architecture i386 && \
    apt update && apt upgrade -y

# Setup locales
RUN DEBIAN_FRONTEND=noninteractive apt install -y \
        locales tzdata apt-utils software-properties-common && \
        echo "$LANG UTF-8" >> /etc/locale.gen && \
        locale-gen

RUN ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
        dpkg-reconfigure --frontend noninteractive tzdata

# Install core Ubuntu stuff
RUN DEBIAN_FRONTEND=noninteractive apt install -y procps psutils sudo nano systemd \
        at-spi2-core wget net-tools locales tar bzip2 \
        fonts-wqy-zenhei fonts-noto-color-emoji libxt6 rsync xorg jq

RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xauth wget ca-certificates curl libsm6 x11-xkb-utils xkb-data python3 \
        python3-numpy supervisor xfonts-base unzip net-tools procps wmctrl \ 
        fonts-liberation gnupg ibus openssh-client whoopsie libwhoopsie0 \
        avahi-utils

# Install Mate stuff
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ubuntu-mate-desktop

RUN apt-get autoremove --purge -y blueman bluez bluez-cups pulseaudio-module-bluetooth

# Install GL/Vulkan related stuff
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libgl1-mesa-glx libgl1-mesa-dri libglvnd0 libgl1 libglx0 \
        libegl1 libegl1-mesa libxext6 libx11-6 mesa-utils mesa-utils-extra \
        libvulkan1 vulkan-tools libvulkan1:i386 libgl1-mesa-dri:i386 \
        mesa-vulkan-drivers mesa-vulkan-drivers:i386

# Correct Vulkan installation
RUN VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)'`

# Finish NVIDIA related install
RUN mkdir -p /etc/vulkan/icd.d/ && \
        echo "{\n\
                \"file_format_version\" : \"1.0.0\",\n\
                \"ICD\": {\n\
                \"library_path\": \"libGLX_nvidia.so.0\",\n\
                \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
                }\n\
        }" > /etc/vulkan/icd.d/nvidia_icd.json
COPY ./scripts/ubuntu/nvidia-egl.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

# Finish AMD related install
RUN VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)'` && \
        mkdir -p /etc/vulkan/icd.d/ && \
        echo "{\n\
                \"file_format_version\" : \"1.0.0\",\n\
                \"ICD\": {\n\
                \"library_path\": \"/opt/amdgpu/lib/x86_64-linux-gnu/libEGL.so.1\",\n\
                \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
                }\n\
        }" > /etc/vulkan/icd.d/amd_icd.json
COPY ./scripts/ubuntu/amd-egl.json /usr/share/glvnd/egl_vendor.d/9_amd.json

# Install VirtualGL
RUN cd /tmp && \
    wget https://sourceforge.net/projects/virtualgl/files/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    wget https://sourceforge.net/projects/virtualgl/files/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    chmod u+s /usr/lib/libvglfaker.so /usr/lib/libdlfaker.so && \
    chmod u+s /usr/lib32/libvglfaker.so /usr/lib32/libdlfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libvglfaker.so /usr/lib/i386-linux-gnu/libdlfaker.so

ENV PATH="/opt/VirtualGL/bin:${PATH}"

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

ENV PATH="/opt/TurboVNC/bin:${PATH}"

# Install audio stuff
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libpulse0 pulseaudio alsa-utils

# Setup the user
ENV USER someone13
ARG USERPW="ncr252"

RUN useradd --create-home --shell /bin/bash -p "$(openssl passwd -1 ${USERPW})" --user-group --groups adm,audio,cdrom,dialout,dip,fax,floppy,input,lp,lpadmin,netdev,plugdev,scanner,sudo,tape,tty,video,render,voice $USER
RUN groupadd power && \
    usermod --groups power --append $USER

RUN dbus-uuidgen > /var/lib/dbus/machine-id && \
    mkdir -p /var/run/dbus && \
    dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address

# Install Xpra
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xpra

# Setup Xpra for the user @fixme Create an xpra group and add the user to that group for /run/xpra
RUN USER_ID=$(id -u ${USER}) && \
        mkdir -p /run/user/$USER_ID/xpra && \
        mkdir -p /run/xpra && \
       chown $USER:$USER /run/user/$USER_ID/xpra && \
       chown $USER:$USER /run/xpra

# Pulseaudio fix for audio redirection to host.
COPY ./scripts/ubuntu/pulseaudio-client.conf /etc/pulse/client.conf
ENV PULSE_SERVER "unix:/usr/pulse-socket"

COPY ./scripts/ubuntu/ /etc/docktop

RUN ln -s /etc/docktop/docktop /usr/bin/docktop

RUN mkdir /home/$USER/.vnc && \
    cp -f /etc/docktop/xstartup/xstartup.mate.turbovnc /home/$USER/.vnc/xstartup.turbovnc && \
    chown -R ${USER}:${USER} /home/$USER/.vnc

ARG DISPLAY=:100
ENV DISPLAY ${DISPLAY}
ENV VGL_DISPLAY ${DISPLAY}
ARG SCREEN_RESOLUTION="1024x768"
ENV SCREEN_RESOLUTION ${SCREEN_RESOLUTION}

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home

ENTRYPOINT [ "/etc/docktop/root_entrypoint.sh" ]

WORKDIR /home/$USER
