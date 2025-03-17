# stop accessibility

## requirements

To calculate the accessibility isochrones this code uses the [Valhalla](https://github.com/valhalla/valhalla) routing engine via [pyvalhalla](https://github.com/gis-ops/pyvalhalla).
As pyvalhalla is no longer developed, it cannot work with Python newer with 3.11.

To install an older Python version, `pyenv` was used.

```
pyenv install 3.11.11
```

The dependencies are managed with [poetry](https://python-poetry.org/).

```
poetry lock && poetry install
```

## OSM source

Geofabrik, with the smallest possible unit:

- [Budapest](https://download.geofabrik.de/europe/hungary.html)
- [Helsinki](https://download.geofabrik.de/europe/finland.html)
- [Madrid](https://download.geofabrik.de/europe/spain/madrid.html)
- [Paris](https://download.geofabrik.de/europe/france/ile-de-france.html)
- [Rotterdam](https://download.geofabrik.de/europe/netherlands/zuid-holland.html)

## accessibility area output schema

- geometries are in EPSG:4326 projection
- costing denotes whether the area is calculated by walking (walk) or biking (bicycle)
- range is in minute
- the isochrones are also available in GeoJSON format

|   stop_id | geometry                                                    | costing |   range |
|----------:|:------------------------------------------------------------|:--------|--------:|
|    008951 | POLYGON ((19.218675 47.433216, [...], 19.218675 47.433216)) | walk    |       5 |
|    008951 | POLYGON ((19.220675 47.436717, [...], 19.220675 47.436717)) | walk    |      10 |
|    008951 | POLYGON ((19.220675 47.43934,  [...], 19.220675 47.43934))  | walk    |      15 |
|    008951 | POLYGON ((19.217675 47.440074, [...], 19.217675 47.440074)) | bicycle |       5 |
|    008951 | POLYGON ((19.215675 47.449231, [...], 19.215675 47.449231)) | bicycle |      10 |
|    008951 | POLYGON ((19.210675 47.456055, [...], 19.210675 47.456055)) | bicycle |      15 |

NB: geometries are shortened in the sample above, consequently not valid


## get city boundaries

```
ruby filter.rb --city budapest --name Budapest --pbf hungary-20250123.osm.pbf --delete-intermediate
ruby filter.rb --city madrid --name Madrid --pbf madrid-latest.osm.pbf --delete-intermediate
ruby filter.rb --city rotterdam --name Rotterdam --pbf zuid-holland-latest.osm.pbf --delete-intermediate
ruby filter.rb --city paris --name Paris --pbf ile-de-france-latest.osm.pbf --delete-intermediate
ruby filter.rb --city helsinki --name Helsinki --pbf finland-latest.osm.pbf --delete-intermediate
```

## calculate stop distance from the city center

- distance is simply the Euclidean distance in a meter based projection
    - the projections are stored in the [`data/crs.yaml`](data/crs.yaml)

The city center can be defined multiple ways.
The centroid of the city geometry can be considered as the center, but could raise problems if the city shape in concave (e.g., Rotterdam).
Not aiming for a universal solution, the centroid of the residential areas (filtering from OSM by the [landuse key](https://wiki.openstreetmap.org/wiki/Key:landuse)) could solve the problem, at least in the case of Rotterdam, because the western part is industrial area only.

Another option is to use the [GTFS](https://en.wikipedia.org/wiki/GTFS) networks and select the largest [betweenness centrality](https://en.wikipedia.org/wiki/Betweenness_centrality).
However, as the network uses a clustering, the centrality value will be the same for multiple stops (of a cluster), which provides multiple stop instead of a single point.

There are two possible ways to determine the center of the cluster, representing the city center: using the centroid (left) or the medoid (right) of the cluster points.
Centroid defines a new, "virtual" stop, while medoid is an existing stop.
In the example below the difference is marginal, a couple of meters only, so it has no significant effect to the outcome.
Still, both of them is provided.

<img src=".github/fovam_stop_centroid.png" alt="centroid" title="centroid" width="250">
<img src=".github/fovam_stop_medoid.png" alt="medoid" title="medoid" width="250">

 <!-- <figure>
    <img src=".github/fovam_stop_centroid.png" alt="centroid" width="250">
    <figcaption>centroid</figcaption>
</figure>
 <figure>
    <img src=".github/fovam_stop_medoid.png" alt="medoid" width="250">
    <figcaption>medoid</figcaption>
</figure> -->

## Ellipticity

Ellipticity is an indicator describing the shape of a polygon.
Its domain is between 0 and 1, the larger the value is the shape of the polygon is more elongated.

First example is Fővám square (blue), its ellipticity is low (0.06), whereas the 509th street (red) is much more elongated, its ellipticity is high (0.61).

<img src=".github/fovam_accessibility_area.png" alt="Fővám tér" title="Fővám tér - 0.06" width="250">
<img src=".github/509_accessibility_area.png" alt="509. utca" title="509.utca - 0.61" width="300">

Ellipticity is defined as follows.
$$ellipticity = 1.0 - (minor\_axis\_length / major\_axis\_length)$$


## Accessibility polygons

The stops are extracted from the GTFS (and clustered as described above).
From each point, a 5-minute walking accessibility area is generated by Valhalla.
The 15-minute walking area is also calculated.

Using the timetable in the GTFS data, stops that are available from a given stop by 10-minute public transport are determined.
The multimodal (currently 5-minute walk + 10-minute public transport) accessibility area is defined as the union of every 5-minute stop walking area of those stops that are available within a 10-minute public transport trip.
See the example below.

<img src=".github/method.png" alt="509. utca" title="509.utca - 0.61" width="350">

### amenity count

The amenities, extracted from OpenStreetMap, which are within the accessibility ranges (either 15-minute walk oe multimodal) are counted.

The amenities are aggregated to higher-level [categories](data/essential_amenities.yaml).

## Caveats

The Budapest isochrones are calculated with an old, 2023 September OSM snapshot.
<!-- As this code uses a precompiled Valhalla network from an old, 2023 September OSM snapshot. -->
