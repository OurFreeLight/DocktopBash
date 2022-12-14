# Docktop Bash
Docktop allows you to run full desktops securely out of containers. Since containers are not running in virtual machines you get near native performance of your machine and GPU support.

Unlike virtual machines, as the performance hit is minimal, we can even play games in these containers such as Counter-Strike: Global Offensive, Rocket League, Rust, and more.

This repository is for Docktop prototyping.

## Getting started
For the best experience, install Ubuntu MATE 22.04 or xUbuntu 22.04. Ubuntu 22.04 uses Wayland and as such has lots of graphical issues, Ubuntu MATE and xUbuntu do not use Wayland.

Windows and Mac are supported, however they will be running in virtual machines which will impact performance.

**NOTE:** When running DockTop, a new folder will be placed in this directory called `docktop_data`. You can change the DockTop data directory location by using the `--docktop_home` argument when running a container.

### Ubuntu Installation
After Ubuntu has been installed, be sure to install your video card drivers, then install Docker using the instructions at: https://docs.docker.com/engine/install/ubuntu/

You must also install weston, xwayland, and xsel by doing:
```console
sudo apt update
sudo apt install weston xsel xwayland
```

Once Ubuntu and Docker have been installed, you can build the Ubuntu 20.04 Mate images, by entering:
```console
./build-examples.sh
```

After the images have been built, you can run the example personal Mate image by entering:
```console
./runs/personal.sh $USER
```

By default, Weston will be used as the viewer and will start the container using Weston as the viewer.

For increased security, you can install TurboVNC or Remmina, be sure to disable encryption and that the encoding method is set to `Lossless Tight (Gigabit)`.

### Windows Installation 
Windows is supported by using WSL2, however it has not been thoroughly tested. GPU support has not been tested yet. Both AMD/NVIDIA might work?

WSL2 does use Hyper-V, which will use a virtual machine degrading performance.

Be sure to install the Ubuntu 22.04 app from the Windows Store. Once installed, install Docker Desktop with WSL2 support at: https://docs.docker.com/desktop/install/windows-install/

After Ubuntu 22.04 and Docker have been installed, follow the instructions for Ubuntu above. You will have to get Docker working inside of the Ubuntu WSL2 installation first.

Weston Viewer will be unavailable for Windows. As such, you will have to use TurboVNC to access the container's desktop.

The example run command to use VNC would be:
```console
./runs/personal.sh $USER vnc
```

### Mac Installation
Intel Mac is supported, however GPU support is not available at all. M2 Mac support should work, however this has not been tested. For M2 Macs there may be issues with trying to get containers to build.

Mac's will use virtual machines when running the containers, degrading performance.

Install Docker by following the guide at: https://docs.docker.com/desktop/install/mac-install/

Once Ubuntu and Docker have been installed, you can build the Ubuntu 20.04 Mate images, by entering:
```console
./build-examples.sh
```

Weston Viewer will be unavailable for Mac. As such, you will have to use TurboVNC to access the container's desktop.
```console
./runs/personal.sh $USER vnc
```

## Mounting
To mount a shared folder from your host filesystem to a location in your container you can enter:
```console
./run.sh --custom_mount="/mnt/ABSOLUTE_PATH_TO_YOUR_SHARED_FOLDER/:/mnt/shared"
```

## Creating a new image from a workspace or base image
Start the container like you normally would, for example:
```console
./run.sh detect developer
```

This will run the base `developer mate` container. Install all the applications and configure them however you want, then disconnect from `vncviewer`.

Using docker, exec into the running container and shut down the VNC Server by entering:
```console
vncserver -kill $DISPLAY
```

Backup the home directory, by entering:
```console
sudo docktop backup_home $USER
```

Exit the container, on the host system, commit the new docker image by doing:
```console
docker commit 7c053c9b67bb ourfreelight/new-image-name:version
```

## Building CLI Arguments
Typically you can build all images by doing `./build.sh` in this folder. However there are other command line options that can be used:
```
Usage: ./build.sh [options]

Options:
  --name(=string)                 Specify a custom name to use when building.
  --type(=string)                 The type of image to build.
  --window_manager(=string)       The window manager to use when building.
  --ubuntu_version(=string)       The ubuntu version to use.
  --base_image(=string)           The base image to use when building.
  --dockerfile(=string)           Specify a dockerfile to use to build.
  --build_dir(=string)            Specify a directory to build in.
  --version(=string)              Set the image version.
  --skip_latest                   Do not set this image tag as the latest.
  --timezone(=string)             Set the default timezone.

Types:
  all              Build all docker images.
  base             Build the base docker images.
  developer        Build the developer docker image.
  steam            Build the steam docker image.

Window Manager:
  all              Build all window manager docker images.
  gnome            Build only gnome type docker images.
  mate             Build only mate type docker images.
  xfce             Build only xfce type docker images.

Base images you can specify any base image you'd like to use, or select from:
Base Images:
  nvidia-opengl    Use the base nvidia glx image. This will only work on 
                   headless servers that do NOT have a GPU connected to X11.
```

To build Ubuntu 22.04 Mate images you can enter:
```console
./build.sh --base_image=ubuntu:22.04 --ubuntu_version=22.04
```

To build with the examples enter:
```console
./build-examples.sh 22.04
```

## Running CLI Arguments
To run images you can typically enter `./run.sh` and the base image will start running.

```
Usage: ./run.sh [options]

Options:
  --image(=string)                The image to use when running a custom image.
  --name(=string)                 The name of the container to run.
  --view_only                     If set, the container will not run, and will instead connect to an existing container.
  --display_name(=string)         The display name to use when running a container in a window (such as Weston).
  --type(=string)                 The type of container to run.
  --entrypoint(=string)           Set an entrypoint. Set to "empty" if you want to have an 
                                  empty entrypoint.
  --echo_cmd                      Echo out the final docker command to be executed.
  --no_audio                      Do not use pulse audio.
  --no_gpu                        Do not use the gpu.
  --use_vgl                       Use VirtualGL, works well with VNC, has visual issues however.
  --device(=string)               Attach a usb device.
  --display(=string)              Set the display to use.
  --env(=string)                  Set custom environmental variables to use.
  --list_usb_devices              List usb devices.
  --privileged                    Run the container in with privileged rights. SECURITY WARNING. 
                                  ONLY USE FOR TESTING OR WHEN USING SECURE CONTAINERS.
  --seccomp_unconfined            Use the unconfined seccomp profile.
  --screen_resolution(=string)    Set to the desired screen resolution in the format: 1024x768.
                                  Or if you'd like it to be detected enter: detect. Default: detect
  --screen_resolution_t(=string)  Set to the desired screen resolution for the second monitor in 
                                  the format: 1024x768. Or if you'd like it to be detected enter: 
                                  detect. Default: detect
  --window_manager(=string)       Set the window manager to use. See available window managers 
                                  below. Default: mate
  --user(=string)                 Run using the specified host user.
  --group(=string)                Run using the specified group user.
  --container_user(=string)       Run using the specified container user.
  --dont_mount_home_dir           Do not mount the user's home directory.
  --mount(=string)                Create a new directory to mount to the container.
  --network(=string)              Use a network, uses --network see docker documentation for details.
  --cap_add(=string)              Add a privilege, uses --cap-add see docker documentation for details.
  --port(=string)                 Expose a port, uses -p see docker documentation for details.
  --container_port(=string)       Set the port to use inside the container.
  --add_host(=string)             Add a host, uses --add-host see docker documentation for details.
  --dns(=string)                  Add DNS servers.
  --shared_memory_size(=string)   Set the shared memory size. Default: 16G
  --max_ulimit                    Set ulimit to the max.
  --viewer(=string)               Set the viewer to use. Can be: none,vnc,xpra,x11_forwarding,weston
                                  WARNING, IF x11_forwarding OR weston IS USED THIS SEVERELY LESSENS
                                  the benefits of containerization and can increase the vulnerability
                                  of the host system! Use with caution! The weston option will use 
                                  Xwayland and use the host's running X11 server.
  --daemon                        Run as a daemon.
  --custom_mount(=string)         Set a custom mount. If you specify "/home/user/shared:/mnt/shared",
                                  it will be mounted by docker like: -v "/home/user/shared:/mnt/shared"
  --docktop_home(=string)         Set the location for the Docktop home. This is where all container
                                  data will be placed. Default: /home/someone13/.docktop/

Types:
  all                             Run all docker images.
  base                            Run the base docker images.
  developer                       Run the developer docker image.
  steam                           Run the steam docker image.
  custom                          Run a custom image using this command, use 
                                  window_manager to specify the image name and 
                                  value1 to set the container name of the image.

Window Manager:
  gnome                           Run only gnome type docker images.
  mate                            Run only mate type docker images.
  xfce                            Run only xfce type docker images.
```

## Troubleshooting

### NodeJS / React Watch Building reports too many files open
This is due to the ulimit set by the containers. You can add `--max_ulimit` to increase this and should work afterwards.

### Certain Games Don't Work or Lag
The games listed at [ProtonDB](https://www.protondb.com/) should work for the most part. If there's any games that aren't working, try running the container by using `--device="/dev/fuse" --privileged`. This WILL DECREASE container security.

I've noticed when playing games in Weston there is a large FPS hit, whereas when playing using X11 Forwarding, there is no performance hit.

### Visual Studio Code doesn't work on Mac
Mac virtualization has an issue with symlinks and as such, VSCode has an issue running.