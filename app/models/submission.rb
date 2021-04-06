class Submission < ActiveRecord::Base
  extend ActionView::Helpers::NumberHelper
  require 'csv'

  ISP_DB = MaxMindDB.new('GeoLite2-ASN.mmdb')
  MOBILE_MAXIMUM_SPEED = 50

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

  #TODO we can't keep storing these, we need to replace all usage with a endpoint for searching boundaries
  ZIP_CODES = Boundaries.where(:boundary_type => "zip_code", :enabled => true).pluck(:boundary_id)
  CENSUS_TRACTS = Boundaries.where(:boundary_type => "census_tract", :enabled => true).pluck(:boundary_id)

  SPEED_BREAKDOWN_RANGES = [
    '0..5.99', '6..10.99', '11..20.99', '21..40.99', '40..60.99', '61..80.99', '81..100.99',
    '101..250.99', '251..500.99', '500..1000.99', '1001+'
  ]

  SPEED_BREAKDOWN_COLUMNS = [
    '0_5', '6_10', '11_20', '21_40', '40_60', '61_80', '81_100',
    '101_250', '251_500', '500_1000', '1001'
  ]

  validates :location, length: { maximum: 20 }
  validates :testing_for, length: { maximum: 20 }
  validates :connected_with, length: { maximum: 50 }
  validates :provider, length: { maximum: 255 }

  default_scope { where('from_mlab = 0 OR (from_mlab = 1 AND provider IS NOT NULL)') }

  scope :with_date_range, -> (start_date, end_date) { where('test_date >= ? AND test_date <= ?', start_date, end_date.end_of_day) }
  scope :with_test_type, -> (test_type) { where(test_type: [test_type, 'both']) }
  scope :valid_test, -> { where.not(test_type: 'duplicate') }
  scope :invalid_test, -> { where('testing_for = ? AND actual_down_speed > ?', 'Mobile Data', MOBILE_MAXIMUM_SPEED) }
  scope :with_connection_type, -> (connection_type) { where(testing_for: connection_type) }
  scope :with_type_and_lower_speed, -> (type, down_speed) { where('testing_for =? AND actual_down_speed < ?', type, down_speed) }
  scope :with_provider, -> (provider) { where(provider: provider) }
  scope :with_zip_code, -> (zip_code) { where(zip_code: zip_code) }
  scope :with_rating, -> (rating) { where(rating: rating) }
  scope :valid_rating, -> { where('rating > 0') }
  scope :from_mlab, -> { where(from_mlab: true) }
  scope :not_from_mlab, -> { where(from_mlab: false) }
  scope :with_census_code, -> (census_code) { where(census_code: census_code) }

  scope :mapbox_filter_by_boundary, -> (boundary_type, test_type) {
    subs = valid_test.with_test_type(test_type)

    if boundary_type == 'census_code'
      subs = subs.joins("LEFT JOIN boundaries b ON b.boundary_type = 'census_tract' AND submissions.census_code = b.boundary_id")
      subs = subs.where('b.enabled = true')
      subs.select('census_code, actual_down_speed, actual_upload_speed').group_by(&:census_code)
    elsif boundary_type == 'census_block'
      subs = subs.joins("LEFT JOIN boundaries b ON b.boundary_type = 'census_block' AND submissions.census_block = b.boundary_id")
      subs = subs.where('b.enabled = true')
      subs.select('census_block, actual_down_speed, actual_upload_speed').group_by(&:census_block)
    elsif boundary_type == 'zip_code'
      subs = subs.joins("LEFT JOIN boundaries b ON b.boundary_type = 'zip_code' AND submissions.zip_code = b.boundary_id")
      subs = subs.where('b.enabled = true')
      subs.select('zip_code, actual_down_speed, actual_upload_speed').group_by(&:zip_code)
    else
      raise 'unknown boundary type: ' + boundary_type
    end
  }

  scope :get_provider_for_stats_cache, -> (provider, test_type) { where(provider: provider).with_test_type(test_type) }

  def self.create_submission(params)
    duplicate_ipa_tests = Submission.where('test_date = ? AND ip_address = ?', Date.today, params[:ip_address])

    submission = Submission.new(params)

    if submission.monthly_price.present? && submission.provider_down_speed.present? && submission.actual_down_speed.present? &&
       submission.provider_down_speed > 0 && submission.monthly_price > 0 && submission.actual_down_speed > 0
      submission.provider_price = submission.monthly_price / submission.provider_down_speed
      submission.actual_price = submission.monthly_price / submission.actual_down_speed
    end

    submission.test_date = Date.today
    submission.test_type = 'duplicate' if duplicate_ipa_tests.present?
    submission.completed = true
    submission.test_id = [Time.now.utc.to_i, SecureRandom.hex(10)].join('_')
    submission.provider = submission.get_provider
    submission.save

    submission.populate_location
    submission.populate_boundaries

    submission
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

  def location
  end

  def self.fetch_tileset_groupby(params)
    providers = provider_names(params[:provider])
    params[:zip_code] = [] if params[:zip_code] == ['all']
    params[:census_code] = [] if params[:census_code] == ['all']

    if params[:zip_code].present? || params[:census_code].present? || providers.present?
      from_cache = false
      stats = calculate_tileset_groupby(params, providers)
    else
      from_cache = true
      stats = cached_tileset_groupby(params[:group_by], params[:test_type])
    end

    {
      'status': 'ok',
      'params': params,
      'result': stats,
      'from_cache': from_cache
    }
  end

  def self.calculate_tileset_groupby(params, providers)
    polygon_data = valid_test
    polygon_data = polygon_data.where(provider: providers)              if providers.present? && providers.any?
    polygon_data = polygon_data.mapbox_filter_by_boundary(params[:group_by], params[:test_type])

    stats = polygon_data.map do |id, submissions|
      attribute_name = speed_attribute(params[:test_type])
      median_speed  = median(submissions.map(&:"#{attribute_name}")).to_f

      {
        'id': id,
        'all_median': median_speed,
        'all_count': number_with_delimiter(submissions.length, delimiter: ','),
        'all_fast': '%.2f' % submissions.map(&:"#{attribute_name}").compact.max.to_f,
        'color': set_color(median_speed),
        'fillOpacity': 0.6,
      }
    end

    stats
  end

  def self.cached_tileset_groupby(group_by, test_type)
    # Deal with census tract being poorly named in the rest of the code base
    if group_by == 'census_code'
      group_by = 'census_tract'
    end

    stats = StatsCache.where(:stat_type => group_by, :date_type => 'all')

    results = []
    stats.each do |stats|
      result = {
        'id': stats.stat_id,
        'fillOpacity': 0.6,
      }

      if test_type == 'download'
        next if stats.download_count == 0

        result[:all_avg] = stats.download_avg
        result[:all_median] = stats.download_median
        result[:all_fast] = stats.download_max
        result[:all_count] = stats.download_count
      else
        next if stats.upload_count == 0

        result[:all_avg] = stats.upload_avg
        result[:all_median] = stats.upload_median
        result[:all_fast] = stats.upload_max
        result[:all_count] = stats.upload_count
      end

      result[:color] = set_color(result[:all_median])

      results << result
    end

    results
  end

  def self.provider_names(provider_ids)
    return [] if provider_ids == ['all']
    ProviderStatistic.where(id: provider_ids).pluck(:name)
  end

  def self.median(array)
    sorted = array.compact.sort
    len = sorted.length
    ((sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0).round(4) if sorted.present?
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
      when 0..10.9999999999 then '#D73027'
      when 11..50.9999999999 then '#FDAE61'
      when 51..100.9999999999 then '#A6D96A'
      when 101..250.9999999999 then '#A6D96A'
      when 251..500.9999999999 then '#1A9641'
      when 501..1000.9999999999 then '#1A9641'
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

  CSV_COLUMNS = [
    'Response #', 'Source', 'Date', 'How Are You Testing', 'Zip', 'Census Tract', 'Census Block',
    'Provider', 'How are you connected', 'Price Per Month', 'Advertised Download Speed',
    'Satisfaction Rating', 'Download Speed', 'Upload Speed', 'Advertised Price Per Mbps',
    'Actual Price Per Mbps', 'Ping'
  ]

  CSV_KEYS = [
    :id, :source, :date, :testing_for, :zip_code, :census_code, :census_block, :provider, :connected_with,
    :monthly_price, :provider_down_speed, :rating,:actual_down_speed, :actual_upload_speed,
    :provider_price, :actual_price, :ping
  ]

  def self.csv_header
    #Using ruby's built-in CSV::Row class
    #true - means its a header
    CSV::Row.new(CSV_KEYS, CSV_COLUMNS, true)
  end

  def to_csv_row
    CSV::Row.new(CSV_KEYS, [id, source, test_date.strftime('%B %d, %Y'), Submission::testing_for_mapping(testing_for),
      zip_code, census_code, census_block, provider, connected_with, monthly_price, provider_down_speed, rating, actual_down_speed,
      actual_upload_speed, provider_price, actual_price, ping])
  end

  def self.find_in_batches(date_range)
    start_date = Date.today.at_beginning_of_month - 13.months
    end_date = Date.today

    data = not_from_mlab.with_date_range(start_date, end_date)
    data.find_each(batch_size: 1000) do |transaction|
      yield transaction
    end
  end

  BOUNDARY_TYPE_TO_SUBS_COLUMN = {
    'region' => 'region',
    'county' => 'county',
    'zip_code' => 'zip_code',
    'census_tract' => 'census_code',
    'census_block' => 'census_block',
  }

  def self.find_for_boundary(type, id)
    if BOUNDARY_TYPE_TO_SUBS_COLUMN.key?(type) == false
      raise 'boundary type not supported'
    end

    column = BOUNDARY_TYPE_TO_SUBS_COLUMN[type]
    quoted_column = Submission.connection.quote_column_name(column)
    Submission.where("#{quoted_column} = ?", id)
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
      'Cellco Partnership DBA Verizon Wireless' => 'Verizon Wireless',
      'MCI Communications Services, Inc. d/b/a Verizon Business' => 'Verizon Business',
      'Online Northwest' => 'XS Media',
    }[provider]

    original_provider.present? && original_provider || provider
  end

  def self.filter_rating(rating)
    (rating * 2).ceil.to_f / 2
  end

  def self.amount_to_percentage(amount)
    amount * 100
  end

  def self.internet_stats_data(statistics)
    start_date = Date.today - 1.year
    end_date = Date.today
    date_ranges = get_date_ranges('month', start_date, end_date)
    categories = date_ranges.collect { |range| range[:name] }

    providers = ProviderStatistic.where(id: statistics[:provider]).pluck(:name)

    statistics[:provider] = ProviderStatistic.pluck(:id) if statistics[:provider] != ['all']
    statistics[:zip_code] = [] if statistics[:zip_code] == ['all']
    statistics[:census_code] = [] if statistics[:census_code] == ['all']

    if statistics[:zip_code].present? || statistics[:census_code].present?
      results = calculate_speed_data(statistics, providers, start_date, end_date, date_ranges)
    else
      results = cached_speed_data(statistics, providers, start_date, end_date, date_ranges)
    end

    results
  end

  def self.calculate_speed_data(params, providers, start_date, end_date, date_ranges)

    submissions = self.valid_test
    submissions = submissions.with_date_range(start_date, end_date)  if date_ranges.present?
    submissions = submissions.with_test_type(params[:test_type]) if params[:test_type].present?
    submissions = submissions.with_zip_code(params[:zip_code])   if params[:zip_code].present? && params[:zip_code].any?
    submissions = submissions.with_census_code(params[:census_code]) if params[:census_code].present? && params[:census_code].any?
    submissions = submissions.where(provider: providers)
    # submissions = submissions.where(from_mlab: 1)

    test_type = params[:test_type]
    categories = date_ranges.collect { |range| range[:name] }

    isps_data = isps_tests_data(submissions, test_type, providers, date_ranges, categories)

    {
      speed_comparison_data: calculate_speed_comparison_data(submissions, test_type),
      speed_breakdown_chart_data: calculate_speed_breakdown_data(submissions, test_type, providers),
      median_speed_chart_data: isps_data[:median_data],
      tests_count_data: isps_data[:tests_count_data],
      from_cache: false,
    }
  end

  def self.cached_speed_data(params, providers, start_date, end_date, date_ranges)
    stats = StatsCache.where(:stat_type => 'provider', :stat_id => providers, :date_type => 'all').to_a

    test_type = params[:test_type]
    categories = date_ranges.collect { |range| range[:name] }

    speed_comparison_data = cached_speed_comparison_data(stats, test_type)
    speed_breakdown_chart_data = cached_speed_breakdown_data(stats, test_type, providers)
    isps_tests_data = cached_isps_tests_data(test_type, providers, date_ranges, categories)

    {
      speed_comparison_data: speed_comparison_data,
      speed_breakdown_chart_data: speed_breakdown_chart_data,
      median_speed_chart_data: isps_tests_data[:median_data],
      tests_count_data: isps_tests_data[:tests_count_data],
      from_cache: true,
    }
  end

  def self.calculate_speed_comparison_data(submissions, test_type)
    attribute_name = speed_attribute(test_type)
    total_count = submissions.count
    mlab_tests_count = submissions.from_mlab.count

    less_than_5 = percentage(submissions.where("#{attribute_name}": [0..5]).count, total_count)
    less_than_25 = percentage(submissions.where("#{attribute_name}": [0..25]).count, total_count)
    faster_than_100 = percentage(submissions.where("#{attribute_name} >?", 100).count, total_count)
    faster_than_250 = percentage(submissions.where("#{attribute_name} >?", 250).count, total_count)

    {
      speedup_tests_count: total_count - mlab_tests_count,
      mlab_tests_count: mlab_tests_count,

      less_than_5: less_than_5,
      less_than_25: less_than_25,
      faster_than_100: faster_than_100,
      faster_than_250: faster_than_250,
    }
  end

  def self.cached_speed_comparison_data(stats, test_type)
    total_count = stats.map(&:"#{test_type}_count").inject(0){|sum, x| sum + x }
    sua_count = stats.map(&:"#{test_type}_sua_count").inject(0){|sum, x| sum + x }

    less_than_5 = Submission.percentage(stats.map(&:"#{test_type}_less_than_5").inject(0){|sum, x| sum + x }, total_count)
    less_than_25 = Submission.percentage(stats.map(&:"#{test_type}_less_than_25").inject(0){|sum, x| sum + x }, total_count)
    faster_than_100 = Submission.percentage(stats.map(&:"#{test_type}_faster_than_100").inject(0){|sum, x| sum + x }, total_count)
    faster_than_250 = Submission.percentage(stats.map(&:"#{test_type}_faster_than_250").inject(0){|sum, x| sum + x }, total_count)

    {
      speedup_tests_count: sua_count,
      mlab_tests_count: total_count - sua_count,

      less_than_5: less_than_5,
      less_than_25: less_than_25,
      faster_than_100: faster_than_100,
      faster_than_250: faster_than_250,
    }
  end

  def self.calculate_speed_breakdown_data(submissions, test_type, providers)
    categories = get_speed_ranges()
    series = []

    providers.each do |provider|
      provider_submissions = submissions.with_provider(provider)
      values = speed_breakdown(test_type, provider_submissions)
      series << { name: provider, data: values }
    end

    { categories: categories, series: series }
  end

  def self.cached_speed_breakdown_data(stats, test_type, providers)
    categories = get_speed_ranges()
    series = []

    stats.each do |stats|
      values = []

      SPEED_BREAKDOWN_RANGES.each_with_index do |range, index|
        column = SPEED_BREAKDOWN_COLUMNS[index]
        values << stats["#{test_type}_#{column}"]
      end

      series << { name: stats.stat_id, data: values }
    end

    { categories: categories, series: series }
  end

  def self.isps_tests_data(submissions, test_type, providers, date_ranges, categories)
    median_speed_series = []
    tests_count_series = []

    providers.each do |provider|
      median_speed_values = []
      tests_count_values = []
      date_ranges.each do |date_range|
        rangedSubmission = submissions.with_date_range(date_range[:range][0], date_range[:range][1]).with_provider(provider)
        attribute_name = speed_attribute(test_type)
        rangedMedian = median(rangedSubmission.map(&:"#{attribute_name}")) if rangedSubmission.present?
        rangedCount = rangedSubmission.size if rangedSubmission.present?

        median_speed_values << rangedMedian.to_f
        tests_count_values << rangedCount.to_f
      end
      median_speed_series << { name: provider, data: median_speed_values }
      tests_count_series << { name: provider, data: tests_count_values }
    end

    {
      median_data: { categories: categories, series: median_speed_series },
      tests_count_data: { categories: categories, series: tests_count_series },
    }
  end

  def self.cached_isps_tests_data(test_type, providers, date_ranges, categories)
    median_speed_series = []
    tests_count_series = []

    providers.each do |provider|
      median_speed_values = []
      tests_count_values = []

      date_ranges.each do |date_range|
        monthly_stats = StatsCache.where(:stat_type => 'provider', :stat_id => provider, :date_type => 'month',
          :date_value => date_range[:range][0].at_beginning_of_month).take

        if monthly_stats.nil?
          median_speed_values = 0
          tests_count_values = 0
        else
          median_speed_values << monthly_stats["#{test_type}_median"]
          tests_count_values << monthly_stats["#{test_type}_count"]
        end
      end

      median_speed_series << { name: provider, data: median_speed_values }
      tests_count_series << { name: provider, data: tests_count_values }
    end

    {
      median_data: { categories: categories, series: median_speed_series },
      tests_count_data: { categories: categories, series: tests_count_series },
    }
  end

  def self.get_date_ranges(period, start_date, end_date)
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

  def self.category_name(date, period)
    if period == 'day'
      [date.day, date.strftime('%B')].join(' ')
    elsif period == 'month'
      [date.strftime('%B'), date.year].join(' ')
    elsif period == 'year'
      date.year
    end
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

  def self.speed_breakdown(test_type, provider_submissions)
    SPEED_BREAKDOWN_RANGES.map do |range|
      count = count_between(provider_submissions, range, test_type)
      percentage(count, provider_submissions.count)
    end
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
    total_count > 0 && (count/total_count.to_f*100).round(2) || 0.00
  end

  def self.get_speed_ranges()
    categories = []
    SPEED_BREAKDOWN_RANGES.each do |range|
      categories << map_range_values(range)
    end

    categories
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
    result = ISP_DB.lookup(ip_address)
    Submission.provider_mapping(result["autonomous_system_organization"]) if result.found?
  end

  def populate_location
    conn = ActiveRecord::Base.connection
    conn.execute("UPDATE submissions SET location = POINT(longitude, latitude) WHERE id = #{id}")
  end

  def populate_boundaries
    conn = ActiveRecord::Base.connection
    query = "SELECT boundary_type, boundary_id FROM boundaries WHERE "\
      "ST_Contains(geometry, (SELECT location FROM submissions WHERE id = #{id} LIMIT 1));"
    result = conn.select_rows(query)

    result.each do |row|
      case row[0]
      when 'region'
        self.assign_attributes(:region => row[1])
        self.assign_attributes(:country_code => 'US')
      when 'county'
        self.assign_attributes(:county => row[1])
      when 'zip_code'
        self.assign_attributes(:zip_code => row[1])
      when 'census_tract'
        self.assign_attributes(:census_code => row[1])
      when 'census_block'
        self.assign_attributes(:census_block => row[1])
      end
    end

    self.save()
  end

  def source
    from_mlab && 'MLab' || 'SpeedUp'
  end

  def to_param #overridden
    test_id
  end

end
