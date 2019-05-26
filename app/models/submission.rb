class Submission < ActiveRecord::Base
  extend ActionView::Helpers::NumberHelper
  require 'csv'

  obfuscate_id spin: 81238123
  MOBILE_MAXIMUM_SPEED = 50

  CENSUS_STATUS = { pending: 'pending', saved: 'saved' }

  MAP_FILTERS = {
    connection_type: {
      home_wifi: 'Home Wifi',
      mobile_data: 'Mobile Data',
      public_wifi: 'Public Wifi',
      all: ['Home Wifi', 'Mobile Data', 'Public Wifi'],
    },

    group_by: {
      zip_code: 'zip_code',
      census_tract: 'census_code',
    },

    test_type: {
      download: 'download',
      upload: 'upload',
    },

    period: {
      month: 'Month',
      year: 'Year',
    },
  }

  CSV_COLUMNS = [
    'Response #', 'Source', 'Day', 'Time', 'How Are You Testing', 'Zip', 'Census Tract',
    'Provider', 'How are you connected', 'Price Per Month', 'Advertised Download Speed',
    'Satisfaction Rating', 'Download Speed', 'Upload Speed', 'Advertised Price Per Mbps',
    'Actual Price Per Mbps', 'Ping'
  ]

  ZIP_CODES = ZipBoundary.pluck(:name)
  CENSUS_CODES = CensusBoundary.pluck(:geo_id)

  validates :testing_for, length: { maximum: 20 }
  validates :provider, :connected_with, length: { maximum: 50 }

  #after_create :update_provider_statistics, if: Proc.new { |submission| submission.provider.present? },
  #                                          unless: :invalid_test_result
  #after_create :update_median_speeds

  default_scope { where('from_mlab = 0 OR (from_mlab = 1 AND provider IS NOT NULL)') }

  scope :mapbox_filter, -> (test_type) { in_zip_code_list.with_test_type(test_type).select('latitude, longitude, zip_code, actual_down_speed, actual_upload_speed, upload_median, download_median') }
  scope :mapbox_filter_by_zip_code, -> (test_type) { in_zip_code_list.with_test_type(test_type).select('zip_code, actual_down_speed, actual_upload_speed').group_by(&:zip_code) }
  scope :with_date_range, -> (start_date, end_date) { where('test_date >= ? AND test_date <= ?', start_date, end_date.end_of_day) }
  scope :with_test_type, -> (test_type) { where(test_type: [test_type, 'both']) }
  scope :completed, -> { where(completed: true) }
  scope :in_zip_code_list, -> { valid_test.where(zip_code: ZIP_CODES).where.not(zip_code: [nil, '']) }
  scope :valid_test, -> { where.not(test_type: 'duplicate') }
  scope :invalid_test, -> { where('testing_for = ? AND actual_down_speed > ?', 'Mobile Data', MOBILE_MAXIMUM_SPEED) }
  scope :with_connection_type, -> (connection_type) { where(testing_for: connection_type) }
  scope :with_type_and_lower_speed, -> (type, down_speed) { where('testing_for =? AND actual_down_speed < ?', type, down_speed) }
  scope :with_provider, -> (provider) { where(provider: provider) }
  scope :with_zip_code, -> (zip_code) { where(zip_code: zip_code) }
  scope :with_rating, -> (rating) { where(rating: rating) }
  scope :valid_rating, -> { where('rating > 0') }
  scope :from_mlab, -> { where(from_mlab: true) }
  scope :mapbox_filter_by_census_code, -> (test_type) { in_census_code_list.with_test_type(test_type).select('census_code, actual_down_speed, actual_upload_speed').group_by(&:census_code) }
  scope :in_census_code_list, -> { valid_test.where(census_code: CENSUS_CODES) }
  scope :with_census_code, -> (census_code) { where(census_code: census_code) }

  def self.create_submission(params)
    duplicate_ipa_tests = Submission.where('test_date = ? AND ip_address = ?', Date.today, params[:ip_address])

    submission = Submission.new(params)

    if submission.monthly_price.present? && submission.provider_down_speed.present? && submission.actual_down_speed.present?
      submission.provider_price = submission.monthly_price / submission.provider_down_speed
      submission.actual_price = submission.monthly_price / submission.actual_down_speed
    end

    submission.test_date = Date.today
    submission.test_type = 'duplicate' if duplicate_ipa_tests.present?
    submission.completed = true if submission.valid_attributes?
    submission.test_id = [Time.now.utc.to_i, SecureRandom.hex(10)].join('_')
    submission.provider = submission.get_provider
    submission.save
    submission
  end

  def valid_attributes?
    has_required_fields?
  end

  def has_required_fields?
    [provider, monthly_price, provider_down_speed, rating].all?(&:present?)
  end

  def self.get_all_results
    all_results = {}

    ProviderStatistic.not_empty.each do |provider_statistic|
      provider_name = provider_statistic.name
      all_results[provider_name] = {}
      all_results[provider_name]['count'] = provider_statistic.applications
      all_results[provider_name]['rating'] = filter_rating(provider_statistic.rating)
      all_results[provider_name]['ratio'] = amount_to_percentage(provider_statistic.advertised_to_actual_ratio)
      all_results[provider_name]['cost'] = '%.2f' % provider_statistic.average_price
    end

    all_results
  end

  def self.fetch_mapbox_data(params)
    if params[:group_by] == MAP_FILTERS[:group_by][:zip_code]
      set_mapbox_polygon_data(params)
    elsif params[:group_by] == MAP_FILTERS[:group_by][:census_tract]
      set_mapbox_census_data(params)
    elsif params[:group_by] == MAP_FILTERS[:group_by][:individual_responses] && params[:is_ie] == 'no'
      set_mapbox_gl_data(params)
    elsif params[:group_by] == MAP_FILTERS[:group_by][:individual_responses] && params[:is_ie] == 'yes'
      set_mapbox_markers_data(params)
    end
  end

  def self.provider_names(provider_ids)
    return ProviderStatistic.pluck(:name) if provider_ids == ['all']
    ProviderStatistic.where(id: provider_ids).pluck(:name)
  end

  def self.set_mapbox_polygon_data(params, data=[])
    agent = Mechanize.new
    date_range = params[:date_range].to_s.split(' - ')
    start_date, end_date = Time.parse(date_range[0]).utc, Time.parse(date_range[1]).utc if date_range.present?
    providers = provider_names(params[:provider])
    params[:zip_code] = ZIP_CODES if params[:zip_code] == ['all']
    params[:census_code] = CENSUS_CODES if params[:census_code] == ['all']

    polygon_data = valid_test
    polygon_data = polygon_data.where(provider: providers)
    polygon_data = polygon_data.with_date_range(start_date, end_date)         if date_range.present?
    polygon_data = polygon_data.with_zip_code(params[:zip_code])              if params[:zip_code].present?
    polygon_data = polygon_data.with_census_code(params[:census_code])        if params[:census_code].present?
    polygon_data = polygon_data.mapbox_filter_by_zip_code(params[:test_type]) if params[:test_type].present?

    #boundaries = Rails.cache.fetch('zip_boundaries', expires_in: 2.hours) do
      zip_boundaries = {}
      ZipBoundary.where(name: ZIP_CODES).each do |zip|
        zip_boundaries[zip.name] = { zip_type: zip.zip_type, bounds: zip.bounds }
      end
      #zip_boundaries
    #end

    boundaries = zip_boundaries

    polygon_data.each do |zip_code, submissions|
      attribute_name = speed_attribute(params[:test_type])
      median_speed  = median(submissions.map(&:"#{attribute_name}")).to_f
      zip_boundary = boundaries[zip_code]

      next if zip_boundary.present? == false

      zip_coordinates = zip_boundary[:bounds]
      zip_type = zip_boundary[:zip_type]

      feature = {
        'type': 'Feature',
        'properties': {
          'title': zip_code,
          'count': number_with_delimiter(submissions.length, delimiter: ','),
          'median_speed': median_speed,
          'fast_speed': '%.2f' % submissions.map(&:"#{attribute_name}").compact.max.to_f,
          'fillColor': set_color(median_speed),
          'fillOpacity': 0.5,
          'weight': 2,
          'opacity': 1,
          'color': set_color(median_speed),
        },
        'geometry': {
          'type': zip_type,
          'coordinates': zip_coordinates
        }
      }

      data << feature
    end

    data
  end

  def self.set_mapbox_census_data(params, data=[])
    agent = Mechanize.new
    date_range = params[:date_range].to_s.split(' - ')
    start_date, end_date = Time.parse(date_range[0]).utc, Time.parse(date_range[1]).utc if date_range.present?
    providers = provider_names(params[:provider])
    params[:zip_code] = ZIP_CODES if params[:zip_code] == ['all']
    params[:census_code] = CENSUS_CODES if params[:census_code] == ['all']

    polygon_data = valid_test
    polygon_data = polygon_data.where(provider: providers)
    polygon_data = polygon_data.with_date_range(start_date, end_date) if date_range.present?
    polygon_data = polygon_data.mapbox_filter_by_census_code(params[:test_type]) if params[:test_type].present?

    #boundaries = Rails.cache.fetch('census_boundaries', expires_in: 2.hours) do
      census_boundaries = {}
      CensusBoundary.where(geo_id: CENSUS_CODES).each do |boundary|
        census_boundaries[boundary.geo_id] = {
           geom_type: boundary.geom_type,
           bounds: boundary.bounds
        }
      end
      #census_boundaries
    #end

    boundaries = census_boundaries

    polygon_data.each do |census_code, submissions|
      attribute_name = speed_attribute(params[:test_type])
      median_speed  = median(submissions.map(&:"#{attribute_name}")).to_f
      census_boundary = boundaries[census_code]

      next if census_boundary.present? == false

      census_coordinates = census_boundary[:bounds]
      geom_type = census_boundary[:geom_type]

      feature = {
        'type': 'Feature',
        'properties': {
          'title': census_code,
          'count': number_with_delimiter(submissions.length, delimiter: ','),
          'median_speed': median_speed,
          'fast_speed': '%.2f' % submissions.map(&:"#{attribute_name}").compact.max.to_f,
          'fillColor': params['type'] == 'stats' && set_stats_color(submissions.count) || set_color(median_speed),
          'fillOpacity': 0.5,
          'weight': 2,
          'opacity': 1,
          'color': params['type'] == 'stats' && set_stats_color(submissions.count) || set_color(median_speed),
        },
        'geometry': {
          'type': geom_type,
          'coordinates': census_coordinates,
        }
      }

      data << feature
    end

    data
  end

  def set_census_code(latitude, longitude)
    agent = Mechanize.new
    return nil if latitude.blank? || longitude.blank?

    begin
      response = Timeout::timeout(30) do
        JSON.parse(agent.get(Submission.census_tract_url(latitude, longitude)).body)
      end

      fips = response['results'][0]['block_fips']
      self.assign_attributes(census_code: fips[0..-5], census_status: CENSUS_STATUS[:saved]) if fips.present?
    rescue
      self.census_status = CENSUS_STATUS[:pending]
    end
  end

  def self.census_tract_url(lat, long)
    "https://geo.fcc.gov/api/census/area?lat=#{lat}&lon=#{long}&format=json"
  end

  def self.median(array)
    sorted = array.compact.sort
    len = sorted.length
    ((sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0).round(4) if sorted.present?
  end

  def self.search(provider, test_type, date_range)
    date_range = date_range.to_s.split(' - ')
    start_date, end_date = Time.parse(date_range[0]).utc, Time.parse(date_range[1]).utc if date_range.present?
    providers = ProviderStatistic.where(id: provider).pluck(:name)

    submissions = valid_test
    submissions = submissions.where(provider: providers)            if providers.present?
    submissions = submissions.mapbox_filter(test_type)              if test_type.present?
    submissions = submissions.with_date_range(start_date, end_date) if date_range.present?

    submissions
  end

  def self.set_mapbox_gl_data(params, data=[])
    submissions = search(params[:provider], params[:test_type], params[:date_range])

    submissions.each do |submission|
      attribute_name = "#{params[:test_type]}_median"
      speed = submission.send(attribute_name)

      data << { 'type': 'Feature', 'properties': { 'description': "Median #{params[:test_type].titleize} Speed: <strong>#{speed} Mbps</strong>" }, 'geometry': { 'type': 'Point', 'coordinates': [ submission.longitude, submission.latitude ] } }
    end

    { features: data }
  end

  def self.set_mapbox_markers_data(params, data=[])
    submissions = search(params[:provider], params[:test_type], params[:date_range])

    submissions.each do |submission|
      attribute_name = speed_attribute(params[:test_type])
      speed = submission.send(attribute_name)

      feature = {
                  title: "#{params[:test_type].titleize} Speed: <strong>#{speed} Mbps</strong>",
                  geometry: {
                    latitude: submission.latitude,
                    longitude: submission.longitude,
                  },
                  properties: {
                    'marker-color': set_color(speed),
                    'marker-size': 'small',
                    'marker-symbol': 'star',
                  }
                }

      data << feature
    end

    data
  end

  def self.set_color(speed)
    case speed
      when 0..5.9999999999 then '#D73027'
      when 6..17.9999999999 then '#FDAE61'
      when 18..24.9999999999 then '#FFFFBF'
      when 25..74.9999999999 then '#A6D96A'
      when 75..99.9999999999 then '#1A9641'
      else '#7030A0'
    end
  end

  def self.set_stats_color(speed)
    case speed
      when 0..10.9999999999 then '#EFF3FF'
      when 11..50.9999999999 then '#C6DBEF'
      when 51..100.9999999999 then '#9ECAE1'
      when 101..250.9999999999 then '#6BAED6'
      when 251..500.9999999999 then '#4292C6'
      when 501..1000.9999999999 then '#2171B5'
      else '#084594'
    end
  end

  def self.filter_satisfaction(value)
    case value
      when 'All' then 0..7
      when 'Negative' then 0...3
      when 'Neutral' then 3...5
      when 'Positive' then 5..7
    end
  end

  def self.get_satisfaction(satisfaction)
    case satisfaction
      when 0...3 then 'Negative'
      when 3...5 then 'Neutral'
      when 5..7 then 'Positive'
    end
  end

  def self.zip_json_url(zip_code)
    api_key = ENV['MAPTECHNICA_API_KEY']
    "https://api.maptechnica.com/v1/zip5/bounds?zip5=#{zip_code}&key=#{api_key}"
  end

  def self.get_location_data(params)
    geocoder = Geocoder.search("#{params[:latitude]}, #{params[:longitude]}").first
    data =  {
              'address' => geocoder.address,
              'zip_code' => geocoder.postal_code,
            }
  end

  def self.to_csv(date_range)
    range = date_range.split(' - ')
    CSV.generate do |csv|
      csv << CSV_COLUMNS
      in_zip_code_list.with_date_range(Time.parse(range[0]), Time.parse(range[1])).find_in_batches(batch_size: 1000) do |submissions|
        submissions.each do |submission|
          csv <<  [
            submission.id, submission.source, submission.test_date.strftime('%B %d, %Y'), submission.test_date.in_time_zone('EST').strftime('%R %Z'),
            testing_for_mapping(submission.testing_for), submission.zip_code, submission.census_code, submission.provider, submission.connected_with,
            submission.monthly_price, submission.provider_down_speed, submission.rating, submission.actual_down_speed, submission.actual_upload_speed,
            submission.provider_price, submission.actual_price, submission.ping
          ]
        end
      end
    end
  end

  def self.testing_for_mapping(testing_for)
    {
      'Home Wifi'   => 'Home',
      'Mobile Data' => 'Mobile',
      'Public Wifi' => 'Work/Public',
    }[testing_for]
  end

  def self.provider_mapping(provider)
    original_provider = {
      'AT&T Services, Inc.' => 'ATT',
      'AT&T Data Communications Services' => 'ATT',
      'IgLou Internet Services' => 'Iglou',
      'Level 3 Communications, Inc.' => 'Level 3',
      'Time Warner Cable Internet LLC' => 'Time Warner',
      'Windstream Communications Inc' => 'Windstream',
    }[provider]

    original_provider.present? && original_provider || provider
  end

  def update_provider_statistics
    return if provider.blank?
    provider_name = provider
    provider_statistic = ProviderStatistic.get_by_name(provider_name).first_or_initialize
    provider_statistic.from_mlab = true unless provider_statistic.persisted?
    provider_applications = provider_statistic.applications
    provider_statistic.rating = calculate_average(rating.to_i, provider_statistic.rating, provider_applications)

    provider_statistic.actual_speed_sum += actual_down_speed.to_f
    provider_statistic.provider_speed_sum += provider_down_speed.to_f

    provider_statistic.advertised_to_actual_ratio = get_actual_to_provider_difference(provider_statistic.actual_speed_sum, provider_statistic.provider_speed_sum) unless provider_statistic.provider_speed_sum.zero?

    provider_statistic.average_price = calculate_average(actual_price.to_f, provider_statistic.average_price , provider_applications)
    provider_statistic.increment(:applications)
    provider_statistic.save
  end

  def update_median_speeds
    upload_speeds = Submission.where(latitude: latitude, longitude: longitude).pluck(:actual_upload_speed)
    download_speeds = Submission.where(latitude: latitude, longitude: longitude).pluck(:actual_down_speed)
    self.upload_median = Submission.median upload_speeds
    self.download_median = Submission.median download_speeds

    self.save
  end

  def self.filter_rating(rating)
    (rating * 2).ceil.to_f / 2
  end

  def self.amount_to_percentage(amount)
    amount * 100
  end

  def self.map_range_values(range)
    {
      '0..5.99' => '0 to 5 Mbps',
      '6..10.99' => '6 to 10 Mbps',
      '11..20.99' => '11-20 Mbps',
      '21..40.99' => '21-40 Mbps',
      '40..60.99' => '40-60 Mbps',
      '61..80.99' => '61-80 Mbps',
      '81..100.99' => '81-100 Mbps',
      '101..250.99' => '101-250 Mbps',
      '251..500.99' => '251-500 Mbps',
      '500..1000.99' => '500-1000 Mbps',
      '1001+' => '1001 Mbps+',
    }[range]
  end

  def self.count_between(submissions, range, test_type)
    attribute_name = speed_attribute(test_type)
    if '+'.in?(range)
      lower = range.gsub('+', '').to_f
      submissions.where("#{attribute_name} >= ?", lower).count
    else
      range_values = range.split('..')
      lower = range_values[0].to_f
      upper = range_values[1].to_f
      submissions.where("#{attribute_name}": [lower..upper]).count
    end
  end

  def self.percentage(count, total_count)
    total_count > 0 && (count/total_count.to_f*100).round(2) || 0
  end

  def self.speed_comparison_data(submissions, test_type)
    attribute_name = speed_attribute(test_type)
    total_count = submissions.count
    mlab_tests_count = submissions.from_mlab.count
    less_than_5 = percentage(submissions.where("#{attribute_name}": [0..5]).count, total_count)
    less_than_25 = percentage(submissions.where("#{attribute_name}": [0..25]).count, total_count)
    faster_than_100 = percentage(submissions.where("#{attribute_name} >?", 100).count, total_count)
    faster_than_250 = percentage(submissions.where("#{attribute_name} >?", 250).count, total_count)

    { less_than_5: less_than_5, less_than_25: less_than_25, faster_than_100: faster_than_100, faster_than_250: faster_than_250, mlab_tests_count: mlab_tests_count, speedup_tests_count: total_count - mlab_tests_count }
  end

  def self.speed_breakdown_data(submissions, statistics, providers)
    speed_breakdown_ranges = ['0..5.99', '6..10.99', '11..20.99', '21..40.99', '40..60.99', '61..80.99', '81..100.99', '101..250.99', '251..500.99', '500..1000.99', '1001+']
    categories = []
    series = []

    providers.each do |provider|
      values = []
      provider_submissions = submissions.with_provider(provider)
      speed_breakdown_ranges.each do |range|
        count = count_between(provider_submissions, range, statistics[:test_type])
        categories << map_range_values(range)
        values << percentage(count, provider_submissions.count).round(2)
      end

      series << { name: provider, data: values }
    end

    { categories: categories, series: series }
  end

  def self.get_date_ranges(statistics, start_date, end_date)
    period = statistics[:period].downcase
    time_intervals = [{ name: category_name(start_date, period), range: [start_date, start_date.send("end_of_#{period}")] }]

    loop do
      return if start_date.blank? || end_date.blank?
      start_date = start_date + 1.send(period)
      break if start_date.send("end_of_#{period}") > end_date

      range = [start_date.send("beginning_of_#{period}"), start_date.send("end_of_#{period}")]
      time_intervals << { name: category_name(start_date, period), range: range }
    end

    time_intervals << { name: category_name(end_date, period), range: [end_date.send("beginning_of_#{period}"), end_date] }

    time_intervals
  end

  def self.speed_attribute(test_type)
    test_type == 'upload' && 'actual_upload_speed' || 'actual_down_speed'
  end

  def self.median_speed_with_range(submissions, provider, range, test_type)
    submissions = submissions.with_date_range(range[0], range[1]).with_provider(provider)
    attribute_name = speed_attribute(test_type)
    median(submissions.map(&:"#{attribute_name}")) if submissions.present?
  end

  def self.tests_count_with_range(submissions, provider, range, test_type)
    submissions.with_date_range(range[0], range[1]).with_provider(provider).count if submissions.present?
  end

  def self.category_name(date, period)
    if period == 'day'
      [date.day, date.strftime('%B')].join(' ')
    elsif period == 'month'
      [date.strftime('%B'), date.year].join(' ')
    elsif period == 'year'
      date.year
    end
  end

  def self.isps_tests_data(submissions, statistics, providers, date_ranges, categories)
    median_speed_series = []
    tests_count_series = []

    providers.each do |provider|
      median_speed_values = []
      tests_count_values = []
      date_ranges.each do |date_range|
        median_speed_values << median_speed_with_range(submissions, provider, date_range[:range], statistics[:test_type]).to_f
        tests_count_values << tests_count_with_range(submissions, provider, date_range[:range], statistics[:test_type]).to_f
      end
      median_speed_series << { name: provider, data: median_speed_values }
      tests_count_series << { name: provider, data: tests_count_values }
    end

    {
      median_data: { categories: categories, series: median_speed_series },
      tests_count_data: { categories: categories, series: tests_count_series },
    }
  end

  def self.internet_stats_data(statistics)
    date_range = statistics[:date_range].to_s.split(' - ')
    start_date, end_date = Time.parse(date_range[0]), Time.parse(date_range[1]) if date_range.present?
    statistics[:provider] = ProviderStatistic.pluck(:id) if statistics[:provider] == ['all']
    statistics[:zip_code] = ZIP_CODES if statistics[:zip_code] == ['all']
    statistics[:census_code] = CENSUS_CODES if statistics[:census_code] == ['all']
    providers = ProviderStatistic.where(id: statistics[:provider]).pluck(:name)
    date_ranges = get_date_ranges(statistics, start_date, end_date)
    categories = date_ranges.collect { |range| range[:name] }

    submissions = self.in_zip_code_list
    total_tests = Submission.in_zip_code_list.count
    submissions = submissions.with_date_range(start_date, end_date)  if date_range.present?
    submissions = submissions.with_test_type(statistics[:test_type]) if statistics[:test_type].present?
    submissions = submissions.with_zip_code(statistics[:zip_code])
    submissions = submissions.with_census_code(statistics[:census_code])
    submissions = submissions.where(provider: providers)

    {
      speed_comparison_data: speed_comparison_data(submissions, statistics[:test_type]),
      speed_breakdown_chart_data: speed_breakdown_data(submissions, statistics, providers),
      median_speed_chart_data: isps_tests_data(submissions, statistics, providers, date_ranges, categories)[:median_data],
      tests_count_data: isps_tests_data(submissions, statistics, providers, date_ranges, categories)[:tests_count_data],
      total_tests: total_tests,
    }
  end

  def self.average_speed_by_zipcode(submissions)
    average_speeds = {}
    zip_codes = submissions.pluck(:zip_code).uniq

    zip_codes.each do |zip_code|
      zip_code_submissions = submissions.where(zip_code: zip_code)
      average = (zip_code_submissions.pluck(:actual_down_speed).sum/zip_code_submissions.count.to_f).round(2)
      average_speeds[zip_code] = average
    end

    average_speeds.sort_by { |k, v| v }
  end

  def self.service_providers_data(type, categories, connection_type, provider)
    submissions = in_zip_code_list
    return service_providers_usage_data(categories, connection_type, submissions) if type == 'isps_usage'
    return service_providers_satisfactions_data(categories, connection_type, provider, submissions) if type == 'isps_satisfactions'
    return mobile_service_providers_data(categories, connection_type, type, submissions) if type.in?(['mobile_isps_speeds', 'mobile_isps_satisfactions'])
  end

  def self.service_providers_usage_data(categories, connection_type, submissions)
    usage_percentages = []
    submissions = submissions.with_connection_type(connection_type)

    categories.each do |category|
      if category == 'Other'
        isps_submissions = submissions.where.not(provider: categories)
      else
        isps_submissions = submissions.with_provider(category)
      end

      entity = { name: category, y: percentage(isps_submissions.length, submissions.count) }
      usage_percentages << entity
    end

    { usage_percentages: usage_percentages }
  end

  def self.service_providers_satisfactions_data(categories, connection_type, provider, submissions)
    satisfaction_ratings = []
    if provider == 'all'
      submissions = submissions.valid_rating.with_connection_type(connection_type)
    else
      submissions = submissions.valid_rating.with_connection_type(connection_type).with_provider(provider)
    end

    categories.each do |category|
      ratings = submissions.with_rating(satisfactions_mapping(category)).pluck(:rating)
      entity = { name: category, y: percentage(ratings.count, submissions.count) }
      satisfaction_ratings << entity
    end

    satisfaction_ratings
  end

  def self.mobile_service_providers_data(categories, connection_type, type, submissions)
    values = []
    submissions = submissions.with_connection_type(connection_type)

    categories.each do |category|
      if type == 'mobile_isps_speeds'
        provider_submissions = submissions.with_provider(category)
        value = (provider_submissions.pluck(:actual_down_speed).sum/provider_submissions.count.to_f).round(2)
      elsif type == 'mobile_isps_satisfactions'
        provider_submissions = submissions.valid_rating.with_provider(category)
        value = (provider_submissions.with_provider(category).pluck(:rating).sum/provider_submissions.count.to_f).round(2)
      end

      values << value
    end

    { categories: categories, values: values }
  end

  def self.satisfactions_mapping(value)
    {
      'Negative' => [0..3.99],
      'Neutral'  => [4..5.99],
      'Positive' => [6..7],
    }[value]
  end

  def invalid_test_result
    testing_for == 'Mobile Data' && actual_down_speed > 50
  end

  def get_actual_to_provider_difference(actual_speed_sum, provider_speed_sum)
    (actual_speed_sum - provider_speed_sum).to_f / provider_speed_sum
  end

  def calculate_average(new_value, old_value, old_count)
    (new_value + (old_value * old_count).to_f) / (old_count + 1)
  end

  def self.int_to_ip(num)
    IPAddress(num.to_i).address
  end

  def get_provider
    ipa = from_mlab? && Submission.int_to_ip(ip_address) || ip_address
    provider_obj = GeoIP.new('GeoIPASNum.dat').asn(ipa)
    Submission.provider_mapping(provider_obj.asn) if provider_obj.present?
  end

  def self.stats_data
    all_results = get_all_results
    home_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:home_wifi])
    mobile_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:mobile_data])
    public_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:public_wifi])
    total_submissions = in_zip_code_list.count
    home_avg_speed_by_zipcode = average_speed_by_zipcode(home_submissions)

    [all_results, home_submissions, mobile_submissions, public_submissions, total_submissions, home_avg_speed_by_zipcode]
  end

  def source
    from_mlab && 'MLab' || 'SpeedUp'
  end
end
