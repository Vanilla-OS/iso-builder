<div align="center">

## ISO Builder

<sup2>This ISO builder was basically a combination of previous efforts from Ubuntu
Budgie, some stuff from livecd-rootfs from Launchpad
and Elementary OS, thanks to the amazing devs from all around!
Elememtary OS Link: https://github.com/elementary/os</sup2>

 And this is a fork of Vanilla OS, More info at: https://github.com/Vanilla-OS
------------

</div>

> Releases usually follows the Ubuntu release cycle i.e. `22.10, 23.04..`. Releases named `22.10-r1` means that the release is still 22.10 with just a refreshed of the repositories and packages, this is meant to help users getting the latest release with updated packages, with more fixes and features OTB.

## Why not just fork from livecd-rootfs?

The Ubuntu ISO's are built with ubuntu-cdimage scripts and with livecd-rootfs,
but it has a lot of extra scripts that are hard to navigate all at once unless
you have previous experience and is a bottomless well of asterisks attached to it.
It's better to get something not perfect, but close enough.

## Building Locally

As UCR is built with the Debian version of `live-build`, not the Ubuntu patched version, it's easiest to build an iso in a Debian VM or container. This prevents messing up your host system too.

The following example uses Docker and assumes you have Docker correctly installed and set up:

 1) Clone this project & `cd` into it:

    ```
    git clone https://github.com/OliDoDEV/Vanillin-OS.git && cd os
    ```

 2) Configure the channel in the `etc/terraform.conf` (unstable, all).

 3) Run the build:

    ```
    docker run --privileged -i -v /proc:/proc \
        -v ${PWD}:/working_dir \
        -w /working_dir \
        debian:sid \
        /bin/bash -s etc/terraform.conf < build.sh
    ```

 4) When done, your image will be in the `builds` folder.
