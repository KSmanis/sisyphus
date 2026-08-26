#!/bin/sh
set -efu

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

echo "repository = ${GITHUB_REPOSITORY}" > /etc/portage/github-binrepo.conf
echo "${GITHUB_TOKEN}" > /etc/portage/github-binrepo.token

set -x
emaint sync
portage-github-binrepo pull
emerge --info
emerge -uDU --changed-deps --onlydeps --onlydeps-with-rdeps=n @world
emerge -uDU --changed-deps --buildpkgonly @world
eclean packages --unreachable
portage-github-binrepo push
