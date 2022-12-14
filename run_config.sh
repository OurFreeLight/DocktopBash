#!/usr/bin/env bash

PORT=$(( ( RANDOM % 5999 )  + 5900 ))
X11_FORWARDING=""
UBUNTU_VERSION="20.04"
PRIVILEGED=""
DOCKER_SECCOMP_PROFILE=""
DOCKER_SOCKET="-v /var/run/docker.sock:/var/run/docker.sock:ro"
#SYSTEMD="–v /sys/fs/cgroup:/sys/fs/cgroup:ro --cap-add SYS_ADMIN"
#FUSE="--security-opt apparmor:unconfined --cap-add mknod --cap-add sys_admin --device=/dev/fuse"
MOUNT_BASE="$DOCKTOP_HOME"
SHARED_VOLUME="-v ${MOUNT_BASE}/host_shared:/mnt/host_shared:z"
INTERNAL_PORT="5901"
SET_CUSTOM_MOUNTS=""
SET_USB_DEVICES=""
PORTS=""
NETWORKING=""
SHM_SIZE="16g"
SOUND=""
GPU=""
PID_TO_CLOSE1=""
PID_TO_CLOSE2=""

if [ "$USE_SECCOMP_UNCONFINED_PROFILE" == "1" ]; then
    DOCKER_SECCOMP_PROFILE="--security-opt seccomp=unconfined"
fi

if [ "$USE_VIEWER" == "x11_forwarding" ] || [ "$USE_VIEWER" == "weston" ]; then
    # @fixme Create a new XAuthority. SHOULD NOT BE USING THE USERS XAUTHORITY.
    X11_FORWARDING="-v /tmp/.X11-unix:/tmp/.X11-unix -v /home/$RUN_USER/.Xauthority:/home/$RUN_USER/.Xauthority"
fi

# Check if PulseAudio is installed on the host.
if [ -x "$(command -v pulseaudio)" ] && [ "$USE_AUDIO" == "1" ]; then
    SOUND="-v /run/user/$UID/pulse/native:/usr/pulse-socket"
    echo "Running with pulse audio..."
else
    echo "Running without audio..."
fi

# Detect if NVIDIA Docker is installed
if [ -x "$(command -v nvidia-docker)" ] && [ "$NO_GPU" == "" ]; then
    GPU="--runtime=nvidia --gpus 1 --device=/dev/kfd:rw --device=/dev/dri:rw --device=/dev/vga_arbiter:rw --group-add video --group-add render --env QT_X11_NO_MITSHM=1 --env NVIDIA_DRIVER_CAPABILITIES=all --env NVIDIA_VISIBLE_DEVICES=all"
    echo "Running with NVIDIA GPU support..."
fi

# Detect if AMD is installed
if [ -x "$(command -v amdgpu-uninstall)" ] && [ ! -x "$(command -v rocm-smi)" ] && [ "$NO_GPU" == "" ]; then
    GPU="--device=/dev/kfd:rw --device=/dev/dri:rw --device=/dev/vga_arbiter:rw --group-add video --group-add render"
    echo "Running with AMD GPU support WITHOUT ROCm..."
fi

# Detect if AMD ROCm is installed
if [ -x "$(command -v rocm-smi)" ] && [ "$NO_GPU" == "" ]; then
    GPU="--device=/dev/kfd:rw --device=/dev/dri:rw --group-add video --group-add render"
    echo "Running with AMD ROCm GPU support..."
fi

if [ -z "$GPU" ]; then
    echo "Running without GPU support..."
fi

# Setup the docktop directory.
setupDocktop() {
    mkdir -p $MOUNT_BASE/host_shared 2> /dev/null
}

# Fix the permissions on a mounted volume.
#
# @arg $1 - Set the user that will own the directory.
# @arg $2 - Set the group that will own the directory.
# @arg $3 - The volume path that will have it's permissions be fixed.
fixMountedVolume() {
    local VOLUME_USER=$1
    local VOLUME_GROUP=$2
    local VOLUME_PATH=$3

    if [ ! -d "$VOLUME_PATH" ]; then
        echo "Volume $VOLUME_PATH does not exist, creating it now."
        mkdir -p $VOLUME_PATH
        chown $VOLUME_USER:$VOLUME_GROUP "$VOLUME_PATH"
    fi

    local DIR_USER=""
    local DIR_GROUP=""

    if [ "$(uname -a | grep Darwin)" ]; then
        DIR_USER=$(stat -f "%Su" "$VOLUME_PATH")
        DIR_GROUP=$(stat -f "%Sg" "$VOLUME_PATH")
    else
        DIR_USER=$(stat -c "%U" "$VOLUME_PATH")
        DIR_GROUP=$(stat -c "%G" "$VOLUME_PATH")
    fi

    if [ "$DIR_USER" != "$(id -un)" ] || [ "$DIR_GROUP" != "$(id -gn)" ]; then
        echo "The permissions on volume $VOLUME_PATH need to be changed. sudo needs to be used now:"
        sudo chown $VOLUME_USER:$VOLUME_GROUP "$VOLUME_PATH"
        echo "Permissions were changed on volume $VOLUME_PATH"
    fi
}

# Setup the mounts for use.
setupMounts() {
    local CONTAINER_PATH=$1
    local VOLUME_USER=$2
    local VOLUME_GROUP=$3

    if [ "${VOLUMES_TO_MOUNT}" != "" ]; then
        for i in "${VOLUMES_TO_MOUNT[@]}"
        do
            TEMP_VOLUME="${CONTAINER_PATH}/${i}/"
            fixMountedVolume "$VOLUME_USER" "$VOLUME_GROUP" "$TEMP_VOLUME";

            MOUNT_VOLUMES="${MOUNT_VOLUMES}-v ${TEMP_VOLUME}:/mnt/${i} "
        done
    fi

    if [ "$MOUNT_HOME_DIR" == "1" ]; then
        MOUNT_VOLUMES="${MOUNT_VOLUMES}-v ${CONTAINER_PATH}/home_dir/:/home/${CONTAINER_USER} "
        fixMountedVolume "$RUN_USER" "$RUN_GROUP" "${CONTAINER_PATH}/home_dir/"
    fi

    if [ "${CUSTOM_MOUNTS}" != "" ]; then
        for i in "${CUSTOM_MOUNTS[@]}"
        do
            SET_CUSTOM_MOUNTS="${SET_CUSTOM_MOUNTS}-v ${i} "
        done
    fi

    if [ "${ATTACH_USBS}" != "" ]; then
        for i in "${ATTACH_USBS[@]}"
        do
            SET_USB_DEVICES="${SET_USB_DEVICES}--device=${i} "
        done
    fi
}

# Start the VNC viewer.
startViewer() {
    local CONTAINER_PATH=$1

    if [ "$ECHO_CMD" == "" ]; then
        if [ "$USE_VIEWER" == "vnc" ]; then
            $(sleep 3 && ../vncviewer.sh ${PORT}) &
        fi

        if [ "$USE_VIEWER" == "xpra" ]; then
            $(sleep 3 && ../xpraviewer.sh ${PORT}) &
        fi

        if [ "$USE_VIEWER" == "x11_forwarding" ]; then
            setupX11Forwarding "$CONTAINER_PATH";
        fi

        if [ "$USE_VIEWER" == "weston" ]; then
            setupWeston "$CONTAINER_PATH";
        fi
    fi
}

# Setup the X11 host for forwarding 
setupX11Forwarding() {
    local CONTAINER_PATH=$1

    if [ "$RUN_AS_DAEMON" == "1" ]; then
        echo "Cannot run as a daemon when X11 forwarding..."

        exit 1
    fi

    echo "Creating new X11 server on display $USE_DISPLAY..."

    exec "/usr/bin/Xorg" "${USE_DISPLAY}" "vt8" "-modulepath" "/usr/lib/xorg/modules" "-retro" "+extension" "RANDR" "+extension" "RENDER" "+extension" "GLX" "+extension" "XVideo" "+extension" "DOUBLE-BUFFER" "+extension" "SECURITY" "+extension" "DAMAGE" "+extension" "X-Resource" "-extension" "MIT-SHM" "+extension" "Composite" "+extension" "COMPOSITE" "-extension" "XINERAMA" "-xinerama" "-extension" "XTEST" "-tst" "-dpms" "-s" "off" "-nolisten" "tcp" "-dpi" "96" &
    PID_TO_CLOSE1=$(echo $!)

    sleep 2
}

# Setup Xwayland and Weston
setupWeston() {
    local CONTAINER_PATH=$1

    #if [ "$RUN_AS_DAEMON" == "1" ]; then
    #    echo "Cannot run as a daemon when using Xwayland/Weston..."

    #    exit 1
    #fi

    echo "Creating new Weston server on display $USE_DISPLAY..."

    export WAYLAND_DISPLAY=wayland${USE_DISPLAY}
    export XDG_RUNTIME_DIR="/run/user/$(id -u ${USER})"

    local WESTON_FILE_PATH=$(pwd)"/weston-${WAYLAND_DISPLAY}-temp.ini"

    cat >"${WESTON_FILE_PATH}" <<EOF
[core]
shell=desktop-shell.so
idle-time=0
[shell]
panel-location=none
panel-position=none
locking=true
background-color=0xff002244
animation=fade
startup-animation=fade
[keyboard]

EOF

    local TEMP_NAME="X"

    if [ "$DISPLAY_NAME" != "" ]; then
        TEMP_NAME="$DISPLAY_NAME"
    fi

    echo "[output]" >> "${WESTON_FILE_PATH}"
    echo "name=X${TEMP_NAME}${USE_DISPLAY}" >> "${WESTON_FILE_PATH}"
    echo "mode=${SCREEN_RESOLUTION}" >> "${WESTON_FILE_PATH}"

    if [ "$SCREEN_RESOLUTION2" != "" ]; then
        echo "" >> "${WESTON_FILE_PATH}"
        echo "[output]" >> "${WESTON_FILE_PATH}"
        echo "name=XT${TEMP_NAME}${USE_DISPLAY}" >> "${WESTON_FILE_PATH}"
        echo "mode=${SCREEN_RESOLUTION2}" >> "${WESTON_FILE_PATH}"
    fi

    chmod +x "${WESTON_FILE_PATH}"

    #weston --socket=${WAYLAND_DISPLAY} --backend=wayland-backend.so --config="${WESTON_FILE_PATH}" &
    weston --socket=${WAYLAND_DISPLAY} --backend=x11-backend.so --config="${WESTON_FILE_PATH}" &
    PID_TO_CLOSE1=$(echo $!)

    sleep 1

    rm "${WESTON_FILE_PATH}"

    #exec env XDG_SESSION_TYPE=wayland env DISPLAY=${USE_DISPLAY} "dbus-run-session" "gnome-session" &

    exec "/usr/bin/Xwayland" "${USE_DISPLAY}" "-retro" "+extension" "RANDR" "+extension" "RENDER" \
        "+extension" "GLX" "+extension" "XVideo" "+extension" "DOUBLE-BUFFER" "+extension" "SECURITY" \
        "+extension" "DAMAGE" "+extension" "X-Resource" "-extension" "MIT-SHM" "+extension" "Composite" \
        "+extension" "COMPOSITE" "-extension" "XTEST" "-tst" "-dpms" "-s" "off" \
        "-nolisten" "tcp" "-dpi" "96" &
    PID_TO_CLOSE2=$(echo $!)

    sleep 2
}

# Update the docker options to be used.
updateOpts() {
    if [ "$USE_PRIVILEGED" == "1" ]; then
        PRIVILEGED="--privileged"
        echo "Running container in privileged mode. SECURITY WARNING: ONLY USE TRUSTED CONTAINERS FOR THIS. THIS IS NOT RECOMMENDED TO DO."
    fi

    if [ "$SHARED_MEMORY_SIZE" != "" ]; then
        SHM_SIZE=$SHARED_MEMORY_SIZE
    fi

    if [ "${USE_NETWORK}" != "" ]; then
        echo "Using network $USE_NETWORK"
        NETWORKING="--network $USE_NETWORK"
    fi

    if [ "${EXPOSE_PORTS}" != "" ]; then
        for i in "${EXPOSE_PORTS[@]}"
        do
            echo "Exposing port ${i}"
            PORTS="${PORTS}-p ${i} "
        done
    fi

    local ADDING_HOSTS=""

    if [ "${ADD_HOSTS}" != "" ]; then
        for i in "${ADD_HOSTS[@]}"
        do
            echo "Adding environment variable: ${i}"
            ADDING_HOSTS="${ADDING_HOSTS}--add-host=${i} "
        done
    fi

    local ADDING_DNS=""

    if [ "${ADD_DNS}" != "" ]; then
        for i in "${ADD_DNS[@]}"
        do
            echo "Adding DNS: ${i}"
            ADDING_DNS="${ADDING_DNS}--dns=${i} "
        done
    fi

    local ADDING_ENVS=""

    if [ "${ADD_ENVS}" != "" ]; then
        for i in "${ADD_ENVS[@]}"
        do
            echo "Adding env ${i}"
            ADDING_ENVS="${ADDING_ENVS}--env ${i} "
        done
    fi

    local ADDING_CAPS=""

    if [ "${ADD_CAPS}" != "" ]; then
        for i in "${ADD_CAPS[@]}"
        do
            echo "Adding capability ${i}"
            ADDING_CAPS="${ADDING_CAPS}--cap-add ${i} "
        done
    fi

    local RUN_TYPE="-it"
    local SET_MAX_ULIMIT=""

    if [ "$RUN_AS_DAEMON" == "1" ]; then
        RUN_TYPE="-d"
    fi

    if [ "$MAX_ULIMIT" == "1" ]; then
        SET_MAX_ULIMIT="--ulimit nofile=65535:65535"
    fi

    INTERNAL_PORT=$USE_INTERNAL_PORT

    OPTS="--rm ${RUN_TYPE} ${PRIVILEGED} ${DOCKER_SECCOMP_PROFILE} ${SET_MAX_ULIMIT} ${NETWORKING} ${ADDING_DNS} ${PORTS} ${ADDING_HOSTS} ${SET_USB_DEVICES} ${ADDING_CAPS} ${ADDING_ENVS} --env USE_VGL=${USE_VGL} --env USE_AUDIO=${USE_AUDIO} --env USE_VIEWER=${USE_VIEWER} ${ENTRYPOINT} --shm-size=${SHM_SIZE} ${X11_FORWARDING} ${SET_CUSTOM_MOUNTS} ${MOUNT_VOLUMES} ${SHARED_VOLUME} ${GPU} ${SOUND} --security-opt seccomp=../chrome.json --env DISPLAY=${USE_DISPLAY} --env SCREEN_RESOLUTION=$SCREEN_RESOLUTION"

    if [ "$USE_VIEWER" == "vnc" ]; then
        echo "VNC running on port ${PORT}"
    fi

    if [ "$USE_VIEWER" == "xpra" ]; then
        echo "XPRA running on port ${PORT}"
    fi
}