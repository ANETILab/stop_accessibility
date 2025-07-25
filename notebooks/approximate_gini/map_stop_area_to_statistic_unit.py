import geopandas as gpd
import numpy as np
import pandas as pd


def merge_stop_area_with_statistics(
    stop_areas: gpd.GeoDataFrame,
    statistics: gpd.GeoDataFrame,
    stat_unit_id: str,
    stat_column: str = "gini",
) -> gpd.GeoDataFrame:
    mm = (
        stop_areas.sjoin(
            statistics[[stat_unit_id, "geometry"]],
            how="left",
            predicate="intersects",
        )
        .drop(columns="index_right")
        .merge(
            statistics[[stat_unit_id, "geometry", stat_column]],
            on=stat_unit_id,
            suffixes=["", "_stat"],
        )
    )
    mm["ratio"] = (
        mm["geometry"].intersection(mm["geometry_stat"]).area / mm["geometry_stat"].area
    )
    return mm


def calculate_weighted_mean(
    x: pd.DataFrame, column: str, weight_column: str
) -> np.float64:
    return np.average(x[column], weights=x[weight_column])


def aggregate_to_stop_area(data: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    result = pd.DataFrame()
    for i in columns:
        temp = (
            data.groupby("stop_id")
            .apply(
                calculate_weighted_mean,
                column=i,
                weight_column="ratio",
                include_groups=False,
            )
            .reset_index()
            .rename(columns={0: i})
        )
        if result.shape == (0, 0):
            result = temp.copy()
        else:
            result = result.merge(temp, on="stop_id", how="outer")
    return result
