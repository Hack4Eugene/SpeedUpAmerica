require 'mechanize'
require 'json'
require 'rake'
require 'georuby'
require 'geo_ruby/ewk' 


task :populate_zip_boundaries => [:environment] do
  puts "Right now we're only including zip codes that overlap with Lane County, OR."

  # keep track of the number of zip codes added to ZipBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/data/us_zip_codes.json") { |line|
    
    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["state_code"] != "OR"

    # if the zip code doesn't include parts of Lane county, ignore it
    #next if !(data["county"].include? "Lane")

    # if it's already in ZipBoundary, ignore it
    next if ZipBoundary.where(name: data["zip_code"]).present?
    
    zip_type = "Polygon"
    polygon = GeoRuby::SimpleFeatures::Polygon.from_ewkt(data["zcta_geom"])
    if data["zcta_geom"].start_with?('MULTIPOLYGON')
      zip_type = "MultiPolygon"
      polygon = GeoRuby::SimpleFeatures::MultiPolygon.from_ewkt(data["zcta_geom"])
    end

    # otherwise, create a new record
    ZipBoundary.create(name: data["zip_code"], zip_type: zip_type, bounds: polygon.to_coordinates())

    # increment the count
    add_count += 1
  }

  puts "Added #{add_count} zip codes."
  
end