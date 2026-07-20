# SourceForge Mirror

SourceForge is a secondary mirror for Paste-vlv release files. GitHub Releases
remain the primary release source.

## What SourceForge Needs

Create a SourceForge project first and note its project URL name. SourceForge
uses that value as `PROJECTNAME` in file paths.

SourceForge file releases can be managed through the web File Manager or through
SFTP, SCP, and rsync. Release files live under:

```text
/home/frs/project/PROJECTNAME/
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
./scripts/publish-sourceforge.sh SOURCEFORGE_USERNAME SOURCEFORGE_PROJECT
```

Example:

```sh
./scripts/publish-sourceforge.sh vlv paste-vlv
```

The script uploads to:

```text
/home/frs/project/SOURCEFORGE_PROJECT/v1.0.0/
```

## Signing Status

Current `v1.0.0` files are ad-hoc signed, not Developer ID signed, and not
notarized. SourceForge is only a mirror; it does not change Gatekeeper behavior.
