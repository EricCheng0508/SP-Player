# Stage the repo at a short path so flutter build windows (MSBuild) does not
# overflow MAX_PATH (260 chars). Self-hosted runners often check out under
# C:\Users\me\.gh-sr\runners\<host>\_work\<org>\<repo>\, which is 76 chars
# alone — once MSBuild appends plugin .tlog paths (e.g.
# build\windows\x64\plugins\flutter_inappwebview_windows\x64\Release\
# flutter_inappwebview_windows_DEPENDENCIES_DOWNLOAD\...\.tlog\) the
# final path is ~270 chars, producing MSB3491 ("could not find part of the
# path"). NTFS junctions and subst both fail: MSBuild resolves them to the
# underlying long path before writing tlog state.
#
# Mirror the project to C:\e\<repo> with robocopy /MIR (skips .git,
# .dart_tool, build/, etc.), then point GITHUB_WORKSPACE at the short
# copy. flutter/cmake/MSBuild all see the project at the short path, so
# the entire build tree — including tlog output — fits under MAX_PATH.
# After the build, only the artifacts (build/windows/.../Release, the
# .exe, the Inno Setup installer) are needed; the rest of the short-path
# copy is cleaned up.
#
# Note: github.workspace (Actions context) stays at the original checkout
# with .git. Steps that need git (e.g. `gh release create --generate-notes`)
# must use working-directory: ${{ github.workspace }} and read build
# outputs from $env:BUILD_WS (the short path).
#
# IMPORTANT: the short path is exported as BUILD_WS, NOT by overwriting
# GITHUB_WORKSPACE via GITHUB_ENV. GITHUB_WORKSPACE is a runner-reserved
# default: it is re-injected (original long path) into every step's process
# env AFTER GITHUB_ENV is applied, so overwriting it silently reverts and
# any `$env:GITHUB_WORKSPACE` in a run script sees the long path again
# while the env-context `{{ env.GITHUB_WORKSPACE }}` seen in step headers
# shows the short one. Reference the short path through BUILD_WS in run
# scripts, and through `working-directory: ${{ env.BUILD_WS }}` for cwd.
$ErrorActionPreference = 'Stop'

$shortRoot = 'C:\e'
$workspace = $env:GITHUB_WORKSPACE
if (-not $workspace) {
  throw 'GITHUB_WORKSPACE is not set'
}
$workspace = (Resolve-Path -LiteralPath $workspace).Path
$baseName = Split-Path -Leaf $workspace
$shortPath = Join-Path $shortRoot $baseName

if (-not (Test-Path $shortRoot)) {
  New-Item -Path $shortRoot -ItemType Directory -Force | Out-Null
}
if (Test-Path $shortPath) {
  Remove-Item -Path $shortPath -Recurse -Force -ErrorAction SilentlyContinue
}

# /MIR mirrors the tree; /XD skips heavy/regenerable dirs.
# robocopy exit codes 0-7 are success (8+ are real failures).
# In PowerShell, $LASTEXITCODE (not the assignment expression) holds the
# native exit code, so capture explicitly.
robocopy $workspace $shortPath /MIR `
  /XD '.git' '.dart_tool' 'build' '.idea' '.vs' 'windows\ffmpeg' `
  /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) {
  throw "robocopy $workspace -> $shortPath failed with exit code $LASTEXITCODE"
}

"BUILD_WS=$shortPath" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
Write-Host "Staged $workspace -> $shortPath"
exit 0
