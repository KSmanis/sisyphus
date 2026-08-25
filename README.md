# Sisyphus

The personalized, GitHub-hosted Gentoo binhost.

Sisyphus is a Gentoo binhost running on GitHub infrastructure. It runs on a loop
until all `@world` updates have been emerged, then rests. By default it runs
every hour or when the `main` branch is updated. Only one instance may run at
any time: newer runs cancel older runs.

It works by bootstrapping a minimal, but configurable, Gentoo chroot that
publishes binpkgs as they are built, using
[portage-github-binrepo](https://github.com/KSmanis/portage-github-binrepo).

## Usage

1. Fork this repository.
2. Customize the chroot seed directory [`data/`](data/) for your systems, e.g.,
   your Portage configuration.

As an example, this repo adds `app-misc/hello` to the world set.

If configuration alone is insufficient, adjust [`data/build.sh`](data/build.sh).
Modify [`scripts/chroot.sh`](scripts/chroot.sh) only when the stage3 or chroot
setup must change.

No additional secret is required. The workflow publishes to its own repository
with the built-in `GITHUB_TOKEN`.

## Use the binhost

For a public fork, create `/etc/portage/binrepos.conf/github.conf` on each
Gentoo system:

```ini
[github]
priority = 1
sync-uri = https://raw.githubusercontent.com/OWNER/REPOSITORY/binrepo
verify-signature = false
```

Replace `OWNER/REPOSITORY` with your fork. The packages are currently unsigned,
so signature verification must remain disabled.

Private forks require authenticated downloads. Follow the
[`portage-github-binrepo` consumer instructions](https://github.com/KSmanis/portage-github-binrepo#consumer-machines)
to configure a read-only token.

## Responsible use

You are responsible for ensuring that every package in your binhost may be
redistributed and for meeting its license obligations, including source-code
requirements where applicable.

Keep builds, API requests, storage, and downloads proportionate to your project.
Use of this repository remains subject to GitHub's
[Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service),
[Acceptable Use Policies](https://docs.github.com/en/site-policy/acceptable-use-policies/github-acceptable-use-policies),
and
[additional terms for GitHub Actions](https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features).
