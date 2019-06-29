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

  def self.import
    client = bigquery_init

    country_code = 'US'
    regions = ['OR', 'WA', 'ID']
    end_time = Date.today.strftime("%Y-%m-%d")

    regions.each do |region|     

      while true #we may need to get multiple batches
        start_time = get_start_time(country_code, region, "upload")
        if start_time == end_time
          break
        end

        upload_query = upload_query(country_code, region, start_time, end_time)
        upload_test_data = client.query(upload_query)
        create_submissions(upload_test_data, 'upload')
      end

      while true #we may need to get multiple batches
        start_time = get_start_time(country_code, region, "download")
        if start_time == end_time
          break
        end

        download_query = download_query(country_code, region, start_time, end_time)
        download_test_data = client.query(download_query)
        create_submissions(download_test_data, 'download')
      end

    end
  end

  def self.upload_query(country_code, region, start_date, end_date)
    puts "Getting upload data for #{country_code} #{region} between #{start_date} and #{end_date}"

    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%S', log_time) AS UTC_date_time,
      connection_spec.client_ip,
      connection_spec.client_hostname AS client_hostname,
      connection_spec.client_application AS client_app,
      connection_spec.client_geolocation.latitude AS client_latitude,
      connection_spec.client_geolocation.longitude AS client_longitude,
      connection_spec.client_geolocation.country_code AS country_code,
      connection_spec.client_geolocation.region AS region,
      connection_spec.client_geolocation.city AS city,
      connection_spec.client_geolocation.postal_code AS postal_code,
      8 * web100_log_entry.snap.HCThruOctetsReceived/web100_log_entry.snap.Duration AS uploadThroughput,
      NULL AS downloadThroughput,
      web100_log_entry.snap.Duration AS duration,
      web100_log_entry.snap.HCThruOctetsReceived AS HCThruOctetsRecv
    FROM `measurement-lab.ndt.uploads`
    WHERE
      partition_date BETWEEN '#{start_date}' AND '#{end_date}' AND
      connection_spec.client_geolocation.country_code = '#{country_code}' AND
      connection_spec.client_geolocation.region = '#{region}'
    ORDER BY partition_date ASC, log_time ASC"
  end

  def self.download_query(country_code, region, start_date, end_date)
    puts "Getting download data for #{country_code} #{region} between #{start_date} and #{end_date}"

    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%S', log_time) AS UTC_date_time,
      connection_spec.client_ip,
      connection_spec.client_hostname AS client_hostname,
      connection_spec.client_application AS client_app,
      connection_spec.client_geolocation.latitude AS client_latitude,
      connection_spec.client_geolocation.longitude AS client_longitude,
      connection_spec.client_geolocation.country_code AS country_code,
      connection_spec.client_geolocation.region AS region,
      connection_spec.client_geolocation.city AS city,
      connection_spec.client_geolocation.postal_code AS postal_code,
      8 * web100_log_entry.snap.HCThruOctetsAcked/ (web100_log_entry.snap.SndLimTimeRwin + web100_log_entry.snap.SndLimTimeCwnd + web100_log_entry.snap.SndLimTimeSnd) AS downloadThroughput,
      NULL AS uploadThroughput,
      web100_log_entry.snap.Duration AS duration,
      web100_log_entry.snap.HCThruOctetsReceived AS HCThruOctetsRecv
    FROM `measurement-lab.ndt.downloads`
    WHERE
      partition_date BETWEEN '#{start_date}' AND '#{end_date}' AND
      connection_spec.client_geolocation.country_code = '#{country_code}' AND
      connection_spec.client_geolocation.region = '#{region}'
    ORDER BY partition_date ASC, log_time ASC"
  end

  def self.get_start_time(country_code, region, test_type)
    start_time = "2019-04-01"

    if Submission.where(:country_code => country_code, :region => region,
        :test_type => test_type, :from_mlab => 1).order("test_date DESC").first.nil? == false
      start_time = Submission.from_mlab.last.test_date.strftime("%Y-%m-%d")
    end
    
    return start_time
  end

  def self.create_submissions(data, test_type)
    puts "Importing #{data.count} #{test_type}s"

    data.each do |row|
      count = Submission.unscoped.where('test_date = ? AND ip_address = ? AND test_type = ?',
        Date.parse(row[:UTC_date_time]), row[:client_ip], test_type).count
      next if count > 0

      submission = Submission.new
      submission.from_mlab           = true
      submission.completed           = true
      submission.test_type           = test_type
      submission.ip_address          = row[:client_ip]
      submission.test_date           = row[:UTC_date_time]
      submission.country_code        = row[:country_code]
      submission.region              = row[:region]
      submission.address             = row[:city]
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

end
