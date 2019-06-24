class SubmissionsImporter

  require 'google/cloud/bigquery'
  require 'google/api_client/auth/key_utils'

  def self.bigquery_init
    keyFile = ENV['MLAB_BIGQUERY_PRIVATE_KEY']
    keyPassphrase = ENV['MLAB_BIGQUERY_PRIVATE_KEY_PASSPHRASE']
    key = Google::APIClient::KeyUtils.load_from_pkcs12(keyFile, keyPassphrase)
    auth = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      audience: 'https://accounts.google.com/o/oauth2/token',
      scope: 'https://www.googleapis.com/auth/bigquery',
      issuer: ENV['MLAB_BIGQUERY_EMAIL'],
      signing_key: key
    )

    client = Google::Cloud::Bigquery.new(
      project_id: 'measurement-lab',
      credentials: auth
    )

    client
  end

  def self.attributes_list(schema)
    attribute_names = []

    schema['fields'].each do |field|
      attribute_names << field['name']
    end

    attribute_names
  end

  def self.attribute_val(row, attributes, name)
    row['f'][attributes.index(name)]['v']
  end

  def self.create_submissions(data, test_type)
    puts "Importing #{data.count} #{test_type}s"

    data.each do |row|
      count = Submission.unscoped.where('test_date = ? AND ip_address = ? AND test_type = ?', Date.parse(row[:UTC_date_time]), row[:client_ip], test_type).count
      next if count > 0

      submission = Submission.new
      submission.from_mlab           = true
      submission.completed           = true
      submission.test_type           = test_type
      submission.ip_address          = row[:client_ip]
      submission.test_date           = row[:UTC_date_time]
      submission.address             = row[:city]
      submission.area_code           = row[:area_code]
      submission.zip_code            = row[:postal_code]
      submission.hostname            = row[:client_hostname]
      submission.latitude            = row[:client_latitude]
      submission.longitude           = row[:client_longitude]
      submission.provider            = Submission.provider_mapping(submission.get_provider)
      submission.actual_down_speed   = row[:downloadThroughput]
      submission.actual_upload_speed = row[:uploadThroughput]
      submission.census_status       = Submission::CENSUS_STATUS[:pending]

      submission.save
    end
  end

  def self.import
    client = bigquery_init

    zips = ZipBoundary.pluck(:name)
    zip_codes = "'#{zips.join("','")}'"

    upload_query = upload_query(zip_codes)
    download_query = download_query(zip_codes)

    upload_test_data = client.query upload_query do |config|
      config.location = "US"
    end
    download_test_data = client.query download_query do |config|
      config.location = "US"
    end

    create_submissions(upload_test_data, 'upload')
    create_submissions(download_test_data, 'download')
  end

  def self.time_constraints
    start_time = Date.today - 60 # Populate with last 60 days by default
    start_time = start_time.strftime("%Y-%m-%d")
    end_time = Date.today.strftime("%Y-%m-%d")

    if Submission.from_mlab.last.nil? == false
      start_time = Submission.from_mlab.last.test_date.strftime("%Y-%m-%d")
    end
    
    "partition_date BETWEEN '#{start_time}' AND '#{end_time}' AND"
  end

  def self.upload_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%S', log_time) AS UTC_date_time,
      connection_spec.client_ip,
      connection_spec.client_hostname AS client_hostname,
      connection_spec.client_application AS client_app,
      connection_spec.client_geolocation.city AS city,
      connection_spec.client_geolocation.latitude AS client_latitude,
      connection_spec.client_geolocation.longitude AS client_longitude,
      connection_spec.client_geolocation.postal_code AS postal_code,
      connection_spec.client_geolocation.area_code AS area_code,
      8 * web100_log_entry.snap.HCThruOctetsReceived/web100_log_entry.snap.Duration AS uploadThroughput,
      NULL AS downloadThroughput,
      web100_log_entry.snap.Duration AS duration,
      web100_log_entry.snap.HCThruOctetsReceived AS HCThruOctetsRecv
    FROM `measurement-lab.ndt.uploads`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.postal_code IN (#{zip_codes}) AND
      connection_spec.client_geolocation.longitude > -179.5838 AND
      connection_spec.client_geolocation.longitude < -58.6461 AND
      connection_spec.client_geolocation.latitude > 14.2649 AND
      connection_spec.client_geolocation.latitude < 72.5019
    ORDER BY partition_date ASC, log_time ASC"
  end

  def self.download_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%S', log_time) AS UTC_date_time,
      connection_spec.client_ip,
      connection_spec.client_hostname AS client_hostname,
      connection_spec.client_application AS client_app,
      connection_spec.client_geolocation.city AS city,
      connection_spec.client_geolocation.latitude AS client_latitude,
      connection_spec.client_geolocation.longitude AS client_longitude,
      connection_spec.client_geolocation.postal_code AS postal_code,
      connection_spec.client_geolocation.area_code AS area_code,
      8 * web100_log_entry.snap.HCThruOctetsAcked/ (web100_log_entry.snap.SndLimTimeRwin + web100_log_entry.snap.SndLimTimeCwnd + web100_log_entry.snap.SndLimTimeSnd) AS downloadThroughput,
      NULL AS uploadThroughput,
      web100_log_entry.snap.Duration AS duration,
      web100_log_entry.snap.HCThruOctetsReceived AS HCThruOctetsRecv
    FROM `measurement-lab.ndt.downloads`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.postal_code IN (#{zip_codes}) AND
      connection_spec.client_geolocation.longitude > -179.5838 AND
      connection_spec.client_geolocation.longitude < -58.6461 AND
      connection_spec.client_geolocation.latitude > 14.2649 AND
      connection_spec.client_geolocation.latitude < 72.5019
    ORDER BY partition_date ASC, log_time ASC"
  end

end
