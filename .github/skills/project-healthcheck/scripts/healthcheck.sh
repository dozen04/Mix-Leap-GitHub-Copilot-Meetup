#!/bin/bash
# healthcheck.sh — プロジェクト健康診断スクリプト
# 使い方: bash healthcheck.sh [対象パス]
# ※ 読み取り専用: ファイルの変更・削除は一切行いません

TARGET="${1:-.}"
SCORE=0
TOTAL=0

echo "=== 🏥 プロジェクト健康診断レポート ==="
echo "対象: $(cd "$TARGET" && pwd)"
echo "実行日時: $(date '+%Y/%m/%d %H:%M')"
echo ""

# --- チェック項目 ---

# 1. README
TOTAL=$((TOTAL + 1))
if [ -f "$TARGET/README.md" ] || [ -f "$TARGET/readme.md" ] || [ -f "$TARGET/README" ]; then
  LINES=$(wc -l < "$TARGET/README.md" 2>/dev/null || wc -l < "$TARGET/readme.md" 2>/dev/null || echo "0")
  LINES=$(echo "$LINES" | tr -d ' ')
  echo "✅ README — 存在する（${LINES} 行）"
  SCORE=$((SCORE + 1))
else
  echo "❌ README — 見つからない"
fi

# 2. テストファイル
TOTAL=$((TOTAL + 1))
TEST_COUNT=$(find "$TARGET" -type f \( -name "*test*" -o -name "*spec*" -o -name "*Test*" -o -name "*Spec*" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TEST_COUNT" -gt 0 ]; then
  echo "✅ テストファイル — ${TEST_COUNT} 件見つかった"
  SCORE=$((SCORE + 1))
else
  echo "❌ テストファイル — 見つからない"
fi

# 3. CI 設定
TOTAL=$((TOTAL + 1))
if [ -d "$TARGET/.github/workflows" ] && [ "$(find "$TARGET/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
  CI_COUNT=$(find "$TARGET/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
  echo "✅ CI 設定 — GitHub Actions ワークフロー ${CI_COUNT} 件"
  SCORE=$((SCORE + 1))
elif [ -f "$TARGET/.gitlab-ci.yml" ]; then
  echo "✅ CI 設定 — GitLab CI を検出"
  SCORE=$((SCORE + 1))
elif [ -f "$TARGET/Jenkinsfile" ]; then
  echo "✅ CI 設定 — Jenkinsfile を検出"
  SCORE=$((SCORE + 1))
else
  echo "❌ CI 設定 — 見つからない"
fi

# 4. lint / フォーマッター設定
TOTAL=$((TOTAL + 1))
LINT_FOUND=""
for f in .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml .prettierrc .prettierrc.json \
         pyproject.toml .flake8 .pylintrc .rubocop.yml .editorconfig biome.json; do
  if [ -f "$TARGET/$f" ]; then
    LINT_FOUND="$f"
    break
  fi
done
if [ -n "$LINT_FOUND" ]; then
  echo "✅ lint/フォーマッター — ${LINT_FOUND} を検出"
  SCORE=$((SCORE + 1))
else
  echo "❌ lint/フォーマッター — 設定ファイルが見つからない"
fi

# 5. LICENSE
TOTAL=$((TOTAL + 1))
if [ -f "$TARGET/LICENSE" ] || [ -f "$TARGET/LICENSE.md" ] || [ -f "$TARGET/LICENCE" ]; then
  LICENSE_TYPE=$(head -1 "$TARGET/LICENSE" 2>/dev/null || head -1 "$TARGET/LICENSE.md" 2>/dev/null || echo "不明")
  echo "✅ LICENSE — 存在する（${LICENSE_TYPE}）"
  SCORE=$((SCORE + 1))
else
  echo "❌ LICENSE — 見つからない"
fi

# 6. .gitignore
TOTAL=$((TOTAL + 1))
if [ -f "$TARGET/.gitignore" ]; then
  IGNORE_LINES=$(grep -v '^#' "$TARGET/.gitignore" | grep -v '^$' | wc -l | tr -d ' ')
  echo "✅ .gitignore — 存在する（有効ルール ${IGNORE_LINES} 件）"
  SCORE=$((SCORE + 1))
else
  echo "❌ .gitignore — 見つからない"
fi

# --- スコア集計 ---
echo ""
PERCENT=$((SCORE * 100 / TOTAL))

if [ "$PERCENT" -ge 100 ]; then
  GRADE="🏆 優良"
elif [ "$PERCENT" -ge 80 ]; then
  GRADE="✅ 良好"
elif [ "$PERCENT" -ge 50 ]; then
  GRADE="⚠️ 改善推奨"
else
  GRADE="🔴 要対応"
fi

echo "📊 スコア: ${SCORE}/${TOTAL}（${PERCENT}%）— ${GRADE}"
echo ""
echo "=== レポート終了 ==="
