ARG BASEIMAGE="amd64/ubuntu20.04-docktop-mate:latest"
FROM ${BASEIMAGE}

ARG SLACK_VERSION="4.24.0"
ARG DOCKER_COMPOSE_VERSION="1.29.2"

RUN apt update

RUN sudo su - $USER && \
    ulimit -Sn 65535 && \
    exit

RUN echo "session required pam_limits.so" >> /etc/pam.d/common-session && \
    echo "$USER soft  nofile 40000" >> /etc/security/limits.conf && \
    echo "$USER hard  nofile 100000" >> /etc/security/limits.conf && \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf && \
    echo "fs.inotify.max_user_instances=8192" >> /etc/sysctl.conf && \
    sysctl --system

# Install common packages
RUN apt update && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    build-essential git libxcb-randr0 filezilla iputils-ping less mysql-client

# MySql client fix
RUN echo "[client]" >> /etc/mysql/conf.d/mysql.cnf && \
    echo "protocol=tcp" >> /etc/mysql/conf.d/mysql.cnf

# Install NodeJS and make npm install from the user directory.
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && \
    apt-get install -y --force-yes nodejs && \
    mkdir "/home/$USER/.npm-packages" && \
    echo "NPM_PACKAGES=\"/home/$USER/.npm-packages\"" >> /home/$USER/.bashrc && \
    echo "NODE_PATH=\"\$NPM_PACKAGES/lib/node_modules:\$NODE_PATH\"" >> /home/$USER/.bashrc && \
    echo "PATH=\"\$NPM_PACKAGES/bin:\$PATH\"" >> /home/$USER/.bashrc && \
    echo "unset MANPATH" >> /home/$USER/.bashrc && \
    echo "MANPATH=\"\$NPM_PACKAGES/share/man:\$(manpath)\"" >> /home/$USER/.bashrc && \
    echo "prefix=/home/$USER/.npm-packages" >> /home/$USER/.npmrc

# Install Visual Studio Code
RUN cd /tmp && \
    wget -O ./vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./vscode.deb

# Install Chrome
RUN cd /tmp && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./google-chrome-stable_current_amd64.deb

# Install Zoom
RUN cd /tmp && \
    wget https://zoom.us/client/latest/zoom_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./zoom_amd64.deb

# Install Slack
RUN cd /tmp && \
    wget https://downloads.slack-edge.com/releases/linux/${SLACK_VERSION}/prod/x64/slack-desktop-${SLACK_VERSION}-amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt install -y ./slack-desktop-${SLACK_VERSION}-amd64.deb

# Install Docker.
RUN groupadd docker
RUN env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
RUN mkdir -p /etc/docker && \
    echo '{ "features": { "buildkit": true }, "storage-driver": "vfs" }' > /etc/docker/daemon.json
RUN usermod -aG docker $USER
RUN systemctl enable docker.service

# Clean up and backup the user's home directory for future home volume mounting.
RUN docktop clean && \
    docktop backup_home
