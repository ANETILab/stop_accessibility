city = "rotterdam"
%x(poetry run python calculate_accessibility.py --city #{city})
%x(poetry run python determine_stop_polygons.py --city #{city})
%x(poetry run python count_amenities_in_accessibility_polygons.py --city #{city})
%x(poetry run python determine_distance_from_center.py --city #{city})
%x(poetry run python merge_indicators.py --city #{city})
