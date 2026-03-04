---
name: multiple-regression-analysis
description: CSVデータに対して重回帰分析（OLS）を実行し、係数・p値・R²・VIFを含むレポートを生成します。
---

# 重回帰分析スキル（シンプル版）

このスキルは **Python スクリプト1本だけ** で重回帰分析を行う。
余計な分岐や追加手順は使わない。

## 入力

- CSV ファイルパス
- 目的変数（1つ）
- 説明変数（1つ以上）

※ 目的変数・説明変数は CSV に存在する列名であれば自由に変更可能

## 実行方法

```bash
python .github/skills/multiple-regression-analysis/scripts/run_regression.py \
  --input-csv data/marketing_mix_sample.csv \
  --target sales \
  --features tv_spend digital_spend discount_rate
```

出力先を明示したい場合のみ `--output` を付ける:

```bash
python .github/skills/multiple-regression-analysis/scripts/run_regression.py \
  --input-csv data/marketing_mix_sample.csv \
  --target sales \
  --features tv_spend digital_spend discount_rate \
  --output reports/custom_report.md
```

## 出力

- 出力先フォルダ: `reports/`
- デフォルトファイル名（`--output` 未指定）: `YYYY-MM-DD_{target}_regression.md`
  - 任意ファイル名にしたい場合は `--output` を指定（例: `--output reports/{target}_regression.md`）
- 含まれる内容:
  - 分析サマリー
  - モデル精度（R²、調整済みR²、F統計量）
  - 係数テーブル（係数、標準誤差、t値、p値）
  - VIF（多重共線性）

## ルール

- 不足列がある場合はエラーで列名一覧を返す
- 欠損値は対象列の行を除外
- 有意判定は `p < 0.05`
