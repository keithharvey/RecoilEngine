#!/bin/bash

set -e -u -o pipefail

# Platform detection and configuration
# Default to linux/amd64 for Apple Silicon compatibility, but allow override
if [[ -z "${DOCKER_PLATFORM:-}" ]]; then
  # Check if we're on Apple Silicon (arm64)
  if [[ "$(uname -m)" == "arm64" ]]; then
    DOCKER_PLATFORM="linux/amd64"
  else
    DOCKER_PLATFORM=""
  fi
fi

# Build platform flag for docker commands
DOCKER_PLATFORM_FLAG=""
if [[ -n "$DOCKER_PLATFORM" ]]; then
  DOCKER_PLATFORM_FLAG="--platform $DOCKER_PLATFORM"
fi

if [[ $(id -u) -eq 0 ]]; then
  echo "You are trying to run build.sh as root, that won't work!"
  echo ""
  echo "If you get permission errors when running docker, check if you've finished the"
  echo "post installation steps and are member of \`docker\` system group."
  echo "See official docs: https://docs.docker.com/engine/install/linux-postinstall/"
fi

USAGE="Usage: $0 [--help] [--configure|--compile] [-j|--jobs {number_of_jobs}] [--docker-platform {platform}] {windows|linux} [cmake_flag...]"
export CONFIGURE=true
export COMPILE=true
export CMAKE_BUILD_PARALLEL_LEVEL=
OS=
while (( $# > 0 )); do
  case $1 in
    --configure)
      CONFIGURE=true
      COMPILE=false
      shift
      ;;
    --compile)
      CONFIGURE=false
      COMPILE=true
      shift
      ;;
    --help)
      echo $USAGE
      echo "Options:"
      echo "  --help       print this help message"
      echo "  --configure  only configure, don't compile"
      echo "  --compile    only compile, don't configure"
      echo "  -j, --jobs   number of concurrent processes to use when building"
      echo "  --docker-platform  Docker platform to use (e.g., linux/amd64, linux/arm64)"
      echo ""
      echo "Environment variables:"
      echo "  DOCKER_PLATFORM  Docker platform to use (e.g., linux/amd64 for Apple Silicon)"
      exit 0
      ;;
    --docker-platform)
      shift
      if [[ -z "${1-}" ]]; then
        echo "Error: --docker-platform requires a platform value"
        echo $USAGE
        exit 1
      fi
      DOCKER_PLATFORM="$1"
      DOCKER_PLATFORM_FLAG="--platform $DOCKER_PLATFORM"
      shift
      ;;
    -j|--jobs)
      shift
      # Match numeric, starting with non-zero digit
      if ! [[ "${1-}" =~ ^[1-9]+[0-9]*$ ]]; then
        echo $USAGE
        exit 1
      fi
      CMAKE_BUILD_PARALLEL_LEVEL="$1"
      shift
      ;;
    windows|linux)
      OS="$1"
      shift
      break
      ;;
    *)
      break
  esac
done
if [[ -z $OS ]]; then
  echo $USAGE
  exit 1
fi

cd "$(dirname "$(readlink -f "$0")")/.."
mkdir -p build-$OS .cache/ccache-$OS

# Use locally build image if available, and pull from upstream if not
image=recoil-build-amd64-$OS:latest
if [[ -z "$(docker images -q $image 2> /dev/null)" ]]; then
  image=ghcr.io/beyond-all-reason/recoil-build-amd64-$OS:latest
  docker pull $DOCKER_PLATFORM_FLAG $image
fi

docker run -it --rm $DOCKER_PLATFORM_FLAG \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    --user=$(id -u):$(id -g) \
    -v $(pwd):/build/src:ro \
    -v $(pwd)/.cache/ccache-$OS:/build/cache:rw \
    -v $(pwd)/build-$OS:/build/out:rw \
    -e CONFIGURE \
    -e COMPILE \
    -e CMAKE_BUILD_PARALLEL_LEVEL \
    $image \
    bash -c '
set -e
echo "$@"
cd /build/src/docker-build-v2/scripts
$CONFIGURE && ./configure.sh "$@"
if $COMPILE; then
  ./compile.sh
  # When compiling for windows, we must strip debug info because windows does
  # not handle the output binary size...
  if [[ $ENGINE_PLATFORM =~ .*windows ]]; then
    ./split-debug-info.sh
  fi
fi
' -- "$@"
