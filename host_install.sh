#!/bin/bash

echo "Installing host dependencies..."

sudo apt update

if [ -x "$(command -v docker)" ]; then
    echo "Docker already installed..."
else
    echo "Installing Docker..."
    sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo "Finished installing Docker..."
fi

if [ -x "$(command -v /opt/TurboVNC/bin/vncviewer)" ]; then
    echo "TurboVNC already installed..."
else
    TURBOVNC_VERSION="2.2.6"
    LIBJPEGTURBO_VERSION="2.1.0"

    cd /tmp && \
        wget https://sourceforge.net/projects/libjpeg-turbo/files/${LIBJPEGTURBO_VERSION}/libjpeg-turbo-official_${LIBJPEGTURBO_VERSION}_amd64.deb && \
        env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./libjpeg-turbo-official_${LIBJPEGTURBO_VERSION}_amd64.deb && \
        wget https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
        env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./turbovnc_${TURBOVNC_VERSION}_amd64.deb
fi

if [ -x "$(command -v /opt/TurboVNC/bin/vncviewer)" ]; then
    echo "VirtualBox already installed..."
else
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
    sudo apt-get update
    sudo apt-get install -y virtualbox-6.1
fi

if [ -x "$(command -v aws)" ]; then
    echo "AWS already installed..."
else
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip ./awscliv2.zip
    sudo ./aws/install
fi

sudo apt install -y weston xwayland xsel sshfs default-jre

echo "Finished installing host dependencies..."