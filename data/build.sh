#!/bin/sh
set -efux

set +u
# shellcheck disable=SC1091
. /etc/profile
set -u

emerge-webrsync --quiet
emerge --oneshot dev-vcs/git

mkdir -p /etc/portage/repos.conf
printf '[gentoo]\nlocation = /var/db/repos/gentoo\nsync-type = git\nsync-uri = https://github.com/gentoo-mirror/gentoo\nsync-git-verify-commit-signature = true\n' > /etc/portage/repos.conf/gentoo.conf
printf '[rookery]\nlocation = /var/db/repos/rookery\nsync-type = git\nsync-uri = https://github.com/KSmanis/rookery\n' > /etc/portage/repos.conf/rookery.conf
rm -rf /var/db/repos/gentoo/
emaint sync

emerge --oneshot sys-apps/portage
# v0.8.0 introduces --unreachable flag
emerge --oneshot '>=app-portage/gentoolkit-0.8.0'
ACCEPT_KEYWORDS="**" emerge --oneshot app-portage/portage-github-binrepo
echo 'source /usr/share/portage-github-binrepo/portage-github-binrepo.bashrc' > /etc/portage/bashrc
mv /binrepo.conf /etc/portage/github-binrepo.conf
mv /binrepo.token /etc/portage/github-binrepo.token

portage-github-binrepo pull
emerge --info
emerge -uDU --onlydeps --onlydeps-with-rdeps=n @world
emerge -uDU --buildpkgonly @world
eclean packages --unreachable
portage-github-binrepo push
