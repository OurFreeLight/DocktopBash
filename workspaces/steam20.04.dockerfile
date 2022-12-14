ARG BASEIMAGE="amd64/ubuntu20.04-docktop-mate:latest"
FROM ${BASEIMAGE}

ARG WINE_GECKO_VERSION="2.47.2"
ARG WINE_MONO="7.0.0"

RUN apt update

# Install wine
RUN cd /tmp && \
        wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
        apt-key add ./winehq.key
RUN add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' && \
        apt update
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --install-recommends \
        winehq-stable
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        fonts-wine ttf-mscorefonts-installer winetricks

RUN mkdir -p /usr/share/wine/gecko && \
    cd /usr/share/wine/gecko && \
      wget https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86.msi && \
      wget https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86_64.msi && \
    mkdir -p /usr/share/wine/mono && \
    cd /usr/share/wine/mono && \
      wget https://dl.winehq.org/wine/wine-mono/${WINE_MONO}/wine-mono-${WINE_MONO}-x86.msi

# Install q4wine
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        q4wine

# Install Firefox
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        firefox libc6:i386

RUN mkdir -p /etc/skel/Desktop && \
echo '#! /bin/bash \n\
datei="/etc/skel/Desktop/$(echo "$1" | LC_ALL=C sed -e "s/[^a-zA-Z0-9,.-]/_/g" ).desktop" \n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=$1\n\
Exec=$2\n\
Icon=$3\n\
" > $datei \n\
chmod +x $datei \n\
' >/usr/local/bin/createicon && chmod +x /usr/local/bin/createicon && \
\
createicon "Q4wine"             "q4wine"            q4wine && \
createicon "Internet Explorer"  "wine iexplore"     applications-internet && \
createicon "Console"            "wineconsole"       utilities-terminal && \
createicon "File Explorer"      "wine explorer"     folder && \
createicon "Notepad"            "wine notepad"      wine-notepad && \
createicon "Wordpad"            "wine wordpad"      accessories-text-editor && \
createicon "winecfg"            "winecfg"           wine-winecfg && \
createicon "WineFile"           "winefile"          folder-wine && \
createicon "Mines"              "wine winemine"     face-cool && \
createicon "winetricks"         "winetricks -gui"   wine && \
createicon "Registry Editor"    "regedit"           preferences-system && \
createicon "UnInstaller"        "wine uninstaller"  wine-uninstaller && \
createicon "Taskmanager"        "wine taskmgr"      utilities-system-monitor && \
createicon "Control Panel"      "wine control"      preferences-system && \
createicon "OleView"            "wine oleview"      preferences-system && \
createicon "CJK fonts installer chinese japanese korean"  "xterm -e \"winetricks cjkfonts\""  font

# Install Discord
RUN cd /tmp && \
    wget -O ./discord.deb "https://discord.com/api/download?platform=linux&format=deb" && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./discord.deb

# Install Chrome
RUN cd /tmp && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./google-chrome-stable_current_amd64.deb

# Install Steam
# @fixme This was working great, what happened?
RUN cd /tmp && \
    env DEBIAN_FRONTEND=noninteractive apt install -y xdg-desktop-portal xdg-desktop-portal-gtk && \
    wget "https://cdn.akamai.steamstatic.com/client/installer/steam.deb" && \
    env DEBIAN_FRONTEND=noninteractive apt install -y ./steam.deb

RUN env DEBIAN_FRONTEND=noninteractive apt install -y \
        wayland-protocols libglfw3-wayland

RUN ulimit -Sn 65535 && \
    echo "session required pam_limits.so" >> /etc/pam.d/common-session && \
    echo "$USER soft  nofile 40000" >> /etc/security/limits.conf && \
    echo "$USER hard  nofile 100000" >> /etc/security/limits.conf

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home
