import geopandas as gpd
import pandas as pd
import yaml
from shapely import from_wkt


def count_amenities_in_walk_accessibility(
    isochrones: gpd.GeoDataFrame,
    amenities: gpd.GeoDataFrame,
) -> pd.DataFrame:
    result = pd.DataFrame()
    for i in isochrones[["costing", "range"]].drop_duplicates().itertuples():
        ac = (
            isochrones.query(f"range == {i.range} & costing=='{i.costing}'")
            .sjoin(amenities)
            .groupby(["stop_id", "category"])["osm_id"]
            .count()
            .reset_index()
        )
        ac.rename({"osm_id": "count"}, axis=1, inplace=True)

        ac = (
            pd.pivot_table(ac, index=["stop_id"], columns=["category"], values="count")
            .fillna(0)
            .map(int)
            .reset_index()
        )

        ac["costing"] = i.costing
        ac["range"] = i.range
        result = pd.concat([result, ac])
    return result


def count_amenities_in_public_transport_accessibility(
    sgfw: gpd.GeoDataFrame,
    amenities: gpd.GeoDataFrame,
) -> pd.DataFrame:
    temp = sgfw.sjoin(amenities)
    temp = temp.groupby(["stop_id", "category"])["osm_id"].count().reset_index()
    temp.rename({"osm_id": "count"}, axis=1, inplace=True)
    temp = (
        pd.pivot_table(temp, index=["stop_id"], columns=["category"], values="count")
        .fillna(0)
        .map(int)
        .reset_index()
    )
    temp["costing"] = "public_transport"
    # temp["range"] = "10+5"
    temp["range"] = pd.NA
    return temp


def create_lookup(essential_amenities: dict[str, list[str]]) -> dict[str, str]:
    result = {}
    for cat, osm_list in essential_amenities.items():
        for i in osm_list:
            result[i] = cat
    return result


def load_category_lookup():
    with open("../data/essential_amenities.yaml", "r") as fp:
        essential_amenities = yaml.safe_load(fp)
    return create_lookup(essential_amenities)


def prepare_amenities(city: str) -> gpd.GeoDataFrame:
    lookup = load_category_lookup()
    amenities = gpd.read_file(
        f"../output/{city}/amenities/amenities_filtered.wkt.csv", engine="pyogrio"
    )
    amenities.rename({"category": "osm_category"}, axis=1, inplace=True)
    amenities["category"] = amenities["osm_category"].map(lookup)
    amenities.dropna(subset=["category"], inplace=True)
    amenities.drop(
        ["osm_type", "amenity_type", "amenity_subtype"],
        axis=1,
        inplace=True,
    )
    amenities["geometry"] = amenities["geometry"].apply(from_wkt)
    amenities = gpd.GeoDataFrame(amenities, geometry="geometry", crs=4326)
    return amenities


if __name__ == "__main__":
    import argparse

    from common import load_isochrones

    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        "--city",
        type=str,
        required=True,
        help="city ID (lowercase name)",
    )
    opts = argparser.parse_args()

    isochrones = load_isochrones(opts.city)
    amenities = prepare_amenities(opts.city)

    aciwa = count_amenities_in_walk_accessibility(isochrones, amenities)
    aciwa.to_csv(
        f"../output/{opts.city}/amenity_counts_in_accessibility.csv", index=False
    )

    sgfw = gpd.read_file(f"../output/{opts.city}/stop_geometries_from_walk.geojson")
    sgfw["stop_id"] = sgfw["stop_id"].apply(str)

    acipta = count_amenities_in_public_transport_accessibility(sgfw, amenities)
    acipta.to_csv(
        f"../output/{opts.city}/amenity_counts_in_public_transport_accessibility.csv",
        index=False,
    )
