import argparse
import subprocess

argparser = argparse.ArgumentParser()
argparser.add_argument(
    "--city",
    type=str,
    required=True,
    help="city ID (lowercase name)",
)
argparser.add_argument(
    "--ellipticity-threshold",
    type=int,
    default=5,
    required=False,
    help="number of stops requires to calculate ellipticity",
)
argparser.add_argument(
    "--centrality",
    type=str,
    default="Betweenness Centrality",
    required=False,
    help="centrality measure to use, possible values: Eigenvector Centrality, Degree Centrality, Closeness Centrality, Betweenness Centrality",
)
opts = argparser.parse_args()

subprocess.run(
    ["poetry run python calculate_accessibility.py", f"--city {opts.city}"],
    capture_output=True,
)
subprocess.run(
    [
        "poetry run python determine_stop_polygons.py",
        f"--city {opts.city}",
        f"--ellipticity-threshold {opts.ellipticity_threshold}",
    ],
    capture_output=True,
)
subprocess.run(
    [
        "poetry run python count_amenities_in_accessibility_polygons.py",
        f"--city {opts.city}",
    ],
    capture_output=True,
)
subprocess.run(
    [
        "poetry run python determine_distance_from_center.py",
        f"--city {opts.city}",
        f"--centrality {opts.centrality}",
    ],
    capture_output=True,
)
subprocess.run(
    [
        "poetry run python merge_indicators.py",
        f"--city {opts.city}",
    ],
    capture_output=True,
)
