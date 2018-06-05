require 'mechanize'
require 'json'
require 'rake'

task :populate_zip_boundaries => [:environment] do
  agent = Mechanize.new
  Submission::ZIP_CODES.each do |zip_code|
    zip_body = agent.get(zip_json_url(zip_code)).body

    polygon = zip_body.split("=")[0].split(" ").last == "polyStrings" ? true : false
    zip_type, zip_coordinates = zip_code_for_polygon(zip_body) if polygon
    zip_type, zip_coordinates = zip_code_for_marker(zip_body) unless polygon

    ZipBoundary.create(name: zip_code, zip_type: zip_type, bounds: zip_coordinates)
  end
  puts 'ZipBoundaries created successfully!'
end

def zip_code_for_marker(zip_body)
  data = zip_body.split(";")
  latitude  = data[0].split('=').last.gsub("'", '').to_f
  longitude = data[1].split(' = ').last.gsub("'", '').to_f
  ['Point', [longitude, latitude]]
end

def zip_code_for_polygon(zip_body)
  zip_coordinates = zip_body.gsub("|", ",").split("polyPoints = '").last.split("';").first.split(',')
  zip_coordinates = [zip_coordinates.map{|a|a.split(" ").map(&:to_f).to_a.reverse}]
  ['Polygon', zip_coordinates]
end

def zip_json_url(zip_code)
  "http://maps.hometownlocator.com/cgi-bin/server_V3.pl?task=getZip&state=CA&mode=zip&zipcode=#{zip_code}"
end
