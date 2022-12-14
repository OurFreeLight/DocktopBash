ARG BASEIMAGE="amd64/ubuntu22.04-docktop-mate:latest"
FROM ${BASEIMAGE}

ARG WINE_GECKO_VERSION="2.47.2"
ARG WINE_MONO="6.3.0"

# Install wine
RUN mkdir -pm755 /etc/apt/keyrings && \
        wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
        wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
        apt update
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --install-recommends \
        winehq-staging
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

RUN env DEBIAN_FRONTEND=noninteractive apt install -y \
        wayland-protocols libglfw3-wayland

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home
