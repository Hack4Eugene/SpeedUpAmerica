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

  def self.import
    client = bigquery_init

    country_code = 'US'
    regions = ['OR', 'WA', 'ID']
    test_types = ['upload', 'download']
    end_time = Date.today.strftime("%Y-%m-%d")

    regions.each do |region|
      test_types.each do |test_type|
        # Track start time of previous batch to abort if we repeat dates
        previous_start = nil

        while true #we may need to get multiple batches
          start_time = get_start_time(country_code, region, test_type)

          # Abort if we repeat start date
          if previous_start == start_time
            break
          end
          previous_start = start_time

          puts "Starting batch #{Time.now}"

          if test_type == 'upload'
            query = upload_query(country_code, region, start_time, end_time)
          else
            query = download_query(country_code, region, start_time, end_time)
          end

          data = client.query(query)
          create_submissions(data, test_type)

          puts "Finishing batch #{Time.now}"
        end
      end
    end

    # Delete any submissions older than 13 months ago
    old = Date.today.at_beginning_of_month - 13.months
    puts "Deleting records older than #{old}"
    Submission.where('test_date < ?', old).delete_all
  end

  def self.upload_query(country_code, region, start_date, end_date)
    puts "Getting upload data for #{country_code} #{region} between #{start_date} and #{end_date}"

    "#standardSQL
    SELECT
      ndt5.ParseInfo.TaskFileName AS test_id,
      TIMESTAMP_SECONDS(ndt5.log_time) AS UTC_date_time,
      ndt5.result.ClientIP AS client_ip,
      tcpinfo.Client.Geo.latitude AS client_latitude,
      tcpinfo.Client.Geo.longitude AS client_longitude,
      tcpinfo.Client.Geo.country_code AS country_code,
      tcpinfo.Client.Geo.region AS region,
      tcpinfo.Client.Geo.city AS city,
      tcpinfo.Client.Geo.postal_code AS postal_code,
      ndt5.result.C2S.MeanThroughputMbps AS uploadThroughput,
      NULL AS downloadThroughput,
      TIMESTAMP_DIFF(ndt5.result.C2S.EndTime, ndt5.result.C2S.StartTime, MICROSECOND) AS duration,
      tcpinfo.FinalSnapshot.TCPInfo.BytesReceived AS HCThruOctetsRecv,
      ndt5.result.C2S.UUID AS test_UUID
    FROM
      `measurement-lab.ndt.ndt5` ndt5,
      `measurement-lab.ndt.tcpinfo` tcpinfo
    WHERE
      ndt5.partition_date BETWEEN '#{start_date}' AND '#{end_date}'
      AND ndt5.result.C2S.UUID = tcpinfo.UUID
      AND tcpinfo.Client.Geo.country_code = '#{country_code}'
      AND tcpinfo.Client.Geo.region = '#{region}'
    ORDER BY ndt5.partition_date ASC, ndt5.log_time ASC"
  end

  def self.download_query(country_code, region, start_date, end_date)
    puts "Getting download data for #{country_code} #{region} between #{start_date} and #{end_date}"

    "#standardSQL
    SELECT
      ndt5.ParseInfo.TaskFileName AS test_id,
      TIMESTAMP_SECONDS(ndt5.log_time) AS UTC_date_time,
      ndt5.result.ClientIP AS client_ip,
      tcpinfo.Client.Geo.latitude AS client_latitude,
      tcpinfo.Client.Geo.longitude AS client_longitude,
      tcpinfo.Client.Geo.country_code AS country_code,
      tcpinfo.Client.Geo.region AS region,
      tcpinfo.Client.Geo.city AS city,
      tcpinfo.Client.Geo.postal_code AS postal_code,
      ndt5.result.S2C.MeanThroughputMbps AS downloadThroughput,
      NULL AS uploadThroughput,
      TIMESTAMP_DIFF(ndt5.result.S2C.EndTime, ndt5.result.S2C.StartTime, MICROSECOND) AS duration,
      tcpinfo.FinalSnapshot.TCPInfo.BytesReceived AS HCThruOctetsRecv,
      ndt5.result.S2C.UUID AS test_UUID
    FROM
      `measurement-lab.ndt.ndt5` ndt5,
      `measurement-lab.ndt.tcpinfo` tcpinfo
    WHERE
      ndt5.partition_date BETWEEN '#{start_date}' AND '#{end_date}'
      AND ndt5.result.C2S.UUID = tcpinfo.UUID
      AND tcpinfo.Client.Geo.country_code = '#{country_code}'
      AND tcpinfo.Client.Geo.region = '#{region}'
    ORDER BY ndt5.partition_date ASC, ndt5.log_time ASC"
  end

  def self.get_start_time(country_code, region, test_type)
    start_time = Date.today.at_beginning_of_month - 13.months

    latest_record = Submission.where(:country_code => country_code, :region => region,
      :test_type => test_type, :from_mlab => 1).order("test_date DESC").first
    if latest_record.nil? == false
      start_time = latest_record.test_date.strftime("%Y-%m-%d")
    end

    return start_time
  end

  def self.create_submissions(data, test_type)
    puts "Importing #{data.count} #{test_type}s"

    data.each do |row|
      count = Submission.unscoped.where('test_date = ? AND ip_address = ? AND test_type = ?',
        row[:UTC_date_time], row[:client_ip], test_type).count
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
      submission.actual_down_speed   = row[:downloadThroughput]
      submission.actual_upload_speed = row[:uploadThroughput]

      submission.provider            = submission.get_provider

      submission.latitude            = row[:client_latitude]
      submission.longitude           = row[:client_longitude]
      submission.location            = nil
      submission.save

      # These execute update queries using the new submissions id
      submission.populate_location
      submission.populate_boundaries
    end
  end

end
