require 'mechanize'
require 'json'
require 'rake'
require 'georuby'
require 'geo_ruby/ewk'

types = {
  :region => {
    :id_property => "STUSPS",
    :name_property => "NAME",
    :files => [
      "tl_2018_us_state.json",
    ],
  },
  :county => {
    :id_property => "GEOID",
    :name_property => "NAMELSAD",
    :files => [
      "tl_2018_us_county.json",
    ],
  },
  :zip_code => {
    :id_property => "ZCTA5CE10",
    :name_property => "ZCTA5CE10",
    :files => [
      "tl_2018_us_zcta510.json",
    ],
  },
  :census_tract => {
    :id_property => "GEOID",
    :name_property => "GEOID",
    :files => [
      "tl_2018_16_tract.json",
      "tl_2018_41_tract.json",
      "tl_2018_53_tract.json",
    ],
  },
  :census_block => {
    :id_property => "GEOID10",
    :name_property => "GEOID10",
    :files => [
      "tl_2018_16_tabblock10.json",
      "tl_2018_41_tabblock10.json",
      "tl_2018_53_tabblock10.json",
    ],
  }
}

task :populate_boundaries => [:environment] do
  puts 'Populating boundaries'

  # keep track of the number of zip codes added to ZipBoundary
  add_count = 0

  types.each {|type, details|
    details[:files].each { | jsonFile |
      puts "Processing #{jsonFile}"
      STDOUT.flush

      process_count = 0

      IO.foreach("/suyc/data/#{jsonFile}") { |line|
        # parse the line
        parser = GeoRuby::GeoJSONParser.new
        feature = parser.parse(line)

        id = feature.properties[details[:id_property]]
        name = feature.properties[details[:name_property]]
        geometry = feature.geometry.as_wkt()

        # if not in Boundaries, add it
        if Boundaries.where(boundary_type: type, boundary_id: id).empty?
          if geometry.start_with?('POLYGON')
            query = "SELECT ST_PolygonFromText('#{geometry}')"
            geometry = ActiveRecord::Base.connection.execute(query).first[0]
          elsif geometry.start_with?('MULTIPOLYGON')
            query = "SELECT ST_MultiPolygonFromText('#{geometry}')"
            geometry = ActiveRecord::Base.connection.execute(query).first[0]
          else
            raise "invalid polygon"
          end

          Boundaries.create(boundary_type: type, boundary_id:id, name: name, geometry: geometry)

          # increment the count
          add_count += 1
        end

        process_count += 1

        if process_count % 1000 == 0
          print "*"
          STDOUT.flush
        end

        if process_count % 10000 == 0
          print "\n"
          STDOUT.flush
        end
      }

      print "\n"
      STDOUT.flush
    }
  }

  puts "Added #{add_count} boundaries"

end

task :populate_missing_boundaries => [:environment] do
  puts 'Populating missing boundaries'

  count = 0

  clause = "region IS NULL OR county IS NULL OR zip_code IS NULL OR "\
    " census_code IS NULL OR census_block IS NULL"
  submissions = Submission.unscoped.where(clause).find_in_batches do |batch|
    batch.each do |submission|
      submission.populate_boundaries
    end

    count += 1

    print "*"
    STDOUT.flush

    if count % 10 == 0
      print "\n"
      STDOUT.flush
    end
  end

  print "\n"
  STDOUT.flush
end
