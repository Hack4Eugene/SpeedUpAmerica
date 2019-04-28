class SubmissionsImporter

  require 'bigquery-client'

  def self.bigquery_init
    opts = YAML.load_file("#{Rails.root}/config/bigquery.yml")
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
      submission = Submission.where('DATE(created_at) = ? AND ip_address = ? AND test_type = ?', Date.parse(row['UTC_date_time']), row['client_ip_numeric'], test_type).first_or_initialize

      next if submission.persisted?

      submission.from_mlab           = true
      submission.completed           = true
      submission.ip_address          = row['client_ip_numeric']
      submission.created_at          = row['UTC_date_time']
      submission.address             = row['city']
      submission.area_code           = row['area_code']
      submission.zip_code            = row['postal_code']
      submission.hostname            = row['client_hostname']
      submission.latitude            = row['client_latitude']
      submission.longitude           = row['client_longitude']
      submission.provider            = Submission.provider_mapping(submission.get_provider)
      submission.actual_down_speed   = row['downloadThroughput']
      submission.actual_upload_speed = row['uploadThroughput']
      submission.set_census_code(row['client_latitude'], row['client_longitude'])
      submission.save
    end
  end

  def self.import
    client = bigquery_init
    zip_codes = "'#{Submission::ZIP_CODES.join("','")}'"

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
      start_time = Submission.from_mlab.last.created_at.strftime("%Y-%m-%d")
    end
    
    "partition_date BETWEEN '#{start_time}' AND '#{end_time}' AND"
  end

  def self.upload_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%s UTC', log_time) AS UTC_date_time,
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
      connection_spec.client_geolocation.longitude > -124.23023107 AND
      connection_spec.client_geolocation.longitude < -121.76806168 AND
      connection_spec.client_geolocation.latitude > 43.43714199 AND
      connection_spec.client_geolocation.latitude < 44.29054797 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes})
    ORDER BY partition_date DESC"
  end

  def self.download_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      FORMAT_TIMESTAMP('%F %H:%m:%s UTC', log_time) AS UTC_date_time,
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
      connection_spec.client_geolocation.longitude > -124.23023107 AND
      connection_spec.client_geolocation.longitude < -121.76806168 AND
      connection_spec.client_geolocation.latitude > 43.43714199 AND
      connection_spec.client_geolocation.latitude < 44.29054797 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes})
    ORDER BY partition_date DESC"
  end

end
