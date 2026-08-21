#!/bin/sh
set -efux

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

STAGE3_BASE_URL='https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc'
STAGE3_LATEST_FILE='latest-stage3-amd64-openrc.txt'
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

mkdir -p "${WORKDIR}"

curl -fsSL "${STAGE3_BASE_URL}/${STAGE3_LATEST_FILE}" -o latest-stage3.txt
stage3_file="$(grep -m1 -o '^stage3-amd64-openrc.*\.tar\.xz' latest-stage3.txt)"
if [ -z "${stage3_file}" ]; then
  echo "Failed to resolve stage3 filename." >&2
  exit 1
fi

curl -fSL "${STAGE3_BASE_URL}/${stage3_file}" -o stage3.tar.xz

tar xpf stage3.tar.xz --xattrs-include='*.*' --numeric-owner -C "${WORKDIR}"

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
