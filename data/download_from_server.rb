dir = "/mnt/common-ssd/mizsakma/Multilin_15p_concept/multilin_15_city"

to_download = [
    "Budapest/Budapest_stops_with_centrality.csv",
    "Budapest/Budapest_10min_walbetclus.pkl",
    "Amsterdam & Rotterdam/Rotterdam_stops_with_centrality.csv",
    "Amsterdam & Rotterdam/Rotterdam_10min_walbetclus.pkl",
    "Madrid/Madrid_stops_with_centrality.csv",
    "Madrid/Madrid_10min_travel_walbetclus.pkl",
    "Paris/Paris_stops_with_centrality.csv",
    "Paris/Paris_10min_walbetclus.pkl",
]
to_download.each do |file|
%x(scp -P 2222 "pintergreg@193.224.139.167:#{dir}/#{file}" .)
end
