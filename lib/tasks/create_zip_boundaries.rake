require 'mechanize'
require 'json'
require 'rake'

task :populate_zip_boundaries => [:environment] do
  agent = Mechanize.new
  Submission.where.not(zip_code: [nil, '']).group_by(&:zip_code).each do |zip_code, submissions|
    next if ZipBoundary.where(name: zip_code).present?
    zip_json = JSON.parse(agent.get(zip_json_url(zip_code)).body)
    next if zip_json['q_results'].first['rows'].blank?

    zip_coordinates = zip_json['q_results'].first['rows'].first['features'].first['geometry']['coordinates']
    zip_type = zip_json['q_results'].first['rows'].first['features'].first['geometry']['type']

    ZipBoundary.create(name: zip_code, zip_type: zip_type, bounds: zip_coordinates)
  end
end

def zip_json_url(zip_code)
  "http://data.washingtonpost.com/politics/superzips/?q={'zip':'#{zip_code}'}"
end
