#!/bin/bash

set -e

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# get config
if [ -n "$1" ]; then
  CONFIG_FILE="$1"
else
  CONFIG_FILE="etc/terraform.conf"
fi
BASE_DIR="$PWD"
source "$BASE_DIR"/"$CONFIG_FILE"

echo -e "
#----------------------#
# INSTALL VANILLA REPO #
#----------------------#
"
# Install required gnupg2 for apt-key
apt-get update
apt-get install -y gnupg2

# Add vanilla sources
cat > /etc/apt/sources.list.d/vanilla-base.list <<EOF
deb [arch=amd64] http://repo.vanillaos.org/ $BASECODENAME main
EOF

# Add vanilla repo key
apt-key add "$BASE_DIR"/etc/config/archives/vanilla.key
apt-key add "$BASE_DIR"/etc/config/archives/vanilla-main.key

# Add vanilla keyring
cp "$BASE_DIR"/etc/config/includes.chroot/usr/share/keyrings/vanilla_keyring.gpg /usr/share/keyrings/

# Remove stock debian sources
rm -f /etc/apt/sources.list.d/debian.sources

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"
apt-get update
apt-get install -y live-build patch binutils zstd ca-certificates
dpkg -i debs/*.deb

# TODO: workaround a bug in lb by increasing number of blocks for creating efi.img

# TODO: Remove this once debootstrap has a script to build lunar images in our container:
# https://salsa.debian.org/installer-team/debootstrap/blob/master/debian/changelog
ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/lunar

build () {
  BUILD_ARCH="$1"
  mkdir -p "$BASE_DIR/tmp/$BUILD_ARCH"
  cd "$BASE_DIR/tmp/$BUILD_ARCH" || exit

  # remove old configs and copy over new
  rm -rf config auto
  cp -r "$BASE_DIR"/etc/* .
  # Make sure conffile specified as arg has correct name
  cp -f "$BASE_DIR"/"$CONFIG_FILE" terraform.conf

  # Symlink chosen package lists to where live-build will find them
  ln -s "package-lists.$PACKAGE_LISTS_SUFFIX" "config/package-lists"

  echo -e "

#------------------#
# LIVE-BUILD CLEAN #
#------------------#
"
  lb clean

  echo -e "
#-------------------#
# LIVE-BUILD CONFIG #
#-------------------#
"
  lb config

  echo -e "
#------------------#
# LIVE-BUILD BUILD #
#------------------#
"
  lb build

  echo -e "
#---------------------------#
# MOVE OUTPUT TO BUILDS DIR #
#---------------------------#
"
  YYYYMMDD="$(date +%Y%m%d)"
  OUTPUT_DIR="$BASE_DIR/builds/$BUILD_ARCH"
  mkdir -p "$OUTPUT_DIR"
  FNAME="VanillaOS-$VERSION-$CHANNEL.$YYYYMMDD$OUTPUT_SUFFIX"
  mv "$BASE_DIR/tmp/$BUILD_ARCH/live-image-$BUILD_ARCH.hybrid.iso" "$OUTPUT_DIR/${FNAME}.iso"

  # cd into output to so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  cd $OUTPUT_DIR
  md5sum "${FNAME}.iso" > "${FNAME}.md5.txt"
  sha256sum "${FNAME}.iso" > "${FNAME}.sha256.txt"
  cd $BASE_DIR
}

if [[ "$ARCH" == "all" ]]; then
    build amd64
else
    build "$ARCH"
fi
