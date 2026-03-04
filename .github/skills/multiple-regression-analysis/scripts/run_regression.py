import argparse
from datetime import date
from pathlib import Path

import pandas as pd
import statsmodels.api as sm
from statsmodels.stats.outliers_influence import variance_inflation_factor


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run multiple regression and export markdown report")
    parser.add_argument("--input-csv", required=True, help="Path to input CSV")
    parser.add_argument("--target", required=True, help="Target column name")
    parser.add_argument(
        "--features",
        nargs="+",
        required=True,
        help="Feature names. Prefer space-separated (e.g. --features a b c)",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output markdown path. If omitted, reports/YYYY-MM-DD_{target}_regression.md",
    )
    return parser.parse_args()


def resolve_output_path(output_arg: str | None, target: str) -> Path:
    date_filename = f"{date.today().isoformat()}_{target}_regression.md"

    if not output_arg:
        return Path("reports") / date_filename

    output_path = Path(output_arg)
    if output_path.suffix.lower() == ".md":
        return output_path

    return output_path / date_filename


def calculate_vif(features_df: pd.DataFrame) -> pd.DataFrame:
    vif_df = pd.DataFrame()
    vif_df["variable"] = features_df.columns
    vif_df["vif"] = [
        variance_inflation_factor(features_df.values, i)
        for i in range(features_df.shape[1])
    ]
    return vif_df


def vif_label(vif_value: float) -> str:
    if vif_value >= 10:
        return "要対応"
    if vif_value >= 5:
        return "注意"
    return "良好"


def significance_label(p_value: float) -> str:
    return "有意" if p_value < 0.05 else "非有意"


def main() -> None:
    args = parse_args()

    input_path = Path(args.input_csv)
    output_path = resolve_output_path(args.output, args.target)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    raw_features = []
    for token in args.features:
        raw_features.extend(token.split(","))
    features = [feature.strip() for feature in raw_features if feature.strip()]
    if not features:
        raise ValueError("At least one feature is required")

    df = pd.read_csv(input_path)
    required_columns = [args.target, *features]
    missing_columns = [column for column in required_columns if column not in df.columns]
    if missing_columns:
        available_columns = ", ".join(df.columns)
        missing = ", ".join(missing_columns)
        raise ValueError(
            f"Missing columns: {missing}. Available columns: {available_columns}"
        )

    before_rows = len(df)
    df_model = df[required_columns].dropna().copy()
    after_rows = len(df_model)
    dropped_rows = before_rows - after_rows

    y = df_model[args.target]
    x = df_model[features]
    x_with_const = sm.add_constant(x)

    model = sm.OLS(y, x_with_const).fit()

    coef_table = pd.DataFrame(
        {
            "variable": model.params.index,
            "coef": model.params.values,
            "std_err": model.bse.values,
            "t_value": model.tvalues.values,
            "p_value": model.pvalues.values,
        }
    )
    coef_table["significance"] = coef_table["p_value"].apply(significance_label)

    vif_table = calculate_vif(x)
    vif_table["judgement"] = vif_table["vif"].apply(vif_label)

    significant_vars = coef_table[
        (coef_table["variable"] != "const") & (coef_table["p_value"] < 0.05)
    ]["variable"].tolist()

    coef_rows = "\n".join(
        [
            f"| {row.variable} | {row.coef:.4f} | {row.std_err:.4f} | {row.t_value:.4f} | {row.p_value:.4g} | {row.significance} |"
            for row in coef_table.itertuples(index=False)
        ]
    )

    vif_rows = "\n".join(
        [
            f"| {row.variable} | {row.vif:.4f} | {row.judgement} |"
            for row in vif_table.itertuples(index=False)
        ]
    )

    significant_text = ", ".join(significant_vars) if significant_vars else "なし"

    markdown = f"""# 重回帰分析レポート

## 1. 分析サマリー
- データファイル: {input_path.as_posix()}
- 分析対象行数: {after_rows}（欠損除外: {dropped_rows} 行）
- 目的変数: {args.target}
- 説明変数: {', '.join(features)}
- 欠損値処理: 対象列の欠損行を除外

## 2. モデル精度
- R²: {model.rsquared:.4f}
- 調整済みR²: {model.rsquared_adj:.4f}
- F統計量: {model.fvalue:.4f}
- Prob(F-statistic): {model.f_pvalue:.4g}

## 3. 係数テーブル
| 変数 | 係数 | 標準誤差 | t値 | p値 | 判定 |
|------|------|---------|-----|-----|------|
{coef_rows}

## 4. 多重共線性（VIF）
| 変数 | VIF | 判定 |
|------|-----|------|
{vif_rows}

## 5. 解釈と示唆
- 有意な説明変数: {significant_text}
- 留意点: R²が高くても因果関係を直接示すものではないため、業務知識と合わせて解釈する
- 次アクション: 有意かつVIFが低い変数を優先して施策仮説を立案し、最新データで再検証する
"""

    output_path.write_text(markdown, encoding="utf-8")
    print(f"Report generated: {output_path.as_posix()}")


if __name__ == "__main__":
    main()
