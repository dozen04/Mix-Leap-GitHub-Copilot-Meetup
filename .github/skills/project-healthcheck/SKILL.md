---
name: project-healthcheck
description: リポジトリの健康状態を診断し、README・テスト・CI設定・lint設定・LICENSE・.gitignoreの有無をチェックしてスコア付きレポートと改善提案を生成します。「健康診断」「ヘルスチェック」「プロジェクト診断」「リポジトリの状態」「プロジェクトの状態」と依頼されたときに使用します。
---

# プロジェクト健康診断スキル

リポジトリの「健康状態」を診断し、改善提案をスコア付きで報告する。
このスキルは**読み取り専用**であり、ファイルの変更や削除は一切行わない。

## 処理フロー

1. ユーザーが指定したパスを対象とする（省略時はカレントディレクトリ）
2. `scripts/healthcheck.sh` を実行して診断データを取得する
3. `resources/healthcheck-rules.md` を参照して各項目を判定する
4. 結果をスコア付きのレポート形式で出力する
5. 不足している項目について具体的な改善アクションを提案する

## 実行方法

macOS / Linux:
```bash
bash .github/skills/project-healthcheck/scripts/healthcheck.sh [対象パス]
```

Windows（PowerShell）:
```powershell
pwsh .github/skills/project-healthcheck/scripts/healthcheck.ps1 [対象パス]
```

- 対象パスを省略した場合はカレントディレクトリが対象
- OS を判定して適切なスクリプトを選択する
- スクリプトの出力を解釈し、healthcheck-rules.md のルールに従って判定する

## チェック項目

| # | チェック項目 | 確認内容 |
|---|------------|---------|
| 1 | README | README.md の存在と行数 |
| 2 | テスト | test/spec を含むファイルの有無と件数 |
| 3 | CI 設定 | .github/workflows/ 等の有無 |
| 4 | lint 設定 | .eslintrc / .prettierrc / pyproject.toml 等の有無 |
| 5 | LICENSE | LICENSE ファイルの有無 |
| 6 | .gitignore | .gitignore の有無と有効ルール数 |

## 出力のルール

- 絵文字を使って視覚的にわかりやすくする（✅ ❌ 🏆 ⚠️ 🔴）
- 各項目の判定結果を一覧で示す
- 合計スコアとパーセンテージ、総合評価を表示する
- 不足項目には具体的な改善アクションを提案する
- ファイルの変更・削除の提案は**しない**（読み取り専用スキル）
