require "optparse"
require "fileutils"

options = {ellipticity_threshold: 5, centrality: "Betweenness Centrality", data_version: "", stages: ["0", "1", "2", "3", "4", "5"]}
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
    opts.on("--data-version VERSION", String, "data version (subfolder in city)") do |x|
        options[:data_version] = x
    end
    opts.on("--stages STAGES", String, "stages separated by comma, i.e.: 0,1,2,3,4,5") do |x|
        options[:stages] = x.split(",")
    end
end.parse!

FileUtils.mkdir_p "../output/#{options[:city]}/#{options[:data_version]}"

if options[:stages].include? "0"
    puts "[stage 0] extract_accessible_stops"
    %x(poetry run python extract_accessible_stops.py --city #{options[:city]} --data-version "#{options[:data_version]}")
end
if options[:stages].include? "1"
    puts "[stage 1] calculate_accessibility"
    %x(poetry run python calculate_accessibility.py --city #{options[:city]} --data-version "#{options[:data_version]}")
end
if options[:stages].include? "2"
    puts "[stage 2] determine_stop_polygons"
    %x(poetry run python determine_stop_polygons.py --city #{options[:city]} --ellipticity-threshold #{options[:ellipticity_threshold]} --data-version "#{options[:data_version]}")
end
if options[:stages].include? "3"
    puts "[stage 3] count_amenities_in_accessibility_polygons"
    %x(poetry run python count_amenities_in_accessibility_polygons.py --city #{options[:city]} --data-version "#{options[:data_version]}")
end
if options[:stages].include? "4"
    puts "[stage 4] determine_distance_from_center"
    %x(poetry run python determine_distance_from_center.py --city #{options[:city]} --centrality "#{options[:centrality]}" --data-version "#{options[:data_version]}")
end
if options[:stages].include? "5"
    puts "[stage 5] merge_indicators"
    %x(poetry run python merge_indicators.py --city #{options[:city]} --data-version "#{options[:data_version]}")
end
