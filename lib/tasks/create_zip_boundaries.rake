require 'mechanize'
require 'json'
require 'rake'

task :populate_zip_boundaries => [:environment] do
  puts "Right now we're only including zip codes that overlap with Lane County, OR."

  # keep track of the number of zip codes added to ZipBoundary
  add_count = 0

  # read in the JSON line by line
  IO.foreach("/suyc/db/data/us_zip_codes.json") { |line|
    
    # parse the line
    data = JSON.parse(line)

    # if the zip code isn't in Oregon, ignore it
    next if data["state_code"] != "OR"

    # if the zip code doesn't include parts of Lane county, ignore it
    next if !(data["county"].include? "Lane County")

    # if it's already in ZipBoundary, ignore it
    next if ZipBoundary.where(name: data["zip_code"]).present?

    # clean up the lat long pairs
    bounds = clean_bounds(data["zcta_geom"])

    # otherwise, create a new record
    # in the original file, it had "zip_type", I'm not sure what that means
    ZipBoundary.create(name: data["zip_code"], zip_type: "Polygon", bounds: bounds)

    # increment the count
    add_count += 1
  }

  puts "Added #{add_count} zip codes."
  
end

def clean_bounds(b)
  temp = b.gsub("POLYGON", "").gsub("(", "").gsub(")", "").gsub("MULTI", "").split(", ")
  temp2 = Array.new
  bounds = Array.new
  temp.each {|x| temp2 << x.split()}
  temp2.each { |s| bounds << [s[0].to_f, s[1].to_f]}
  return bounds
end
