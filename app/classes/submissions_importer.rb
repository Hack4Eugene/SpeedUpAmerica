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

    # puts upload_query

    upload_test_data = client.sql(upload_query)
    download_test_data = client.sql(download_query)

    create_submissions(upload_test_data, 'upload')
    create_submissions(download_test_data, 'download')
  end

  def self.time_constraints
    start_time = Date.today - 60 # Populate with last 60 days by default
    start_time = start_time.strftime("%Y-%m-%d %H:%M:%S")

    if Submission.from_mlab.last.nil? == false
      start_time = Submission.from_mlab.last.created_at.strftime("%Y-%m-%d %H:%M:%S")
    end

    end_time = Date.today.strftime("%Y-%m-%d %H:%M:%S")
    "web100_log_entry.log_time >= UNIX_SECONDS('#{start_time}') AND
      web100_log_entry.log_time < UNIX_SECONDS('#{end_time}') AND" 
  end

  def self.upload_query(zip_codes)
    "#standardSQL
    SELECT
      test_id,
      TIMESTAMP_MICROS(web100_log_entry.log_time) AS UTC_date_time,
      NET.IPV4_TO_INT64(NET.IP_FROM_STRING(connection_spec.client_ip)) AS client_ip_numeric,
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
    FROM `measurement-lab.release.ndt_all`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.longitude > -85.948441 AND
      connection_spec.client_geolocation.longitude < -85.4051 AND
      connection_spec.client_geolocation.latitude > 37.9971 AND
      connection_spec.client_geolocation.latitude < 38.38051 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes}) AND
      connection_spec.data_direction = 0 AND
      web100_log_entry.snap.HCThruOctetsReceived >= 8192 AND
      web100_log_entry.snap.Duration >= 9000000 AND
      web100_log_entry.snap.Duration < 600000000 AND
      (web100_log_entry.snap.State = 1 OR (web100_log_entry.snap.State >= 5
        AND web100_log_entry.snap.State <= 11)) AND
      blacklist_flags = 0;"
  end

  def self.download_query(zip_codes)
    "SELECT
      test_id,
      TIMESTAMP_MICROS(web100_log_entry.log_time) AS UTC_date_time,
      NET.IPV4_TO_INT64(NET.IP_FROM_STRING(connection_spec.client_ip)) AS client_ip_numeric,
      connection_spec.client_hostname AS client_hostname,
      connection_spec.client_application AS client_app,
      connection_spec.client_geolocation.city AS city,
      connection_spec.client_geolocation.latitude AS client_latitude,
      connection_spec.client_geolocation.longitude AS client_longitude,
      connection_spec.client_geolocation.postal_code AS postal_code,
      connection_spec.client_geolocation.area_code AS area_code,
      8 * web100_log_entry.snap.HCThruOctetsAcked/ (web100_log_entry.snap.SndLimTimeRwin + web100_log_entry.snap.SndLimTimeCwnd + web100_log_entry.snap.SndLimTimeSnd) AS downloadThroughput,
      NULL AS uploadThroughput,
      web100_log_entry.snap.HCThruOctetsAcked AS HCThruOctetsAcked
    FROM `measurement-lab.release.ndt_all`
    WHERE
      #{time_constraints.to_s}
      connection_spec.client_geolocation.longitude > -85.948441 AND
      connection_spec.client_geolocation.longitude < -85.4051 AND
      connection_spec.client_geolocation.latitude > 37.9971 AND
      connection_spec.client_geolocation.latitude < 38.38051 AND
      connection_spec.client_geolocation.postal_code IN (#{zip_codes}) AND
      connection_spec.data_direction = 1 AND
      web100_log_entry.snap.HCThruOctetsAcked >= 8192 AND
      (web100_log_entry.snap.SndLimTimeRwin +
        web100_log_entry.snap.SndLimTimeCwnd +
        web100_log_entry.snap.SndLimTimeSnd) >= 9000000 AND
      (web100_log_entry.snap.SndLimTimeRwin +
        web100_log_entry.snap.SndLimTimeCwnd +
        web100_log_entry.snap.SndLimTimeSnd) < 600000000 AND
      web100_log_entry.snap.CongSignals > 0 AND
      (web100_log_entry.snap.State = 1 OR
        (web100_log_entry.snap.State >= 5 AND
        web100_log_entry.snap.State <= 11)) AND
      blacklist_flags = 0;"
  end

end
