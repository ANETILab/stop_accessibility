require "optparse"

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: pipeline.rb [options]"

    opts.on("--city CITY", String, "city identifier (i.e. folder name); lower-case, no spaces") do |x|
        options[:city] = x
    end
end.parse!
%x(poetry run python calculate_accessibility.py --city #{options[:city]})
%x(poetry run python determine_stop_polygons.py --city #{options[:city]})
%x(poetry run python count_amenities_in_accessibility_polygons.py --city #{options[:city]})
%x(poetry run python determine_distance_from_center.py --city #{options[:city]})
%x(poetry run python merge_indicators.py --city #{options[:city]})
