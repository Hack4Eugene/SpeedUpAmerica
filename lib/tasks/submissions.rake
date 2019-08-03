require 'rake'

task :delete_invalid_tests => [:environment] do
  Submission.invalid_test.delete_all
  puts 'All invalid tests are deleted successfully!'
end

task :import_mlab_submissions => [:environment] do
  puts 'Started job to import MLab speed test submissions'

  SubmissionsImporter.import

  count_with_isps = Submission.count
  puts "Tests with ISPs: #{count_with_isps}"
  puts "Tests without ISPs: #{Submission.unscoped.count - count_with_isps}"
  puts "MLab speed test submissions imported successfully at #{Time.now}!"
  puts '*' * 50
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
  puts '*' * 50
end

task :populate_missing_isps => [:environment] do
  Submission.where(:provider => nil).each do |s|
    s.provider = s.get_provider
    s.save
  end
end

def get_census_code(latitude, longitude)
  agent = Mechanize.new
  return nil if latitude.blank? || longitude.blank?

  begin
    response = Timeout::timeout(30) do
      JSON.parse(agent.get(census_tract_url(latitude, longitude)).body)
    end

    response['results'][0]['block_fips'][0..-5]
  rescue
    nil
  end
end

def census_tract_url(lat, long)
  "https://geo.fcc.gov/api/census/area?lat=#{lat}&lon=#{long}&format=json"
end
