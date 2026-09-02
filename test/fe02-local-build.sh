#!/bin/bash
set -e

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --desktop   Desktop environment: kde, gnome, cosmic (default: kde)"
    echo "  -g, --gaming    Enable gaming packages (default: false)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --desktop cosmic"
    echo "  $0 --desktop kde --gaming"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../ENVAR"

DESKTOP_ENV="kde"
GAMING="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--desktop)
            DESKTOP_ENV="$2"
            shift 2
            ;;
        -g|--gaming)
            GAMING="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            usage
            exit 1
            ;;
    esac
done

case "$DESKTOP_ENV" in
    kde)    BASE_IMAGE="quay.io/fedora-ostree-desktops/kinoite" ;;
    gnome)  BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue" ;;
    cosmic) BASE_IMAGE="quay.io/fedora-ostree-desktops/cosmic-atomic" ;;
    *)
        echo "Error: Unknown desktop environment '$DESKTOP_ENV'. Must be one of: kde, gnome, cosmic"
        exit 1
        ;;
esac

if [[ "$GAMING" == "true" ]]; then
    TAG="fe02-os:${DESKTOP_ENV}-gaming"
else
    TAG="fe02-os:${DESKTOP_ENV}"
fi

echo "Building Fe02-OS locally..."
echo "  Desktop    : $DESKTOP_ENV"
echo "  Base Image : $BASE_IMAGE"
echo "  Gaming     : $GAMING"
echo "  Tag        : $TAG"
echo ""

podman build \
  --build-arg FEDORA_MAJOR_VERSION="$MAJOR_VERSION" \
  --build-arg BASE_IMAGE_NAME="$BASE_IMAGE" \
  --build-arg DESKTOP_ENV="$DESKTOP_ENV" \
  --build-arg GAMING="$GAMING" \
  -t "$TAG" .

echo "Build completed successfully! Image tagged as: $TAG"
