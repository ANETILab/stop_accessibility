city="budapest"
name = "Budapest"
osm = "hungary-20250123.osm.pbf"

%x(osmium tags-filter -o output/#{city}/admin.xml data/osm/#{city}/#{osm} r/boundary=administrative --overwrite)
%x(osmium tags-filter -o output/#{city}/admin_8.xml output/#{city}/admin.xml r/admin_level=8 --overwrite)
%x(osmium tags-filter -o output/#{city}/city.xml output/#{city}/admin_8.xml r/name=#{name} -t --overwrite)
%x(osmium export output/#{city}/city.xml -o output/#{city}/city.geojson -f geojson --attributes type,id --overwrite)
