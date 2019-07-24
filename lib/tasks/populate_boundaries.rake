require 'mechanize'
require 'json'
require 'rake'
require 'georuby'
require 'geo_ruby/ewk'

types = {
  :state => [],
  :county => [],
  :zip_code => [],
  :census_tract => [],
  :census_block => [
    "tl_2018_16_tabblock10.json",
    "tl_2018_41_tabblock10.json",
    "tl_2018_53_tabblock10.json",
  ]
}

task :populate_boundaries => [:environment] do
  puts 'Populating boundaries'

  # keep track of the number of zip codes added to ZipBoundary
  add_count = 0

  types.each {|type, files|
    files.each { | jsonFile |
      IO.foreach("/suyc/data/#{jsonFile}") { |line|
        # parse the line
        parser = GeoRuby::GeoJSONParser.new
        feature = parser.parse(line)

        id = feature.properties["GEOID10"]
        geometry = feature.geometry.as_wkt()

        # if not in Boundaries, add it
        if Boundaries.where(boundary_type: type, boundary_id: id).empty?
          if geometry.start_with?('POLYGON')
            geometry = ActiveRecord::Base.connection.execute("SELECT ST_PolygonFromText('#{geometry}')").first[0]
          elsif geometry.start_with?('MULTIPOLYGON')
            geometry = ActiveRecord::Base.connection.execute("SELECT ST_MultiPolygonFromText('#{geometry}')").first[0]
          else
            raise "invalid polygon"
          end

          Boundaries.create(boundary_type: type, boundary_id:id, geometry: geometry)

          # increment the count
          add_count += 1
        end
      }
    }
  }

  puts "Added #{add_count} boundaries"

end

task :populate_missing_boundaries => [:environment] do
  puts 'Populating boundaries'

  Submissions.unscoped.where('zip_code IS NULL OR census_code IS NULL OR census_block IS NULL')

end
