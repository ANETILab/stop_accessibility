require "optparse"

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: test_release.rb [options]"

    opts.on("--city CITY", String, "city identifier (i.e. folder name); lower-case, no spaces") do |x|
        options[:city] = x
    end
    opts.on("--name NAME", String, "city name (in OSM)") do |x|
        options[:name] = x
    end
    opts.on("--pbf PBF", String, "PBF filename") do |x|
        options[:pbf] = x
    end
    opts.on("--delete-intermediate", "delete intermediate files") do |x|
        options[:delete_intermediate] = true
    end
end.parse!

%x(osmium tags-filter -o ../data/osm/#{options[:city]}/admin.xml ../data/osm/#{options[:city]}/#{options[:pbf]} r/boundary=administrative --overwrite)
%x(osmium tags-filter -o ../data/osm/#{options[:city]}/admin_8.xml ../data/osm/#{options[:city]}/admin.xml r/admin_level=8 --overwrite)
%x(osmium tags-filter -o ../data/osm/#{options[:city]}/boundary.xml ../data/osm/#{options[:city]}/admin_8.xml r/name=#{options[:name]} -t --overwrite)
%x(osmium export ../data/osm/#{options[:city]}/boundary.xml -o ../data/osm/#{options[:city]}/boundary.geojson -f geojson --attributes type,id --overwrite)

if options[:delete_intermediate]
    File.delete "../data/osm/#{options[:city]}/admin.xml"
    File.delete "../data/osm/#{options[:city]}/admin_8.xml"
    File.delete "../data/osm/#{options[:city]}/boundary.xml"
end
