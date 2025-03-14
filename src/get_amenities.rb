require "fileutils"

city = "budapest"
osm_file = "hungary-20250123.osm.pbf"
city = "helsinki"
osm_file = "finland-latest.osm.pbf"
city = "madrid"
osm_file = "madrid-latest.osm.pbf"
city = "rotterdam"
osm_file = "zuid-holland-latest.osm.pbf"
city = "paris"
osm_file = "ile-de-france-latest.osm.pbf"

categories = ["amenity", "leisure", "office", "shop", "tourism"]
categories.each do |category|
    puts category
    FileUtils.mkdir_p "../output/#{city}/amenities/"
    %x(osmium tags-filter -o ../output/#{city}/amenities/#{category}.xml ../data/osm/#{city}/#{osm_file} nwr/#{category})
    %x(osmium export ../output/#{city}/amenities/#{category}.xml -o ../output/#{city}/amenities/#{category}.geojson -f geojson --attributes type,id --geometry-types point,polygon)
end
