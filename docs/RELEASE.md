# How to release a new version (2 steps)

## Step 1 — On your PC: upload your work
1. Open `pubspec.yaml`, change `version:` to the new version (example: `1.0.5-beta`). Save.
2. Open PowerShell in the project folder and run:
   `.\scripts\release.ps1 -Version 1.0.5-beta -Message "what changed"`
3. Open the link it prints and press **Merge** on GitHub.

## Step 2 — On GitHub: press one button
1. Open your repository → **Actions** tab → **Release Windows build**.
2. Press **Run workflow**, type the same version (`1.0.5-beta`), press **Run**. Leave release notes empty — the "what's new" text is written automatically from your recent changes. (Or type your own text to use that instead.)
3. Wait a few minutes. When it finishes green, the new version is published under **Releases**, ready to download.

## The update file (so the app finds the new version)
- If you added the `UPDATER_REPO_TOKEN` secret (one time, in repository Settings → Secrets): nothing to do, the file updates itself.
- If not: after the run, copy the ready-made text from the run summary into `update_manifest.txt` in your `sahibz-updater` repository.

## If the run turns red
Click the failed run, open the red step, read the error. Common causes:
- Version typed in the button does not match `pubspec.yaml` → fix and re-run.
- `Analyze` step failed → fix the code error it names, merge, re-run.
