require 'mechanize'
require 'json'
require 'rake'
require 'georuby'

task :populate_census_tracts => [:environment] do
  puts "Right now we're only including OR."

  # keep track of the number of Census Tracts added to CensusBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/data/cb_2016_us_census_tracts.json") { |line|
    
    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["STATEFP"] != "41"

    # if the zip code doesn't include parts of Lane county, ignore it
    #next if !(data["COUNTYFP"].include? "39")

    # if it's already in CensusBoundary, ignore it
    next if CensusBoundary.where(geo_id: data["GEOID"]).present?

    geom_type = "Polygon"
    polygon = GeoRuby::SimpleFeatures::Polygon.from_ewkt(data["tract_polygons"])
    if data["tract_polygons"].start_with?('MULTIPOLYGON')
      geom_type = "MultiPolygon"
      polygon = GeoRuby::SimpleFeatures::MultiPolygon.from_ewkt(data["tract_polygons"])
    end

    # otherwise, create a new record
    CensusBoundary.create(name: data["GEOID"], geo_id: data["GEOID"], geom_type: geom_type,
      bounds: polygon.to_coordinates())

    # increment the count
    add_count += 1
  }

  puts "Added #{add_count} census tracts."
  
end