# healthcheck.ps1 — プロジェクト健康診断スクリプト（PowerShell 版）
# 使い方: pwsh healthcheck.ps1 [対象パス]
# ※ 読み取り専用: ファイルの変更・削除は一切行いません

param(
    [string]$Target = "."
)

$Score = 0
$Total = 0

Write-Host "=== 🏥 プロジェクト健康診断レポート ==="
Write-Host "対象: $((Resolve-Path $Target).Path)"
Write-Host "実行日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm')"
Write-Host ""

# --- チェック項目 ---

# 1. README
$Total++
$readme = Get-ChildItem -Path $Target -Filter "README*" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($readme) {
    $lines = (Get-Content $readme.FullName | Measure-Object -Line).Lines
    Write-Host "✅ README — 存在する（$lines 行）"
    $Score++
} else {
    Write-Host "❌ README — 見つからない"
}

# 2. テストファイル
$Total++
$testFiles = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '(test|spec)' -and $_.FullName -notmatch '(node_modules|\.git)' }
$testCount = ($testFiles | Measure-Object).Count
if ($testCount -gt 0) {
    Write-Host "✅ テストファイル — $testCount 件見つかった"
    $Score++
} else {
    Write-Host "❌ テストファイル — 見つからない"
}

# 3. CI 設定
$Total++
$workflowDir = Join-Path $Target ".github/workflows"
if (Test-Path $workflowDir) {
    $ciCount = (Get-ChildItem -Path $workflowDir -Include "*.yml","*.yaml" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($ciCount -gt 0) {
        Write-Host "✅ CI 設定 — GitHub Actions ワークフロー $ciCount 件"
        $Score++
    } else {
        Write-Host "❌ CI 設定 — 見つからない"
    }
} elseif (Test-Path (Join-Path $Target ".gitlab-ci.yml")) {
    Write-Host "✅ CI 設定 — GitLab CI を検出"
    $Score++
} elseif (Test-Path (Join-Path $Target "Jenkinsfile")) {
    Write-Host "✅ CI 設定 — Jenkinsfile を検出"
    $Score++
} else {
    Write-Host "❌ CI 設定 — 見つからない"
}

# 4. lint / フォーマッター設定
$Total++
$lintFiles = @(".eslintrc", ".eslintrc.js", ".eslintrc.json", ".eslintrc.yml",
    ".prettierrc", ".prettierrc.json", "pyproject.toml", ".flake8",
    ".pylintrc", ".rubocop.yml", ".editorconfig", "biome.json")
$lintFound = $null
foreach ($f in $lintFiles) {
    if (Test-Path (Join-Path $Target $f)) {
        $lintFound = $f
        break
    }
}
if ($lintFound) {
    Write-Host "✅ lint/フォーマッター — $lintFound を検出"
    $Score++
} else {
    Write-Host "❌ lint/フォーマッター — 設定ファイルが見つからない"
}

# 5. LICENSE
$Total++
$license = Get-ChildItem -Path $Target -Filter "LICEN?E*" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($license) {
    $licenseType = (Get-Content $license.FullName -TotalCount 1) -join ""
    Write-Host "✅ LICENSE — 存在する（$licenseType）"
    $Score++
} else {
    Write-Host "❌ LICENSE — 見つからない"
}

# 6. .gitignore
$Total++
if (Test-Path (Join-Path $Target ".gitignore")) {
    $ignoreLines = (Get-Content (Join-Path $Target ".gitignore") |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
        Measure-Object).Count
    Write-Host "✅ .gitignore — 存在する（有効ルール $ignoreLines 件）"
    $Score++
} else {
    Write-Host "❌ .gitignore — 見つからない"
}

# --- スコア集計 ---
Write-Host ""
$Percent = [math]::Floor($Score * 100 / $Total)

$Grade = switch ($true) {
    ($Percent -ge 100) { "🏆 優良" }
    ($Percent -ge 80)  { "✅ 良好" }
    ($Percent -ge 50)  { "⚠️ 改善推奨" }
    default            { "🔴 要対応" }
}

Write-Host "📊 スコア: $Score/$Total（$Percent%）— $Grade"
Write-Host ""
Write-Host "=== レポート終了 ==="
