# scoop-bucket

[Scoop](https://scoop.sh) bucket for [forfudan](https://github.com/forfudan)
command-line tools on Windows — the counterpart of
[homebrew-tap](https://github.com/forfudan/homebrew-tap), which does the same
job on macOS and Linux.

Currently published:

- [`yumete`](https://github.com/forfudan/yumete) — CJK-aware terminal editor for Chinese prose, with the Yume IME built in

## Install

```powershell
scoop bucket add forfudan https://github.com/forfudan/scoop-bucket
scoop install yumete
```

`yumete` installs under both its names — `yumete`, and `ye` for the one you
actually type. They are two shims onto one `yumete.exe`, so they cannot come
to differ.

## Verify

```powershell
yumete --version
ye --shot=40x6 some-file.md
```

`--shot` draws one frame and exits, so it says whether the editor can render
without opening it.

## Upgrade

```powershell
scoop update
scoop update yumete
```

## Uninstall

```powershell
scoop uninstall yumete
scoop bucket rm forfudan
```

## Supported platforms

Windows x86_64 only. The release builds no arm64 Windows binary; when one
exists, the manifest grows an `arm64` block rather than pretending the x86_64
zip will do.

The editor types 漢字 with nothing else installed — every binary carries
靈明 精華版, a cut covering CJK 基本區 and 擴展A. Words, the language model
behind fluency mode, and the 拆分 annotations come from the Yume data layer,
which travels separately: install the Yume input method, or point
`$env:YUMETE_DATA_DIR` at a data directory. A machine that already runs Yume
needs nothing — yumete finds those tables where the app put them.

## Maintaining

A release bump is four things — the version, the URL, the hash and
`extract_dir`. The script rewrites all four from the `.sha256` the release
publishes beside the zip, then shows the diff without committing:

```bash
scripts/update-yumete.sh 0.11.0
```

It refuses to write unless the checksum is 64 hex digits, and then downloads
the zip and hashes it itself — the `.sha256` file is only what the release
*says*, and a manifest whose hash disagrees with the file fails at install
time with a message about a mismatch and no hint about which of the two is
wrong.

The release has to carry the zip first. The release page is live from the
moment it is published and the assets arrive minutes later, so check that the
zip is really there rather than assuming it.

The manifest also carries `checkver` and `autoupdate`, which is what
[Excavator](https://github.com/ScoopInstaller/Excavator) and
`scoop-update` read. Nothing runs them for this bucket yet; the script above
is the supported path.

### Never rewrite a pushed commit here

No `--amend` after pushing, no force-push, no rebase of `main`.

Scoop keeps its own clone of this bucket, separate from any working copy you
have, under `~\scoop\buckets\forfudan`, and `scoop update` pulls into it. A
clone that fetched a commit before it was rewritten is asked to merge two
histories that no longer share a tip. On the Homebrew tap that left conflict
markers sitting in a formula for four months before anyone upgraded and
noticed; here it would leave them in a JSON manifest, where the error reads as
a broken manifest rather than a broken checkout.

To repair such a clone — it is a mirror, so nothing is lost:

```powershell
git -C "$env:USERPROFILE\scoop\buckets\forfudan" reset --hard origin/main
```

## License

Apache-2.0 (matches the upstream tools).
