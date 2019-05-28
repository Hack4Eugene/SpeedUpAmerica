class SubmissionsImporter

  require 'bigquery-client'

  def self.bigquery_init
    template = ERB.new File.new("#{Rails.root}/config/bigquery.yml").read
    opts = YAML.load template.result(binding)
    BigQuery::Client.new(opts['config'])
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
      submission = Submission.where('test_date = ? AND ip_address = ? AND test_type = ?', Date.parse(row['UTC_date_time']), row['client_ip_numeric'], test_type).first_or_initialize

      next if submission.persisted?

      submission.from_mlab           = true
      submission.completed           = true
      submission.test_type           = test_type
      submission.ip_address          = row['client_ip_numeric']
      submission.test_date           = row['UTC_date_time']
      submission.address             = row['city']
      submission.area_code           = row['area_code']
      submission.zip_code            = row['postal_code']
      submission.hostname            = row['client_hostname']
      submission.latitude            = row['client_latitude']
      submission.longitude           = row['client_longitude']
      submission.provider            = Submission.provider_mapping(submission.get_provider)
      submission.actual_down_speed   = row['downloadThroughput']
      submission.actual_upload_speed = row['uploadThroughput']
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

    upload_test_data = client.sql(upload_query)
    download_test_data = client.sql(download_query)

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
      IF(connection_spec.client_af = 2, NET.IPV4_TO_INT64(NET.IP_FROM_STRING(connection_spec.client_ip)), NULL) AS client_ip_numeric,
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
    FROM `measurement-lab.release.ndt_uploads`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.longitude > -125.3976 AND
      connection_spec.client_geolocation.longitude < -116.0812 AND
      connection_spec.client_geolocation.latitude > 41.7650 AND
      connection_spec.client_geolocation.latitude < 46.3916 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes})
    ORDER BY partition_date ASC, log_time ASC"
  end

  def self.download_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%S', log_time) AS UTC_date_time,
      IF(connection_spec.client_af = 2, NET.IPV4_TO_INT64(NET.IP_FROM_STRING(connection_spec.client_ip)), NULL) AS client_ip_numeric,
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
    FROM `measurement-lab.release.ndt_downloads`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.longitude > -125.3976 AND
      connection_spec.client_geolocation.longitude < -116.0812 AND
      connection_spec.client_geolocation.latitude > 41.7650 AND
      connection_spec.client_geolocation.latitude < 46.3916 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes})
    ORDER BY partition_date ASC, log_time ASC"
  end

end
