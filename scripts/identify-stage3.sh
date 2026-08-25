#!/bin/sh
set -efux

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

# shellcheck disable=SC1091
. "$PWD/stage3.conf"
STAGE3_LATEST_FILE="latest-stage3-${STAGE3_ID}.txt"

export GNUPGHOME="$PWD/.gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
gpg --batch --import "$PWD/keys/gentoo-release.asc"

wget -nv "${STAGE3_BASE_URL}/${STAGE3_LATEST_FILE}" -O "${STAGE3_LATEST_FILE}"
gpgv --keyring pubring.kbx "${STAGE3_LATEST_FILE}"

file="$(grep -m1 -o "^stage3-${STAGE3_ID}.*\.tar\.xz" "${STAGE3_LATEST_FILE}")"
if [ -z "${file}" ]; then
  echo "Failed to resolve stage3 filename." >&2
  exit 1
fi

echo "file=${file}" >> "${GITHUB_OUTPUT}"
