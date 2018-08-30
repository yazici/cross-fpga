#!/bin/bash

DATE_VERSION=2018-08

# -- Target architectures
ARCH=$1
TARGET_ARCHS="linux_x86_64 linux_i686 linux_armv7l linux_aarch64 windows_x86 windows_amd64 darwin"
J=$(($(nproc)-1))

# -- Debug flags
BUILD_SYSTEM=0
BUILD_YOSYS=0
BUILD_ICE40=1

# -- Store current dir
WORK_DIR=$PWD
# -- Folder for building the source code
BUILDS_DIR=$WORK_DIR/_builds
# -- Folder for storing the generated packages
PACKAGES_DIR=$WORK_DIR/_packages
# --  Folder for storing the source code from github
UPSTREAM_DIR=$WORK_DIR/_upstream

# -- Create the build directory
mkdir -p $BUILDS_DIR
# -- Create the packages directory
mkdir -p $PACKAGES_DIR
# -- Create the upstream directory and enter into it
mkdir -p $UPSTREAM_DIR

# -- Test script function
function test_bin {
  $WORK_DIR/test/test_bin.sh $1
  if [ $? != "0" ]; then
    exit 1
  fi
}

# -- Print function
function print {
  echo ""
  echo $1
  echo ""
}

# -- Check ARCH
if [[ $# > 1 ]]; then
  echo ""
  echo "Error: too many arguments"
  exit 1
fi

if [[ $# < 1 ]]; then
  echo ""
  echo "Usage: bash build.sh TARGET"
  echo ""
  echo "Targets: $TARGET_ARCHS"
  exit 1
fi

if [[ $ARCH =~ [[:space:]] || ! $TARGET_ARCHS =~ (^|[[:space:]])$ARCH([[:space:]]|$) ]]; then
  echo ""
  echo ">>> WRONG ARCHITECTURE \"$ARCH\""
  exit 1
fi

echo ""
echo ">>> ARCHITECTURE \"$ARCH\""
if [ $ARCH == "linux_x86_64" ]; then
  CROSS=$WORK_DIR/docker/bin/cross-linux-x64
  CROSS_PREFIX=/opt/x86_64-linux-gnu
fi
if [ $ARCH == "linux_i686" ]; then
  CROSS=$WORK_DIR/docker/bin/cross-linux-x86
  CROSS_PREFIX=/opt/i686-linux-gnu
fi
if [ $ARCH == "linux_armv7l" ]; then
  CROSS=$WORK_DIR/docker/bin/cross-linux-arm
  CROSS_PREFIX=/opt/arm-linux-gnueabihf
fi
if [ $ARCH == "linux_aarch64" ]; then
  CROSS=$WORK_DIR/docker/bin/cross-linux-arm64
  CROSS_PREFIX=/opt/aarch64-linux-gnu
fi
if [ $ARCH == "windows_x86" ]; then
  EXE=".exe"
  CROSS=$WORK_DIR/docker/bin/cross-windows-x86
  CROSS_PREFIX=/opt/i686-w64-mingw32
fi
if [ $ARCH == "windows_amd64" ]; then
  EXE=".exe"
  CROSS=$WORK_DIR/docker/bin/cross-windows-x64
  CROSS_PREFIX=/opt/x86_64-w64-mingw32
fi
if [ $ARCH == "darwin" ]; then
  CROSS=$WORK_DIR/docker/bin/cross-darwin-x64
  CROSS_PREFIX=/opt/x86_64-apple-darwin15
fi

# -- Directory for compiling the tools
BUILD_DIR=$BUILDS_DIR/build_$ARCH

# -- Directory for installation the target files
PACKAGE_DIR=$PACKAGES_DIR/build_$ARCH

# -- Create the build dir
mkdir -p $BUILD_DIR

# --------- Build system ------------------------------------------
if [ $BUILD_SYSTEM == "1" ]; then
  print ">> Compile system"
  # -- Toolchain name
  NAME=tools-system
  VERSION=1.2.0
  # -- Create the package folders
  mkdir -p $PACKAGE_DIR/$NAME/bin

  cd $PACKAGE_DIR/$NAME/bin
  $CROSS cp $CROSS_PREFIX/bin/lsusb lsusb$EXE
  $CROSS cp $CROSS_PREFIX/bin/lsftdi lsftdi$EXE
  test_bin lsusb$EXE
  test_bin lsftdi$EXE  
  cd $WORK_DIR

  print ">> Create system package"
  . $WORK_DIR/scripts/create_package.sh
fi

# --------- Build yosys ------------------------------------------
if [ $BUILD_YOSYS == "1" ]; then
  print ">> Compile yosys"
  # -- Toolchain name
  NAME=toolchain-yosys
  VERSION=$DATE_VERSION
  # -- Create the package folders
  mkdir -p $PACKAGE_DIR/$NAME/bin
  mkdir -p $PACKAGE_DIR/$NAME/share

  . $WORK_DIR/scripts/compile_yosys.sh

  print ">> Create yosys package"
  . $WORK_DIR/scripts/create_package.sh
fi

# --------- Build ice40 ------------------------------------------
if [ $BUILD_ICE40 == "1" ]; then
  print ">> Compile ice40"
  # -- Toolchain name
  NAME=toolchain-ice40
  VERSION=$DATE_VERSION
  # -- Create the package folders
  mkdir -p $PACKAGE_DIR/$NAME/bin
  mkdir -p $PACKAGE_DIR/$NAME/share

  . $WORK_DIR/scripts/compile_icestorm.sh

  . $WORK_DIR/scripts/compile_arachnepnr.sh

  print ">> Create ice40 package"
  . $WORK_DIR/scripts/create_package.sh
fi
