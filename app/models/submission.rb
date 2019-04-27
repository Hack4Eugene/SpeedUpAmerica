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
    'Response #', 'Source', 'Day', 'Time', 'How Are You Testing', 'Zip', 'Census Tract', 'Provider', 'How are you connected', 'Price Per Month', 'Advertised Download Speed', 'Satisfaction Rating', 'Download Speed', 'Upload Speed', 'Advertised Price Per Mbps', 'Actual Price Per Mbps', 'Ping'
  ]

  ZIP_CODES = [
    '97405', '97401', '97424', '97403', '97439', '97463', '97438',
    '97493', '97492', '97402', '97452', '97477', '97404', '97426',
    '97487', '97408', '97448', '97478'
  ]

  UAIs = ['0458997', '458970', '458971', '458972', '458973', '458974', '458975', '458976', '459086', '459091', '458977', '458978', '459037', '458913', '458915', '459090', '459088', '459052', '458914', '459092', '459089', '459082', '459041', '459038', '459085', '459093', '459039', '458912', '458986', '459072', '459073', '459074', '459075', '458959', '458960', '458961', '458998', '459079', '458962', '458963', '458979', '458980', '458981', '458982', '458983', '459053', '459055', '459054', '459087', '459114', '459113', '459115', '459047', '459043', '459078', '459080', '459044', '458984', '459045', '459112', '458994', '459017', '458993', '459016', '459050', '459081', '459018', '459019', '458985', '458992', '459051', '459076', '459116', '459083', '458991', '458989', '458990', '458988', '459049', '458964', '459006', '459046', '459077', '459042', '458965', '458999', '459007', '459008', '459009', '459010', '459011', '459012', '459013', '459014', '459015', '459029', '459030', '459031', '459032', '459033', '459034', '459035', '459036', '459084', '458987', '459063', '459064', '459065', '459066', '459067', '459068', '459069', '459070', '459071', '459102', '459103', '459040', '459000', '459001', '459002', '459003', '459004', '458966', '459020', '459021', '459022', '459023', '459024', '458967', '459025', '459026', '459027', '459028', '459056', '459057', '458968', '459058', '459059', '459060', '459061', '459062', '459095', '459096', '459097', '459098', '459099', '459100', '459101', '458919', '458920', '458969', '458921', '459104', '459105', '458922', '458923', '459106', '459107', '458918', '459108', '459048', '459109', '459110', '459111', '459117', '459118', '459119', '459120', '459121', '459122', '458995', '458925', '458926', '458927', '458928', '458929', '458930', '458931', '458952', '458996', '458924', '459005', '458917', '458916', '458953', '458954', '458955', '458956', '458957', '459094', '458958']

  CENSUS_CODES = ['1000', '10001', '10004', '10005', '10006', '10007', '10008', '10102', '10103', '10104', '10307', '10309', '10311', '10312', '10313', '10314', '10315', '10316', '10317', '10318', '10319', '10320', '10402', '10403', '10405', '10406', '10500', '10601', '10602', '10701', '10702', '10705', '10706', '10800', '10901', '10902', '1100', '11002', '11003', '11004', '11005', '11102', '11106', '11109', '11110', '11111', '11112', '11113', '11114', '11200', '11301', '11302', '11403', '11404', '11405', '11406', '11505', '11506', '11508', '11509', '11513', '11514', '11515', '11516', '11517', '11518', '11519', '11520', '11601', '11603', '11604', '11706', '11707', '11708', '11709', '11710', '11711', '11712', '11713', '11800', '11901', '11904', '11905', '11906', '11907', '1200', '12001', '12002', '12003', '12103', '12104', '12105', '12106', '12107', '12202', '12203', '12204', '12301', '12302', '12406', '12407', '12408', '12409', '12410', '12411', '12501', '12502', '12503', '12601', '12603', '12604', '12701', '12702', '12703', '12801', '12802', '13100', '1400', '1500', '1600', '1700', '1800', '200', '2100', '2300', '2400', '2700', '2800', '300', '3000', '3500', '3600', '3700', '3800', '3900', '400', '4000', '4100', '4301', '4302', '4400', '4500', '4600', '4900', '5000', '5100', '5200', '5300', '5600', '5900', '600', '6200', '6300', '6400', '6500', '6600', '6800', '6900', '700', '7000', '7100', '7400', '7501', '7502', '7601', '7602', '7603', '7700', '7800', '7900', '800', '8100', '8200', '8300', '8400', '8500', '8700', '8800', '8900', '900', '9000', '9103', '9105', '9106', '9300', '9400', '9600', '9700', '9800', '980100', '9900']

  validates :testing_for, length: { maximum: 20 }
  validates :provider, :connected_with, length: { maximum: 50 }

  after_create :update_provider_statistics, if: Proc.new { |submission| submission.provider.present? },
                                            unless: :invalid_test_result
  after_create :update_median_speeds_and_census

  default_scope { where('from_mlab = 0 OR (from_mlab = 1 AND provider IS NOT NULL)') }

  scope :mapbox_filter, -> (test_type) { in_zip_code_list.with_test_type(test_type).select('latitude, longitude, zip_code, actual_down_speed, actual_upload_speed, upload_median, download_median') }
  scope :mapbox_filter_by_zip_code, -> (test_type) { in_zip_code_list.with_test_type(test_type).select('zip_code, actual_down_speed, actual_upload_speed').group_by(&:zip_code) }
  scope :with_date_range, -> (start_date, end_date) { where('created_at >= ? AND created_at <= ?', start_date, end_date.end_of_day) }
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
    duplicate_ipa_tests = Submission.where('DATE(created_at) = ? AND ip_address = ?', Date.today, params[:ip_address])

    submission = Submission.new(params)

    if submission.monthly_price.present? && submission.provider_down_speed.present? && submission.actual_down_speed.present?
      submission.provider_price = submission.monthly_price / submission.provider_down_speed
      submission.actual_price = submission.monthly_price / submission.actual_down_speed
    end

    submission.test_type = 'duplicate' if duplicate_ipa_tests.present?
    submission.completed = true if submission.valid_attributes?
    submission.test_id = [Time.now.utc.to_i, SecureRandom.hex(10)].join('_')
    submission.provider = submission.get_provider
    submission.save
    submission
  end

  def valid_attributes?
    has_required_fields? && valid_zip_code?
  end

  def valid_zip_code?
    ZIP_CODES.include?(zip_code)
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

    boundaries = Rails.cache.fetch('zip_boundaries', expires_in: 2.hours) do
      zip_boundaries = {}
      ZipBoundary.where(name: ZIP_CODES).each do |zip|
        zip_boundaries[zip.name] = { zip_type: zip.zip_type, bounds: zip.bounds }
      end
      zip_boundaries
    end

    polygon_data.each do |zip_code, submissions|
      attribute_name = speed_attribute(params[:test_type])
      median_speed  = median(submissions.map(&:"#{attribute_name}")).to_f
      zip_boundary = boundaries[zip_code]

      if zip_boundary.present?
        zip_coordinates = zip_boundary[:bounds]
        zip_type = zip_boundary[:zip_type]
      else
        begin
          zip_json = Timeout::timeout(2) do
            JSON.parse(agent.get(zip_json_url(zip_code)).body)
          end

          next if zip_json['features'].blank?

          zip_coordinates = zip_json['features'].first['geometry']['coordinates']
          zip_type = zip_json['features'].first['geometry']['type']

          zip = ZipBoundary.first_or_initialize(name: zip_code, zip_type: zip_type)
          zip.bounds = zip_coordinates
          zip.save
        rescue Timeout::Error
          next
        end
      end

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
    polygon_data = polygon_data.with_zip_code(params[:zip_code]) if params[:zip_code].present?
    polygon_data = polygon_data.with_census_code(params[:census_code]) if params[:census_code].present?
    polygon_data = polygon_data.mapbox_filter_by_census_code(params[:test_type]) if params[:test_type].present?

    boundaries = Rails.cache.fetch('census_boundaries', expires_in: 2.hours) do
      census_boundaries = {}
      CensusBoundary.where(area_identifier: UAIs).each do |boundary|
        census_boundaries[boundary.name.to_i.to_s] = { bounds: boundary.bounds }
      end
      census_boundaries
    end

    polygon_data.each do |census_code, submissions|
      attribute_name = speed_attribute(params[:test_type])
      median_speed  = median(submissions.map(&:"#{attribute_name}")).to_f
      census_boundary = boundaries[census_code.to_s]

      if census_boundary.present?
        census_coordinates = census_boundary[:bounds]
      else
        census_coordinates = CensusBoundary.first.bounds
      end

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
                    'type': 'Polygon',
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

      fips = response['Block']['FIPS']
      self.assign_attributes(census_code: fips[5..-5].to_i, census_status: CENSUS_STATUS[:saved]) if fips.present?
    rescue
      self.census_status = CENSUS_STATUS[:pending]
    end
  end

  def self.census_tract_url(lat, long)
    "http://data.fcc.gov/api/block/find?format=json&latitude=#{lat}&longitude=#{long}"
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
                    submission.id, submission.source, submission.created_at.strftime('%B %d, %Y'), submission.created_at.in_time_zone('EST').strftime('%R %Z'), testing_for_mapping(submission.testing_for), submission.zip_code, submission.census_code, submission.provider, submission.connected_with, submission.monthly_price, submission.provider_down_speed, submission.rating, submission.actual_down_speed, submission.actual_upload_speed, submission.provider_price, submission.actual_price, submission.ping
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

  def update_median_speeds_and_census
    upload_speeds = Submission.where(latitude: latitude, longitude: longitude).pluck(:actual_upload_speed)
    download_speeds = Submission.where(latitude: latitude, longitude: longitude).pluck(:actual_down_speed)
    self.upload_median = Submission.median upload_speeds
    self.download_median = Submission.median download_speeds
    self.set_census_code(latitude, longitude)

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
