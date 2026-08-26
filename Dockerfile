FROM ghcr.io/ksmanis/stage3:20260824@sha256:7eac94c2d143dbc44bbf6f618e28491b587339e5e752368ec54a3011f870c0ec

COPY data/ /

RUN --mount=type=bind,from=ghcr.io/ksmanis/portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo \
    emerge --oneshot dev-vcs/git

RUN set -eux; \
    mkdir -p /etc/portage/repos.conf; \
    printf '[gentoo]\nlocation = /var/db/repos/gentoo\nsync-type = git\nsync-uri = https://github.com/gentoo-mirror/gentoo\nsync-git-verify-commit-signature = true\n' > /etc/portage/repos.conf/gentoo.conf; \
    printf '[rookery]\nlocation = /var/db/repos/rookery\nsync-type = git\nsync-uri = https://github.com/KSmanis/rookery\n' > /etc/portage/repos.conf/rookery.conf; \
    emaint sync; \
    emerge --oneshot sys-apps/portage; \
    emerge --oneshot app-portage/gentoolkit

# renovate: datasource=github-releases depName=KSmanis/portage-github-binrepo
ARG PORTAGE_GITHUB_BINREPO_VERSION=2.0.3
RUN set -eux; \
    ACCEPT_KEYWORDS="**" emerge --oneshot "=app-portage/portage-github-binrepo-${PORTAGE_GITHUB_BINREPO_VERSION}"; \
    echo 'source /usr/share/portage-github-binrepo/portage-github-binrepo.bashrc' > /etc/portage/bashrc

ENTRYPOINT ["/build.sh"]
