#!/bin/sh
set -efux

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${STAGE3_FILE:?STAGE3_FILE is required}"

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
tar xpf "${STAGE3_FILE}" --xattrs-include='*.*' --numeric-owner -C "${WORKDIR}"

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
