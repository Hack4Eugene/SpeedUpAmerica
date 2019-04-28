require 'mechanize'
require 'json'
require 'rake'

task :populate_census_tracts => [:environment] do
  puts "Right now we're only including census tracts that overlap with Lane County, OR."

  # keep track of the number of Census Tracts added to CensusBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/db/data/cb_2016_us_census_tracts") { |line|
    
    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["STATEFP"] != "41"

    # if the zip code doesn't include parts of Lane county, ignore it
    next if !(data["COUNTYFP"].include? "39")

    # if it's already in ZipBoundary, ignore it
    next if CensusBoundary.where(name: data["TRACTCE"]).present?

    # clean up the lat long pairs
    bounds = clean_bounds(data["tract_polygons"])

    # otherwise, create a new record
    CensusBoundary.create(name: data["TRACTCE"], geo_id: data["GEOID"], bounds: bounds)

    # increment the count
    add_count += 1
  }

  puts "Added #{add_count} census tracts."
  
end

def clean_bounds(b)
  if b.start_with?('MULTIPOLYGON')
    #cords = b.gsub('MULTIPOLYGON(((', '').gsub(')))', '')
    #cords = [cords.split(',').collect{|c| c.split(" ").map(&:to_f).reverse()}]

    #puts cords
    return [[]]
  else
    cords = b.gsub('POLYGON((', '').gsub('))', '')
    cords = [cords.split(',').collect{|c| c.split(" ").map(&:to_f).reverse()}]

    puts cords
    return cords
  end
end
