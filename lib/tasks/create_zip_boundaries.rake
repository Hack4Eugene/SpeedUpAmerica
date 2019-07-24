require 'mechanize'
require 'json'
require 'rake'
require 'georuby'
require 'geo_ruby/geojson'
require 'geo_ruby/ewk'


task :populate_zip_boundaries => [:environment] do
  puts "Right now we're only including OR, WA, and ID."

  # keep track of the number of zip codes added to ZipBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/data/us_zip_codes.json") { |line|

    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["state_code"] != "OR" && data["state_code"] != "WA" && data["state_code"] != "ID"

    # if the zip code doesn't include parts of Lane county, ignore it
    #next if !(data["county"].include? "Lane")

    # if it's already in ZipBoundary, ignore it
    if ZipBoundary.where(name: data["zip_code"]).empty?
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
    end

    # if not in Boundaries, add it
    if Boundaries.where(boundary_type: 'zip_code', boundary_id: data["zip_code"]).empty?
      if data["zcta_geom"].start_with?('POLYGON')
        geo = ActiveRecord::Base.connection.execute("SELECT ST_PolygonFromText('#{data['zcta_geom']}')").first[0]
      elsif data["zcta_geom"].start_with?('MULTIPOLYGON')
        geo = ActiveRecord::Base.connection.execute("SELECT ST_MultiPolygonFromText('#{data['zcta_geom']}')").first[0]
      else
        raise "invalid polygon"
      end

      Boundaries.create(boundary_type: 'zip_code', boundary_id: data["zip_code"], geometry: geo)
    end
  }

  puts "Added #{add_count} zip codes."

end
