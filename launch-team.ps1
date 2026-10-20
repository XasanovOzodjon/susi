# Claude Code team grid launcher for Windows Terminal. See REGLAMENT section 10.
# Lives in <project>\.team\ next to team.conf, roles\, bus.sh.
#   $env:TEAM_DRYRUN='1'; .\launch-team.ps1   -> print wt arguments, change nothing
#   .\launch-team.ps1                         -> create worktrees, open all panes
# Env: PROJECT (default: parent of .team), BUS_DIR (default C:\bus), MODEL (default claude-opus-5-5).
#
# ASCII-only on purpose: Windows PowerShell 5.1 reads a .ps1 without BOM as cp1251,
# and Cyrillic in the code breaks parsing. Cyrillic paths are fine as DATA (taken from disk).

$ErrorActionPreference = 'Stop'
$team    = $PSScriptRoot
$project = if ($env:PROJECT) { $env:PROJECT } else { Split-Path $team -Parent }
$wtRoot  = Join-Path (Split-Path $project -Parent) ((Split-Path $project -Leaf) + '-wt')
$bus     = if ($env:BUS_DIR) { $env:BUS_DIR } else { 'C:\bus' }
$model   = if ($env:MODEL) { $env:MODEL } else { 'claude-opus-5-5' }
$dry     = $env:TEAM_DRYRUN -eq '1'

function ToBash([string]$p) {   # C:\x\y -> /c/x/y (bus.sh runs in Git Bash)
    if ($p -match '^([A-Za-z]):\\(.*)$') { return '/' + $Matches[1].ToLower() + '/' + ($Matches[2] -replace '\\', '/') }
    return $p -replace '\\', '/'
}

if (-not (Get-Command claude -EA SilentlyContinue)) { throw 'claude not found in PATH' }
$wtExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (-not (Test-Path $wtExe)) { throw 'Windows Terminal (wt.exe) not found' }
git -C $project rev-parse --git-dir | Out-Null
if ($LASTEXITCODE -ne 0) { throw "$project is not a git repository" }

# Bus folders (same layout as bus.sh init).
foreach ($d in 'inbox', 'outbox', 'presence', 'cursor', 'handoffs') { New-Item -ItemType Directory -Force (Join-Path $bus $d) | Out-Null }
New-Item -ItemType Directory -Force (Join-Path $team 'sessions') | Out-Null

$roles = Get-Content (Join-Path $team 'team.conf') -Encoding UTF8 |
    Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() } |
    ForEach-Object { $f = -split $_; [pscustomobject]@{ Name = $f[0]; Tree = $f[1]; Tg = $f[2] } }

$panes = @()
foreach ($r in $roles) {
    foreach ($box in 'inbox', 'outbox') { $f = Join-Path $bus "$box\$($r.Name).md"; if (-not (Test-Path $f)) { New-Item -ItemType File $f | Out-Null } }

    # 1. Role folder: main tree or own worktree on branch w/<role>/main.
    if ($r.Tree -eq 'main') { $dir = $project } else {
        $dir = Join-Path $wtRoot $r.Name
        if (-not (Test-Path $dir)) {
            try { git -C $project fetch -q origin 2>$null } catch { }   # no remote yet is fine (PS 5.1 throws on stderr)
            $base = $null; try { $base = git -C $project rev-parse --verify -q origin/main } catch { }
            if (-not $base) { $base = git -C $project rev-parse HEAD }
            git -C $project rev-parse --verify -q "w/$($r.Name)/main" | Out-Null
            if ($LASTEXITCODE -eq 0) { $a = @('worktree', 'add', $dir, "w/$($r.Name)/main") }
            else { $a = @('worktree', 'add', '-b', "w/$($r.Name)/main", $dir, $base) }
            if ($dry) { "+ git $a" } else { git -C $project @a }
        }
    }

    # 2. Stable session id: first run --session-id, later --resume (history survives reboot).
    $idf = Join-Path $team "sessions\$($r.Name).id"
    if (Test-Path $idf) { $sess = '--resume ' + (Get-Content $idf).Trim() }
    else { $id = [guid]::NewGuid().ToString(); if (-not $dry) { Set-Content $idf $id -Encoding ASCII }; $sess = "--session-id $id" }

    # 3. Role prompt with absolute paths (worktrees have no .team folder). Written as UTF-8 via .NET.
    $p = [IO.File]::ReadAllText((Join-Path $team "roles\$($r.Name).md"), [Text.Encoding]::UTF8)
    $p = $p.Replace('{{bus}}', "BUS_DIR='$(ToBash $bus)' '$(ToBash $team)/bus.sh'").Replace('{{team}}', $team).Replace('{{busdir}}', $bus)
    $pf = Join-Path $team "sessions\$($r.Name).prompt.md"
    if (-not $dry) { [IO.File]::WriteAllText($pf, $p, (New-Object Text.UTF8Encoding $false)) }

    # 4. Telegram channel only for the role with tg=yes (one bot = one consumer).
    $ch = if ($r.Tg -eq 'yes') { ' --channels plugin:telegram@claude-plugins-official' } else { '' }
    # Folder goes through wt -d, not "cd" inside cmd: Cyrillic paths in cmd /k can fail silently.
    # No ';' inside a pane command: wt treats ';' as its own command separator.
    $panes += '--title "{0}" -d "{1}" cmd /k claude {2} --name {0} --model {3}{4} --append-system-prompt-file "{5}"' -f $r.Name, $dir, $sess, $model, $ch, $pf
}

# Layout: two rows. Top row = first ceil(n/2) roles left to right, bottom row = the rest.
$n = $panes.Count; $cols = [math]::Ceiling($n / 2)
$parts = @('--maximized new-tab ' + $panes[0])   # 6 panes need the whole screen
for ($c = 1; $c -lt $cols; $c++) {
    # wt keeps focus on the pane it split, not the new one: focus the last column explicitly,
    # otherwise the first column gets split again (seen live: two narrow + one wide column).
    if ($c -gt 1) { $parts += "focus-pane -t $($c - 1)" }
    $size = [math]::Round(($cols - $c) / ($cols - $c + 1), 4)   # new pane takes its fair share of the rest
    $parts += ('split-pane -V -s {0} ' -f $size.ToString([Globalization.CultureInfo]::InvariantCulture)) + $panes[$c]
}
for ($c = 0; $c -lt ($n - $cols); $c++) {
    $parts += "focus-pane -t $c"
    $parts += 'split-pane -H -s 0.5 ' + $panes[$cols + $c]
}
$wtArgs = $parts -join ' ; '

if ($dry) { 'PROJECT = ' + $project; 'WT ARGS:'; $parts; return }
Start-Process -FilePath $wtExe -ArgumentList $wtArgs
