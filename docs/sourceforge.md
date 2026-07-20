# SourceForge Mirror

SourceForge is a secondary mirror for Paste-vlv release files. GitHub Releases
remain the primary release source.

Project:

- Admin: `https://sourceforge.net/p/paste-vlv/admin/`
- Public project: `https://sourceforge.net/projects/paste-vlv/`
- Release files: `https://sourceforge.net/projects/paste-vlv/files/v1.0.0/`

## What SourceForge Needs

Paste-vlv uses `paste-vlv` as the SourceForge project URL name. SourceForge uses
that value as `PROJECTNAME` in file paths.

SourceForge file releases can be managed through the web File Manager or through
SFTP, SCP, and rsync. Release files live under:

```text
/home/frs/project/paste-vlv/
```

## Prepare Local Files

```sh
./scripts/prepare-sourceforge-release.sh 1.0.0
```

This creates:

```text
dist/sourceforge/v1.0.0/Paste-vlv-1.0.0-macos-unsigned.zip
dist/sourceforge/v1.0.0/Paste-vlv-1.0.0-macos-unsigned.zip.sha256
dist/sourceforge/v1.0.0/readme.md
```

The `readme.md` file appears as release notes in the SourceForge file browser.

## Upload With SourceForge Web

1. Open the SourceForge project.
2. Go to Files.
3. Add folder `v1.0.0`.
4. Upload:
   - `dist/sourceforge/v1.0.0/Paste-vlv-1.0.0-macos-unsigned.zip`
   - `dist/sourceforge/v1.0.0/Paste-vlv-1.0.0-macos-unsigned.zip.sha256`
   - `dist/sourceforge/v1.0.0/readme.md`
5. Mark the ZIP as the default macOS download if SourceForge asks.

## Upload With SSH

If SSH is configured for SourceForge:

```sh
./scripts/publish-sourceforge.sh SOURCEFORGE_USERNAME
```

Example:

```sh
./scripts/publish-sourceforge.sh vlv
```

The script uploads to:

```text
/home/frs/project/paste-vlv/v1.0.0/
```

After upload, the public folder should be:

```text
https://sourceforge.net/projects/paste-vlv/files/v1.0.0/
```

Direct ZIP download:

```text
https://sourceforge.net/projects/paste-vlv/files/v1.0.0/Paste-vlv-1.0.0-macos-unsigned.zip/download
```

## Signing Status

Current `v1.0.0` files are ad-hoc signed, not Developer ID signed, and not
notarized. SourceForge is only a mirror; it does not change Gatekeeper behavior.
