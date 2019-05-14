require 'mechanize'
require 'json'
require 'rake'
require 'georuby'

task :populate_census_tracts => [:environment] do
  puts "Right now we're only including census tracts that overlap with Lane County, OR."

  # keep track of the number of Census Tracts added to CensusBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/data/cb_2016_us_census_tracts.json") { |line|
    
    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["STATEFP"] != "41"

    # if the zip code doesn't include parts of Lane county, ignore it
    next if !(data["COUNTYFP"].include? "39")

    # if it's already in ZipBoundary, ignore it
    next if CensusBoundary.where(name: data["TRACTCE"]).present?

    # get polygon
    polygon = GeoRuby::SimpleFeatures::MultiPolygon.from_ewkt(data["tract_polygons"])

    # otherwise, create a new record
    CensusBoundary.create(name: data["TRACTCE"], geo_id: data["GEOID"], bounds: polygon.to_coordinates())

    # increment the count
    add_count += 1
  }

  puts "Added #{add_count} census tracts."
  
end