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
<!-- - [Paris](https://download.geofabrik.de/europe/france/ile-de-france.html) -->
<!-- - [Rotterdam](https://download.geofabrik.de/europe/netherlands/zuid-holland.html) -->

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
ruby filter.rb --city helsinki --name Helsinki --pbf finland-latest.osm.pbf --delete-intermediate
```
<!-- ruby filter.rb --city rotterdam --name Rotterdam --pbf zuid-holland-latest.osm.pbf --delete-intermediate -->
<!-- ruby filter.rb --city paris --name Paris --pbf ile-de-france-latest.osm.pbf --delete-intermediate -->

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

## workflow

```yaml
- name: extract_accessible_stops.ipynb
  input:
    - 10_minute_walbetclus.pkl
  output:
    - accessible_stops.json
- name: calculate_accessibility.ipynb
  input:
    - valhalla_tiles.tar
    - stops_with_centrality.csv
  output:
    - isochrones.csv
- name: determine_stop_polygons.ipynb
  input:
    - crs.yaml
    - isochrones.csv
    - accessible_stops.json
    - stops_with_centrality.csv
  output:
    - stop_geometries_from_walk.csv
    - stop_geometries_from_walk.geojson
- name: count_amenities_in_accessibility_polygons.ipynb
  input:
    - essential_amenities.yaml
    - amenities_filtered.wkt.csv
    - stop_geometries_from_walk.geojson
  output:
    - amenity_counts_in_accessibility.csv
    - amenity_counts_in_public_transport_accessibility.csv
- name: determine_distance_from_center.ipynb
  input:
    - stops_with_centrality.csv
  output:
    - distance.csv
- name: merge_indicators.ipynb
  input:
    - distance.csv
    - amenity_counts_in_accessibility.csv
    - amenity_counts_in_public_transport_accessibility.csv
    - stop_geometries_from_walk.csv
    - stops_with_centrality.csv
  output:
    - merged.csv

```

The `pipeline.rb` Ruby script can execute every script for a given city.

```mermaid
flowchart TD
flowchart TD

    gini_bud2[Approximate Gini for Budapest from property price]:::gp
    gini_bud[Approximate Gini for Budapest from mobility data]:::zz
    gini_hel[Approximate Gini for Helsinki]:::zz
    gini_mad[Process Gini for Madrid]:::zz
    socioecon[Enrich indicators with socioeconomic status]:::zz
    regressions[Run regressions]:::bl
    sp_stat[(Spanish<br>statistical data)]:::data
    fi_stat[(Finnish<br>statistical data)]:::data
    tkom[(Temporal population density data)]:::data

    gtfs[(GTFS)]:::data
    osm[(OSM)]:::data
    pp[(property price)]:::data
    network[Build network]:::mm
    dfs[Calculate shortest route within time limit]:::mm
    centrality[Calculate network centralities]:::mm
    valhalla[Build valhalla routing network]:::gp

    %%stage0[Extract accessible stops]
    stage1[Calculate walk accessibility]:::gp
    stage2[Calculate ellipticity and accessibility area]:::gp
    stage3[Count amenities in accessibility polygons]:::gp
    stage4[Determine distance from center]:::gp
    stage5[Merge indicators]:::gp

    %%stage0 --> stage2
    stage1 --> stage2
    stage2 --> stage5
    stage3 --> stage5
    stage4 --> stage5

    osm --> valhalla
    valhalla --> stage1
    gtfs --> network
    network --> centrality
    network --> dfs
    dfs --> stage2

    pp --> gini_bud2

    gini_bud --> socioecon
    fi_stat --> gini_hel
    gini_hel --> socioecon
    sp_stat --> gini_mad
    gini_mad --> socioecon
    gini_bud2 --> socioecon

    tkom --> gini_bud

    centrality --> stage5
    stage5 --> socioecon
    socioecon --> regressions

    classDef data fill: #d7aca1, color: black, stroke: black
    classDef bl fill: #34b6c6, color: black, stroke: black
    classDef gp fill: #79ad41, color: black, stroke: black
    classDef mm fill: #4063a3, color: black, stroke: black
    classDef zz fill: #ddc000, color: black, stroke: black

```

### outer sources

- accessible_stops.json
  - this one is based on Maté Mizsák's work, which has two outputs:
    - stops_with_centralities.csv
    - 10_minute_walbetclus.pkl
      - this one is a [pickled](https://docs.python.org/3/library/pickle.html) Python object with the following structure: `dict[str, tuple[list[tuple[list[str], int]], set[str]]]`
      - the dictionary key is a stop ID, the first element of the tuple is a list of routes accessible within 10 minutes (with the exact time required), and the set is a set of stop IDs accessible from the the given stop.
      - the `data/stops/<CITY>/accessible_stops.json` is an extracted form of the set from the `10_minute_walbetclus.pkl`, with the structure of `dict[str, list[str]]]`
      - the list, the first element of the value tuple, describes the possible routes to the accessible stops with a time needed to travel the given route
- [CRS](https://en.wikipedia.org/wiki/Spatial_reference_system), with meter as unit used, for the distance calculations. For each city/country a specific ones should be used, these are read from the [data/crs.yaml](data/crs.yaml) file.
  - for Hungary it is the [Egységes Országos Vetület](https://hu.wikipedia.org/wiki/Egys%C3%A9ges_orsz%C3%A1gos_vet%C3%BClet), also known as [EPSG:23700](https://epsg.io/23700)
  - if needed, you can change it, by modifying the values for every city
- Valhalla tiles in `data/valhalla/<CITY>/valhalla_tiles.tar`
  - for calculating the accessibility areas (`output/<CITY>/isochrones.geojson`), the [isochrone API](https://valhalla.github.io/valhalla/api/isochrone/api-reference/) of the [Valhalla routing engine](https://github.com/valhalla/valhalla) is used.
  - Valhalla uses OpenStreetMap data to prepare a network used for routing. Although it can be used as a server-client application, for projects like this, it is more convient to extract the precompiled network (vallhalla_tiles.tar) and use valhalla from a [python package](https://github.com/gis-ops/pyvalhalla).
  - further info in [this repo](https://github.com/ANET-NETI/accessibility)
- [amenity categories](data/essential_amenities.yaml)
  - based on the paper [The 15-minute city quantified using human mobility data](https://www.nature.com/articles/s41562-023-01770-y)
  - more discussion is here: https://github.com/ANET-NETI/15minute_city/issues/18

### statistical data

#### Finland

- [Paavo – Open data by postal code area](https://stat.fi/org/avoindata/paikkatietoaineistot/paavo_en.html)
  - https://stat.fi/tup/paavo/paavon_aineistokuvaukset_en.html
  - the data is [available](https://stat.fi/org/lainsaadanto/copyright_en.html) under CC-BY 4.0.

#### Spain

The Spanish income data is from [INE. Instituto Nacional de Estadística](https://www.ine.es/dyngs/INEbase/en/operacion.htm?c=Estadistica_C&cid=1254736177088&menu=ultiDatos&idp=1254735976608) via [ineAtlas.data](https://github.com/pablogguz/ineAtlas.data), and is available under CC-BY-4.0.

## output

|column name|description           |
|:----------|:---------------------|
|stop_id|stop ID from the GTFS data|
|area|area of the 5-minute walking polygons from the accessible stops in km^2^, see details above|
|ellipticity|ellipticity value of the stop cluster [0..1], see details above|
|number_of_accessible_stops|the number of accessible stops within 10 minutes|
|concave_area|area of the concave hull of the accessible stops in km^2^|
|distance_betweenness|distance from the stop with the largest betweenness centrality (claster centroid)|
|distance_from_landuse_centroid|distance from the centroid of the residential areas of the city|
|cultural_institutions_multimodal|number of cultural institutions in the multimodal accessibility|
|drugstores_multimodal|number of drugstores in the multimodal accessibility|
|groceries_multimodal|number of grocery stores in the multimodal accessibility|
|healthcare_multimodal|number of healthcare institutions in the multimodal accessibility|
|parks_multimodal|number of parks in the multimodal accessibility|
|religious_organizations_multimodal|number of religious organizations in the multimodal accessibility|
|restaurants_multimodal|number of restaurants in the multimodal accessibility|
|schools_multimodal|number of schools in the multimodal accessibility|
|services_multimodal|number of services in the multimodal accessibility|
|cultural_institutions_walk15|number of cultural institutions 15-minute walking area|
|drugstores_walk15|number of drugstores 15-minute walking area|
|groceries_walk15|number of grocery stores 15-minute walking area|
|healthcare_walk15|number of healthcare institutions 15-minute walking area|
|parks_walk15|number of parks 15-minute walking area|
|religious_organizations_walk15|number of religious organizations 15-minute walking area|
|restaurants_walk15|number of restaurants 15-minute walking area|
|schools_walk15|number of schools 15-minute walking area|
|services_walk15|number of services in the 15-minute walking area|
|walk_area|area of the 15-minute walking polygons from the stop in km^2^|
|area_difference|difference of the (public transport accessibility) area and the walk_area in km^2^|
|eigenvector_centrality|eigenvector centrality of the GTFS netwok|
|degree_centrality|degree centrality of the GTFS network|
|closeness_centrality|closeness centrality of the GTFS network|
|betweenness_centrality|betweenness centrality of the GTFS network|
|cluster|cluster ID, not deterministic|
|stop_lat|latitude of the stop (cluster center)|
|stop_lon|longitude of the stop (cluster center)|
|stop_name|name of the stop in the system of the public transport company|

## Caveats

<!-- As this code uses a precompiled Valhalla network from an old, 2023 September OSM snapshot. -->
- The Budapest isochrones are calculated with an old, 2023 September OSM snapshot.
- [pyvalhalla](https://github.com/gis-ops/pyvalhalla) in unmaintained in its current form and not compatible with Python 3.12+, so this code requires a special environment with Python 3.11
