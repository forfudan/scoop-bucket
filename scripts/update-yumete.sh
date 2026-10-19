#!/usr/bin/env bash
# update-yumete.sh — point bucket/yumete.json at a release.
#
#   scripts/update-yumete.sh 0.11.0
#
# A release bump is four things — the version, the URL, the hash and
# `extract_dir` — and typing four things by hand is how one of them ends up
# belonging to the previous release. This reads the `.sha256` file the release
# publishes beside the zip, rewrites all four, and shows the diff.
# **It does not commit.**
#
# It then downloads the zip and hashes it itself, because the `.sha256` file is
# only what the release *says*. A manifest whose hash disagrees with the file
# fails at install time with a message about a hash mismatch and no hint about
# which of the two is wrong.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO="${YUMETE_REPO:-forfudan/yumete}"
VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "usage: scripts/update-yumete.sh <version>   e.g. 0.11.0" >&2
  exit 2
fi
MANIFEST="bucket/yumete.json"
NAME="yumete-${VERSION}-windows-x86_64.zip"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${NAME}"

echo "==> ${NAME}.sha256"
# The file holds `<sha>  <name>`; take the first field.
line="$(curl -fsSL --retry 3 "${URL}.sha256")" || {
  echo "!! could not fetch ${NAME}.sha256 — is the release published, and has the" >&2
  echo "   build finished? The release page is live minutes before its assets are." >&2
  exit 1
}
sum="${line%% *}"
if [[ ! "${sum}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "!! ${NAME}.sha256 does not hold a SHA-256: ${line}" >&2
  exit 1
fi

echo "==> ${NAME} (checking the zip really hashes to that)"
real="$(curl -fsSL --retry 3 "${URL}" | shasum -a 256 | awk '{print $1}')"
if [[ "${real}" != "${sum}" ]]; then
  echo "!! the zip hashes to ${real}" >&2
  echo "   but ${NAME}.sha256 says ${sum}" >&2
  exit 1
fi

jq --indent 4 \
  --arg v "${VERSION}" --arg u "${URL}" --arg h "${sum}" \
  --arg d "yumete-${VERSION}-windows-x86_64" '
    .version = $v
    | .architecture["64bit"].url = $u
    | .architecture["64bit"].hash = $h
    | .architecture["64bit"].extract_dir = $d
  ' "${MANIFEST}" > "${MANIFEST}.new"
mv "${MANIFEST}.new" "${MANIFEST}"

echo
git --no-pager diff -- "${MANIFEST}"
echo
echo "==> ${MANIFEST} now points at v${VERSION}. Check it, then:"
echo "      git commit -am 'Update yumete to v${VERSION}' && git push"
