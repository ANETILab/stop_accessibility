import math

import contextily as cx
import folium
import geopandas as gpd
import jenkspy
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import xyzservices.providers as xyz
import yaml
from branca.colormap import StepColormap
from matplotlib.colors import to_hex
from shapely import Point, Polygon
from sklearn.preprocessing import minmax_scale

with open("../data/crs.yaml", "r") as fp:
    crs = yaml.safe_load(fp)
with open("../plotting_config.yaml", "r") as fp:
    config = yaml.safe_load(fp)


def determine_square_boundary(
    boundary_polygon: Polygon,
) -> tuple[float, float, float, float]:
    """
    Takes a city boundary as a polygon and calculates its bounds as a square.
    """
    minx, miny, maxx, maxy = boundary_polygon.bounds
    diff_y = maxy - miny
    diff_x = maxx - minx
    offset = abs(diff_y - diff_x) / 2
    if diff_y >= diff_x:
        minx -= offset
        maxx += offset
    else:
        miny -= offset
        maxy += offset
    return minx, miny, maxx, maxy


def get_boundary_centroid(boundary: gpd.GeoDataFrame) -> tuple[float, float]:
    """
    return longitude, latitude of the centroid in EPSG:4326 (WGS84)
    """
    lat, lon = boundary.centroid.to_crs(4326)[0].xy
    return lon[0], lat[0]


def determine_bins(df: pd.DataFrame, column: str, n_classes: int = 6) -> list[float]:
    return jenkspy.jenks_breaks(df[df[column].notna()][column], n_classes=n_classes)


def colorize(
    x: float, bins: list[np.float64], palette: list[tuple[float, float, float]]
) -> str:
    """
    >>> colorize(0.9, [0, 0.5, 1], [(255, 255, 255), (0, 0, 0)])
    '#000000'
    """
    result = 0
    for i, v in enumerate(bins):
        if x < v:
            result = i
            break

    return to_hex(palette[result - 1])


def build_popul_table(row) -> str:
    result = f"""<table>
    <tr>
        <td><strong>stop name:</strong></td>
        <td>{row.stop_name}</td>
    </tr>
    <tr>
        <td><strong>stop id:</strong></td>
        <td>{row.stop_id}</td>
    </tr>
    <tr>
        <td><strong>cluster id:</strong></td>
        <td>{row.cluster}</td>
    </tr>
    <tr>
        <td><strong>ellipticity:</strong></td>
        <td>{row.ellipticity}</td>
    </tr>
    <tr>
        <td><strong>accessible stops:</strong></td>
        <td>{row.number_of_accessible_stops}</td>
    </tr>
    </table>
    """
    return result


def create_colormap(data: pd.DataFrame, column: str, cmap: str) -> StepColormap:
    bins = determine_bins(data, column)
    palette = sns.color_palette(cmap, len(bins) - 1)
    colormap = StepColormap(
        palette,
        vmin=bins[0],
        vmax=bins[-1],
        index=bins,
        caption=column,
    )
    return colormap


def create_feature_group(
    data: pd.DataFrame, column: str, cmap: str
) -> folium.map.FeatureGroup:
    bins = determine_bins(data, column)
    palette = sns.color_palette(cmap, len(bins) - 1)
    fg = folium.FeatureGroup(name=column)
    for row in data.itertuples():
        p = folium.Popup(
            build_popul_table(row),
            max_width=500,
            sticky=True,
        )
        fg.add_child(
            folium.CircleMarker(
                location=[row.stop_lat, row.stop_lon],
                radius=10,
                popup=p,
                fill_color=colorize(getattr(row, column), bins, palette),
                fill=True,
                color="none",
                fill_opacity=0.85,
            ),
        )
    return fg


def create_folium_map(
    data: gpd.GeoDataFrame,
    boundary: gpd.GeoDataFrame,
    lon: float,
    lat: float,
) -> folium.Map:
    m = folium.Map(location=[lon, lat], zoom_start=12, tiles=xyz.CartoDB.Voyager)
    folium.GeoJson(
        boundary.to_crs(4326),
        fill_color="none",
        color="#2d2d2d",
        name="city boundary",
        legend_name="city boundary",
        control=False,
    ).add_to(m)

    fg_el = create_feature_group(
        data.drop_duplicates(subset=["cluster"]),
        "ellipticity",
        "RdYlBu_r",
    )
    scm_el = create_colormap(
        data.drop_duplicates(subset=["cluster"]),
        "ellipticity",
        "RdYlBu_r",
    )
    m.add_child(fg_el)
    scm_el.add_to(m)
    fg_area = create_feature_group(
        data.drop_duplicates(subset=["cluster"]),
        "area",
        "plasma_r",
    )
    scm_area = create_colormap(
        data.drop_duplicates(subset=["area"]),
        "area",
        "plasma_r",
    )
    scm_area.add_to(m)
    fg_area.show = False
    m.add_child(fg_area)
    fg_nas = create_feature_group(
        data.drop_duplicates(subset=["cluster"]),
        "number_of_accessible_stops",
        "viridis_r",
    )
    scm_nas = create_colormap(
        data.drop_duplicates(subset=["number_of_accessible_stops"]),
        "number_of_accessible_stops",
        "viridis_r",
    )
    scm_nas.add_to(m)
    fg_nas.show = False
    m.add_child(fg_nas)
    folium.LayerControl().add_to(m)

    return m


def plot_stops(
    data: gpd.GeoDataFrame,
    boundary: gpd.GeoDataFrame,
    column: str,
    crs: int,
) -> tuple[plt.Figure, plt.Axes]:
    bins = determine_bins(data, column)

    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_axes([0, 0, 1, 1], frameon=False, xticks=[], yticks=[])
    minx, miny, maxx, maxy = determine_square_boundary(boundary.geometry.values[0])
    ax.set_xlim([math.floor(minx), math.ceil(maxx)])
    ax.set_ylim([math.floor(miny), math.ceil(maxy)])
    boundary.plot(ax=ax, fc="none", ec="#2d2d2d")
    data.plot(
        column=column,
        legend=True,
        cmap="RdYlBu_r",
        ax=ax,
        scheme="UserDefined",
        classification_kwds=dict(
            bins=bins[1:],
        ),
        markersize=minmax_scale(
            data[column],
            feature_range=(2, 16),
        ),
    )
    ax.margins(0.1)
    ax.axis("off")
    cx.add_basemap(
        ax,
        crs=crs,
        source=cx.providers.CartoDB.PositronNoLabels,
        alpha=1,
        attribution=False,
    )
    return fig, ax


def plot_histogram(
    data: gpd.GeoDataFrame,
    palette: str = "RdYlBu_r",
) -> tuple[plt.Figure, plt.Axes]:
    bins = np.arange(0, 1.01, 0.05)
    data["hue"] = pd.cut(
        data["ellipticity"],
        bins=bins,
        right=False,
        include_lowest=True,
    )
    fig, ax = plt.subplots(figsize=(6, 6), layout="constrained")
    sns.histplot(
        data.sort_values("ellipticity"),
        x="ellipticity",
        palette=palette,
        edgecolor=".3",
        linewidth=0.5,
        bins=bins,
        hue="hue",
        alpha=1,
        ax=ax,
        legend=False,
    )
    ax.margins(0, 0.05)
    ax.set_xlabel("Elipticity", fontsize=15)
    ax.set_ylabel("Count", fontsize=15)
    return fig, ax


if __name__ == "__main__":
    import argparse

    import yaml

    with open("../data/crs.yaml", "r") as fp:
        crs = yaml.safe_load(fp)
    with open("../plotting_config.yaml", "r") as fp:
        config = yaml.safe_load(fp)

    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        "--city",
        type=str,
        required=True,
        help="city ID (lowercase name)",
    )
    argparser.add_argument(
        "--data-version",
        type=str,
        default="",
        required=False,
        help="data version (subfolder in city)",
    )
    opts = argparser.parse_args()
    data = pd.read_csv(f"../output/{opts.city}/{opts.data_version}/merged.csv")
    data["geometry"] = data.apply(lambda x: Point(x["stop_lon"], x["stop_lat"]), axis=1)
    data = gpd.GeoDataFrame(data, geometry="geometry", crs=4326)

    boundary = gpd.read_file(f"../data/osm/{opts.city}/boundary.geojson").to_crs(
        crs[opts.city]
    )
    boundary_polygon = boundary.geometry[0]
    lon, lat = get_boundary_centroid(boundary)

    to_plot = data.sort_values("ellipticity", ascending=True).to_crs(crs[opts.city])

    fig, ax = plot_stops(
        gpd.clip(to_plot, boundary_polygon).query("ellipticity.notna()"),
        boundary,
        "ellipticity",
        crs=crs[opts.city],
    )

    for i in ["png"]:
        fig.savefig(
            f"../output/{opts.city}/{opts.data_version}/ellipticity_jenks.{i}",
            dpi=300,
            facecolor="white",
            pad_inches=0,
            metadata=config["metadata"][i],
        )

    fig, ax = plot_histogram(
        gpd.clip(to_plot, boundary_polygon).query("ellipticity.notna()")
    )
    for i in ["png"]:
        fig.savefig(
            f"../output/{opts.city}/{opts.data_version}/ellipticity_histogram.{i}",
            dpi=300,
            facecolor="white",
            pad_inches=0,
            metadata=config["metadata"][i],
        )

    m = create_folium_map(data, boundary, lon, lat)
    m.save(f"../output/{opts.city}/{opts.data_version}/folium.html")
