import pandas as pd
import argparse

argparser = argparse.ArgumentParser()
argparser.add_argument(
    "--city",
    type=str,
    required=True,
    help="city IDs (lowercase name)",
)
argparser.add_argument(
    "--data-version",
    type=str,
    default="",
    required=False,
    help="data version (subfolder in city)",
)
opts = argparser.parse_args()

path = f"../output/{opts.city}/{opts.data_version}"

indicators = pd.read_csv(f"{path}/merged.csv")


if opts.city == "helsinki":
    stop_socioecon = pd.read_csv(f"{path}/stop_socioecon.csv")
    merged = indicators.merge(stop_socioecon, on="stop_id")
    merged = merged.rename(
        columns={
            "walk15_gini": "weighted_gini_walk",
            "multimodal_gini": "weighted_gini_multi",
            "median_income_walk": "weighted_med_inc_walk",
            "median_income_multimodal": "weighted_med_inc_multi",
        }
    )
if opts.city == "madrid":
    stop_socioecon = pd.read_csv(f"{path}/stop_socioecon.csv")
    merged = indicators.merge(stop_socioecon, on="stop_id")
    merged = merged.rename(
        columns={
            "walk15_gini": "weighted_gini_walk",
            "multimodal_gini": "weighted_gini_multi",
            "income_walk": "weighted_net_income_hh_walk",
            "income_multimodal": "weighted_net_income_hh_multi",
        }
    )
if opts.city == "budapest":
    stop_socioecon_pp = pd.read_csv(f"{path}/stop_socioecon_property_price.csv")
    stop_socioecon_tpdd = pd.read_csv(f"{path}/stop_socioecon_from_mobility.csv")
    merged = indicators.merge(stop_socioecon_pp, on="stop_id").merge(
        stop_socioecon_tpdd, on="stop_id"
    )
    merged = merged.rename(
        columns={
            "walk15_gini": "gini_house_walk15",
            "multimodal_gini": "gini_house_multimodal",
        }
    )


merged.to_csv(f"{path}/indicators_with_ses.csv", index=False)
