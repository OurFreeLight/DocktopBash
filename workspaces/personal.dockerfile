ARG BASEIMAGE="amd64/ubuntu20.04-docktop-mate:latest"
FROM ${BASEIMAGE}

# Install Visual Studio Code
RUN cd /tmp && \
    wget -O ./vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./vscode.deb

# Install Discord
RUN cd /tmp && \
    wget -O ./discord.deb "https://discord.com/api/download?platform=linux&format=deb" && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./discord.deb

# Install Chrome
RUN cd /tmp && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./google-chrome-stable_current_amd64.deb

# Install ping
RUN DEBIAN_FRONTEND=noninteractive apt install -y iputils-ping

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home
