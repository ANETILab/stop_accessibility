import geopandas as gpd
import pandas as pd
from shapely import Point


def load_stops(city: str) -> gpd.GeoDataFrame:
    stops = pd.read_csv(
        f"../data/stops/{city}/stops_with_centrality.csv",
        engine="pyarrow",
        dtype={"stop_id": str},
    )
    stops["geometry"] = stops.apply(
        lambda x: Point(x["stop_lon"], x["stop_lat"]), axis=1
    )
    stops = gpd.GeoDataFrame(stops, geometry="geometry", crs=4326)
    return stops
