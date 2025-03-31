require "optparse"

options = {ellipticity_threshold: 5, centrality: "Betweenness Centrality"}
OptionParser.new do |opts|
    opts.banner = "Usage: pipeline.rb [options]"

    opts.on("--city CITY", String, "city identifier (i.e. folder name); lower-case, no spaces") do |x|
        options[:city] = x
    end
    opts.on("--ellipticity-threshold THRESHOLD", Integer, "number of stops requires to calculate ellipticity") do |x|
        options[:ellipticity_threshold] = x
    end
    opts.on("--centrality CENTRALITY", String, "centrality measure to use, possible values: Eigenvector Centrality, Degree Centrality, Closeness Centrality, Betweenness Centrality") do |x|
        options[:centrality] = x
    end
end.parse!

puts "calculate_accessibility"
%x(poetry run python calculate_accessibility.py --city #{options[:city]})
puts "determine_stop_polygons"
%x(poetry run python determine_stop_polygons.py --city #{options[:city]} --ellipticity-threshold #{options[:ellipticity_threshold]})
puts "count_amenities_in_accessibility_polygons"
%x(poetry run python count_amenities_in_accessibility_polygons.py --city #{options[:city]})
puts "determine_distance_from_center"
%x(poetry run python determine_distance_from_center.py --city #{options[:city]} --centrality "#{options[:centrality]}")
puts "merge_indicators"
%x(poetry run python merge_indicators.py --city #{options[:city]})
