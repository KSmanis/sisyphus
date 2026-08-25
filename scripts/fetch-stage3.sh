#!/bin/sh
set -efux

: "${STAGE3_FILE:?STAGE3_FILE is required}"

# shellcheck disable=SC1091
. "$PWD/stage3.conf"

export GNUPGHOME="$PWD/.gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
gpg --batch --import "$PWD/keys/gentoo-release.asc"

wget -nv "${STAGE3_BASE_URL}/${STAGE3_FILE}.sha256" -O "${STAGE3_FILE}.sha256"
gpgv --keyring pubring.kbx "${STAGE3_FILE}.sha256"
gpg --batch --decrypt "${STAGE3_FILE}.sha256" > "${STAGE3_FILE}.sha256.verified"

wget -nv "${STAGE3_BASE_URL}/${STAGE3_FILE}" -O "${STAGE3_FILE}"
sha256sum --check "${STAGE3_FILE}.sha256.verified"

wget -nv "${STAGE3_BASE_URL}/${STAGE3_FILE}.asc" -O "${STAGE3_FILE}.asc"
gpgv --keyring pubring.kbx "${STAGE3_FILE}.asc" "${STAGE3_FILE}"
