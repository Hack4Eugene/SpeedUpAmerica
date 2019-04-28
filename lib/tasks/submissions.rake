require 'rake'

task :delete_invalid_tests => [:environment] do
  Submission.invalid_test.delete_all
  puts 'All invalid tests are deleted successfully!'
end

task :import_mlab_submissions => [:environment] do
  puts 'Started job to import MLab speed test submissions'
  count_with_isps = Submission.count
  count_without_isps = Submission.unscoped.count

  SubmissionsImporter.import

  puts "Tests with ISPs: #{Submission.count - count_with_isps}"
  puts "Tests without ISPs: #{Submission.unscoped.count - count_without_isps}"
  puts "MLab speed test submissions imported successfully at #{Time.now}!"
  puts '*' * 50
end

task :update_pending_census_codes => [:environment] do
  puts 'Updating pending census_codes for submissions'

  count = 0
  submissions = Submission.where(census_status: Submission::CENSUS_STATUS[:pending])

  submissions.each do |s|
    s.set_census_code(s.latitude, s.longitude)
    s.save && count += 1 if s.census_code.present?
  end

  puts "Updated census_codes of #{count} submissions from #{submissions.size} submissions."
  puts '*' * 50
end

task :populate_census_boundaries_old => [:environment] do
  puts 'Populating census boundaries...'

  Submission::GEO_IDS.each do |uai|
    agent = Mechanize.new
    census_json = JSON.parse(agent.get(area_identifier_json_url(uai)).body)
    census_name = census_json['area']['TRACTCE']
    area_identifier_id = census_json['area']['UAID']
    census_geo_id = census_json['area']['GEOID']
    census_coordinates = census_json['geom'].gsub('POLYGON ((', '').gsub('))', '')
    census_coordinates = [census_coordinates.split(',').collect{|c| c.split(" ").map(&:to_f)}]

    boundary = CensusBoundary.where(name: census_name.to_i, geo_id: census_geo_id).first_or_initialize
    boundary.area_identifier = area_identifier_id
    boundary.bounds = census_coordinates
    boundary.save
  end

  puts 'Census boundaries successfully populated'
end

task :populate_median_speeds => [:environment] do
  puts 'Populating median speeds...'
  data = Submission.where(upload_median: nil, download_median: nil).group_by { |s| [s.longitude, s.latitude] }

  speeds_data = {}

  data.each do |coordinates, submissions|
    longitude, latitude = coordinates
    key = [longitude, latitude].join('_')
    upload_median = Submission.median submissions.map(&:actual_upload_speed)
    download_median = Submission.median submissions.map(&:actual_down_speed)
    speeds_data[key] = { upload: upload_median, download: download_median }
  end

  Submission.all.each do |s|
    key = [s.longitude, s.latitude].join('_')
    median_speeds = speeds_data[key]
    s.upload_median = median_speeds[:upload]
    s.download_median = median_speeds[:download]
    s.save
  end

  puts 'Median speeds successfully populated'
end

def area_identifier_json_url(area_identifier)
  "http://www.usboundary.com/api/areadata/geom/?id=#{area_identifier}"
end
