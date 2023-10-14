#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://codeberg.org/duxsco/unset/
unset current_stage3

function gpg_verify() {
    gpg_status="$(gpg --batch --status-fd 1 --verify "$1" "$2" 2>/dev/null)" && \
    grep -E -q "^\[GNUPG:\][[:space:]]+GOODSIG[[:space:]]+" <<< "${gpg_status}" && \
    grep -E -q "^\[GNUPG:\][[:space:]]+VALIDSIG[[:space:]]+" <<< "${gpg_status}" && \
    grep -E -q "^\[GNUPG:\][[:space:]]+TRUST_ULTIMATE[[:space:]]+" <<< "${gpg_status}"
}

pushd /mnt/gentoo || { echo 'Failed to move to directory "/mnt/gentoo"! Aborting...' >&2; exit 1; }

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME

# prepare gnupg
if  gpg --batch --locate-external-keys infrastructure@gentoo.org releng@gentoo.org >/dev/null 2>&1
then
    echo -e "13EBBDBEDE7A12775DFDB1BABB572E0E2D182910:6:\nDCD05B71EAB94199527F44ACDB6B8C1F96D8BF6D:6:" | \
        gpg --batch --import-ownertrust --quiet
else
    echo "Failed to fetch GnuPG public keys! Aborting..." >&2
    exit 1
fi

# fetch tarballs
if ! current_stage3="$(
        grep -Po "^[0-9]{8}T[0-9]{6}Z/[^[:space:]]+" < <(
            curl \
                --fail --silent --show-error --location \
                --proto '=https' --tlsv1.2 --ciphers 'AESGCM+ECDHE:CHACHA20+ECDHE' \
                "https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-systemd-mergedusr.txt"
        )
    )"
then
    echo "Failed to fetch stage3 tarball info! Aborting..." >&2
    exit 1
elif ! curl \
        --fail --silent --show-error --location \
        --proto '=https' --tlsv1.2 --ciphers 'AESGCM+ECDHE:CHACHA20+ECDHE' \
        --remote-name-all \
        "https://distfiles.gentoo.org/releases/amd64/autobuilds/${current_stage3}{,.asc}" \
        "https://distfiles.gentoo.org/snapshots/gentoo-latest.tar.xz{,.gpgsig}"
then
    echo "Failed to fetch files! Aborting..." >&2
    exit 1
fi

# gnupg verify
if  ! gpg_verify "${current_stage3##*/}.asc" "${current_stage3##*/}" || \
    ! gpg_verify gentoo-latest.tar.xz.gpgsig gentoo-latest.tar.xz
then
    echo "Failed to verify GnuPG signature! Aborting..." >&2
    exit 1
fi

gpgconf --kill all

popd || { echo 'Failed to move out of directory "/mnt/gentoo"! Aborting...' >&2; exit 1; }
