#!/bin/sh
set -efux

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

STAGE3_ID=amd64-openrc
STAGE3_BASE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-${STAGE3_ID}"
STAGE3_LATEST_FILE="latest-stage3-${STAGE3_ID}.txt"
WORKDIR="$PWD/chroot"

cleanup() {
  set +e
  umount -l "${WORKDIR}/dev" >/dev/null
  umount -l "${WORKDIR}/proc" >/dev/null
  umount -l "${WORKDIR}/run" >/dev/null
  umount -l "${WORKDIR}/sys" >/dev/null
  umount -l "${WORKDIR}/tmp" >/dev/null
  rm -rf "${WORKDIR}"
}
trap cleanup EXIT

export GNUPGHOME="$PWD/.gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
gpg --batch --import "$PWD/keys/gentoo-release.asc"

wget -nv "${STAGE3_BASE_URL}/${STAGE3_LATEST_FILE}" -O "${STAGE3_LATEST_FILE}"
gpgv --keyring pubring.kbx "${STAGE3_LATEST_FILE}"

stage3_file="$(grep -m1 -o "^stage3-${STAGE3_ID}.*\.tar\.xz" "${STAGE3_LATEST_FILE}")"
if [ -z "${stage3_file}" ]; then
  echo "Failed to resolve stage3 filename." >&2
  exit 1
fi

wget -nv "${STAGE3_BASE_URL}/${stage3_file}.sha256" -O "${stage3_file}.sha256"
gpgv --keyring pubring.kbx "${stage3_file}.sha256"
gpg --batch --decrypt "${stage3_file}.sha256" > "${stage3_file}.sha256.verified"

wget -nv "${STAGE3_BASE_URL}/${stage3_file}" -O "${stage3_file}"
sha256sum --check "${stage3_file}.sha256.verified"

wget -nv "${STAGE3_BASE_URL}/${stage3_file}.asc" -O "${stage3_file}.asc"
gpgv --keyring pubring.kbx "${stage3_file}.asc" "${stage3_file}"

mkdir -p "${WORKDIR}"
tar xpf "${stage3_file}" --xattrs-include='*.*' --numeric-owner -C "${WORKDIR}"

rsync -av ./data/ "${WORKDIR}/"

echo "repository = ${GITHUB_REPOSITORY}" > "${WORKDIR}/binrepo.conf"
unset GITHUB_REPOSITORY
echo "${GITHUB_TOKEN}" > "${WORKDIR}/binrepo.token"
unset GITHUB_TOKEN
chmod 0400 "${WORKDIR}/binrepo.token"

mount --rbind /dev "${WORKDIR}/dev"
mount --make-rslave "${WORKDIR}/dev"
mount -t proc /proc "${WORKDIR}/proc"
mount -t tmpfs -o mode=0755 tmpfs "${WORKDIR}/run"
mount --rbind /sys "${WORKDIR}/sys"
mount --make-rslave "${WORKDIR}/sys"
mount --rbind /tmp "${WORKDIR}/tmp"
cp -L /etc/resolv.conf "${WORKDIR}/etc/"

chroot "${WORKDIR}" /build.sh
