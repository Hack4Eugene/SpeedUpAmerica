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

task :update_pending_census_codes => [:environment] do
  puts 'Updating pending census_codes for submissions'

  count = 0
  submissions = Submission.select("latitude, longitude")
    .where(census_status: Submission::CENSUS_STATUS[:pending])
    .group("latitude, longitude")

  submissions.each do |s|
    census_tract = get_census_code(s.latitude, s.longitude)
    next if census_tract.nil?

    latlong = Submission.unscoped.where('latitude = ? AND longitude = ? AND census_status = ?',
      s.latitude, s.longitude, Submission::CENSUS_STATUS[:pending])
    latlong.update_all({:census_code => census_tract, :census_status => Submission::CENSUS_STATUS[:saved]})

    count += 1
  end

  puts "Updated census_codes of #{count} submissions from #{submissions.size} submissions."
  puts '*' * 50
end

task :create_test_data => [:environment] do
  puts "Creating test data from existing submissions"

  tracts = CensusBoundary.all()
  countTracts = tracts.length

  zips = ZipBoundary.all()
  countZips = zips.length

  submissions = Submission.all()
  submissions.each_with_index do |s, index|
    s.census_code = tracts[index % countTracts].geo_id
    s.census_status = 'saved'
    s.zip_code = zips[index % countZips].name
    s.save
  end

  puts "Done"
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
