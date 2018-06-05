class Submission < ActiveRecord::Base
  extend ActionView::Helpers::NumberHelper
  require 'csv'

  obfuscate_id spin: 81238123
  MOBILE_MAXIMUM_SPEED = 50

  MAP_FILTERS = {
                  connection_type: {
                                      home_wifi: 'Home Wifi',
                                      mobile_data: 'Mobile Data',
                                      public_wifi: 'Public Wifi',
                                      commercial_data: 'Commercial Data',
                                      all: ['Home Wifi', 'Mobile Data', 'Public Wifi', 'Commercial Data'],
                                   },

                  group_by: {
                              zip_code: 'zip_code',
                              all_responses: 'all_responses'
                            }
                }

  CSV_COLUMNS = [
                  'Response #', 'Day', 'Time', 'Type of internet tested', 'Zip', 'Provider', 'How are you connected','What kind or work or public connection are you testing', 'Price Per Month', 'Advertised Download Speed', 'Satisfaction Rating', 'Download Speed', 'Advertised Price Per Mbps', 'Actual Price Per Mbps', 'Upload Speed', 'ping'
                ]

  ZIP_CODES = [
                '95002', '95008', '95013', '95014', '95032', '95034', '95035', '95037', '95050', '95110', '95111', '95112', '95113', '95116', '95117', '95118', '95119', '95120', '95121', '95122', '95123', '95124', '95125', '95126', '95127', '95128', '95129', '95130', '95131', '95132', '95133', '95135', '95136', '95138', '95139', '95141', '95148'
              ]

  validates :testing_for, :actual_down_speed, presence: true
  validates :testing_for, length: { maximum: 20 }
  validates :provider, :connected_with, length: { maximum: 50 }

  after_create :update_provider_statistics, if: Proc.new { |submission| submission.completed? },
                                            unless: :invalid_test_result

  scope :mapbox_filter, -> (connection_type, satisfaction) { valid_test.where(testing_for: connection_type, rating: satisfaction) }
  scope :mapbox_filter_for_markers, -> (connection_type, satisfaction) { mapbox_filter(connection_type, satisfaction).in_zip_code_list.where.not(latitude: nil, longitude: nil).select('latitude, longitude, actual_down_speed, testing_for, rating') }
  scope :mapbox_filter_by_zip_code, -> (connection_type, satisfaction) { mapbox_filter(connection_type, satisfaction).in_zip_code_list.where.not(zip_code: [nil, '']).select('zip_code, actual_down_speed').group_by(&:zip_code) }
  scope :completed, -> { where(completed: true) }
  scope :in_zip_code_list, -> { valid_test.where(zip_code: ZIP_CODES) }
  scope :valid_test, -> { where.not('testing_for = ? AND actual_down_speed > ?', 'Mobile Data', MOBILE_MAXIMUM_SPEED) }
  scope :invalid_test, -> { where('testing_for = ? AND actual_down_speed > ?', 'Mobile Data', MOBILE_MAXIMUM_SPEED) }
  scope :with_connection_type, -> (connection_type) { where(testing_for: connection_type) }
  scope :with_type_and_lower_speed, -> (type, down_speed) { where('testing_for =? AND actual_down_speed < ?', type, down_speed) }
  scope :with_provider, -> (provider) { where(provider: provider) }
  scope :with_rating, -> (rating) { where(rating: rating) }
  scope :valid_rating, -> { where('rating > 0') }

  def self.create_submission(params)
    submission = Submission.new(params)

    if submission.monthly_price.present? && submission.provider_down_speed.present? && submission.actual_down_speed.present?
      submission.provider_price = submission.monthly_price / submission.provider_down_speed
      submission.actual_price = submission.monthly_price / submission.actual_down_speed
    end

    submission.completed = true if submission.valid_attributes?
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
    else
      set_mapbox_markers_data(params)
    end
  end

  def self.set_stats_color(speed)
    case speed
      when 0..10.99 then '#A6A6A6'
      when 11..50.99 then '#D7E3BE'
      when 51..100.99 then '#94CE58'
      else '#1AAF54'
    end
  end

  def self.set_mapbox_polygon_data(params, data=[])
    agent = Mechanize.new
    Submission.mapbox_filter_by_zip_code(params[:connection_type], filter_satisfaction(params[:satisfaction])).each do |zip_code, submissions|

      average_speed = submissions.sum(&:actual_down_speed) / submissions.length
      median_speed  = median(submissions.map(&:actual_down_speed))
      zip_boundary = ZipBoundary.where(name: zip_code).first
      if zip_boundary.present?
        zip_coordinates = zip_boundary.bounds
        zip_type = zip_boundary.zip_type
      else
        zip_body = agent.get(zip_json_url(zip_code)).body
        polygon = zip_body.split("=")[0].split(" ").last == "polyStrings" ? true : false
        zip_type, zip_coordinates = zip_code_for_polygon(zip_body) if polygon
        zip_type, zip_coordinates = zip_code_for_marker(zip_body) unless polygon

        ZipBoundary.create(name: zip_code, zip_type: zip_type, bounds: zip_coordinates)
      end

      if zip_type == "Polygon"
        feature = {
                    'type': 'Feature',
                    'properties': {
                      'title': zip_code,
                      'count': number_with_delimiter(submissions.length, delimiter: ','),
                      'average_speed': '%.2f' % average_speed,
                      'median_speed': '%.2f' % median_speed,
                      'fast_speed': '%.2f' % submissions.collect(&:actual_down_speed).max,
                      'fillColor': params['type'] == 'stats' && set_stats_color(submissions.count) || set_color(median_speed),
                      'fillOpacity': 0.5,
                      'weight': 2,
                      'opacity': 1,
                      'color': params['type'] == 'stats' && set_stats_color(submissions.count) || set_color(median_speed),
                    },
                    'geometry': {
                      'type': zip_type,
                      'coordinates': zip_coordinates
                    }
                  }

        data << feature
      else
        feature = {
                  'type': 'Feature',
                  'geometry': {
                    'type': zip_type,
                    'coordinates': zip_coordinates,
                  },
                  'properties': {
                    'title': zip_code,
                    'count': number_with_delimiter(submissions.length, delimiter: ','),
                    'average_speed': '%.2f' % average_speed,
                    'median_speed': '%.2f' % median_speed,
                    'fast_speed': '%.2f' % submissions.collect(&:actual_down_speed).max,
                    'marker-color': set_color(median_speed),
                    'marker-size': 'small',
                    'marker-symbol': 'star',
                  }
                }
        data << feature
      end
    end
    data
  end

  def self.zip_code_for_marker(zip_body)
    data = zip_body.split(";")
    latitude  = data[0].split('=').last.gsub("'", '').to_f
    longitude = data[1].split(' = ').last.gsub("'", '').to_f
    ['Point', [longitude, latitude]]
  end

  def self.zip_code_for_polygon(zip_body)
    zip_coordinates = zip_body.gsub("|", ",").split("polyPoints = '").last.split("';").first.split(',')
    zip_coordinates = [zip_coordinates.map{|a|a.split(" ").map(&:to_f).to_a.reverse}]
    ['Polygon', zip_coordinates]
  end

  def self.median(array)
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def self.set_mapbox_markers_data(params, data=[])
    Submission.mapbox_filter_for_markers(params[:connection_type], filter_satisfaction(params[:satisfaction])).where(zip_code: params[:zipcode]).each do |submission|
      speed = submission.actual_down_speed

      feature = {
                  'type': 'Feature',
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [submission.longitude, submission.latitude],
                  },
                  'properties': {
                    'title': speed,
                    'connection_type': submission.testing_for,
                    'satisfaction': get_satisfaction(submission.rating),
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
      when 0..9.99 then '#C0504D'
      when 10..19.99 then '#FFFF00'
      when 20..49.99 then '#F79646'
      when 50..99.99 then '#8EB4E3'
      when 100..499.99 then '#00B050'
      when 500..999.99 then '#7030A0'
      else '#595959'
    end
  end

  def self.filter_satisfaction(value)
    case value
      when 'All'      then 0..5
      when 'Negative' then 0..2.99
      when 'Neutral'  then 3..3.99
      when 'Positive' then 4..5
    end
  end

  def self.get_satisfaction(satisfaction)
    case satisfaction
      when 0..2.99  then 'Negative'
      when 3..3.99  then 'Neutral'
      when 4..5     then 'Positive'
    end
  end

  def self.zip_json_url(zip_code)
    "http://maps.hometownlocator.com/cgi-bin/server_V3.pl?task=getZip&state=CA&mode=zip&zipcode=#{zip_code}"
  end

  def self.get_location_data(params)
    geocoder = Geocoder.search("#{params[:latitude]}, #{params[:longitude]}").first
    data =  {
              'address' => geocoder.address,
              'zip_code' => geocoder.postal_code
            }
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << CSV_COLUMNS
      in_zip_code_list.each do |submission|
        submission.rating = '' if submission.rating.zero?
        csv <<  [
                  submission.id, submission.created_at.strftime('%-m/%d/%Y'), submission.created_at.in_time_zone('EST').strftime('%R %Z'), testing_for_mapping(submission.testing_for), submission.zip_code, submission.provider, submission.connected_with, submission.internet_location, submission.monthly_price, submission.provider_down_speed, submission.rating, submission.actual_down_speed, submission.provider_price, submission.actual_price,submission.actual_upload_speed, submission.ping
                ]
      end
    end
  end

  def self.testing_for_mapping(testing_for)
    {
      'Home Wifi'   => 'Home',
      'Mobile Data' => 'Mobile',
      'Public Wifi' => 'Public',
      'Commercial Data' => 'Business',
    }[testing_for]
  end

  def update_provider_statistics
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    provider_applications = provider_statistic.applications

    provider_statistic.rating = calculate_average(rating, provider_statistic.rating, provider_applications)

    provider_statistic.actual_speed_sum += actual_down_speed
    provider_statistic.provider_speed_sum += provider_down_speed

    provider_statistic.advertised_to_actual_ratio = get_actual_to_provider_difference(provider_statistic.actual_speed_sum, provider_statistic.provider_speed_sum)

    provider_statistic.average_price = calculate_average(actual_price, provider_statistic.average_price, provider_applications)

    provider_statistic.applications += 1
    provider_statistic.save
  end

  def self.filter_rating(rating)
    (rating * 2).ceil.to_f / 2
  end

  def self.amount_to_percentage(amount)
    amount * 100
  end

  def self.map_range_values(range)
    {
      '0..5.99'     => '0 to 5 Mbps',
      '6..25.99'    => '6 to 25 Mbps',
      '26..50.99'   => '26 to 50 Mbps',
      '51..100.99'  => '51 to 100 Mbps',
      '101..200.99' => '101 to 200 Mbps',
      '201..500'    => '201 to 500 Mbps',
      '500+'        => '500+ Mbps',
      '100+'        => '100+ Mbps',

      '0..5.99'     => '0 to 5 Mbps',
      '6..10.99'    => '6 to 10 Mbps',
      '11..15.99'   => '11 to 15 Mbps',
      '16..20.99'   => '16 to 20 Mbps',
      '21..25.99'   => '21 to 25 Mbps',
      '26..30.99'   => '26 to 30 Mbps',
      '31..40.99'   => '31 to 40 Mbps',
      '41..50.99'   => '41 to 50 Mbps',
      '51..75.99'   => '51 to 75 Mbps',

      '26..99.99'   => '26 to 99 Mbps',
      '76..100.99'  => '76 to 100 Mbps',
      '101..200.99' => '101 to 200 Mbps',
      '201..300.99' => '201 to 300 Mbps',
      '301..500'    => '301 to 500 Mbps',
    }[range]
  end

  def self.count_between(submissions, range)
    if '+'.in?(range)
      lower = range.gsub('+', '').to_f
      submissions.where('actual_down_speed >= ?', lower).count
    else
      range_values = range.split('..')
      lower = range_values[0].to_f
      upper = range_values[1].to_f
      submissions.where(actual_down_speed: [lower..upper]).count
    end
  end

  def self.percentage(count, total_count)
    (count/total_count.to_f*100).round(2)
  end

  def self.download_speed_data(connection_type, ranges, provider)
    if provider.in?(['ATT', 'Comcast'])
      submissions = in_zip_code_list.with_connection_type(connection_type).with_provider(provider)
    else
      submissions = in_zip_code_list.with_connection_type(connection_type)
    end

    categories = []
    values = []

    ranges.each do |range|
      count = count_between(submissions, range)
      categories << map_range_values(range)
      values << percentage(count, submissions.count).round(2)
    end

    { categories: categories, values: values }
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

  def self.median_speed_by_zipcode(submissions)
    median_speeds = {}
    zip_codes = submissions.pluck(:zip_code).uniq

    zip_codes.each do |zip_code|
      zip_code_submissions = submissions.where(zip_code: zip_code).pluck(:actual_down_speed)
      median_speeds[zip_code] = median(zip_code_submissions).round(2)
    end

    median_speeds.sort_by { |k, v| v }
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
      'Negative' => [0..2.99],
      'Neutral'  => [3..3.99],
      'Positive' => [4..5],
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

  def self.indoor_or_outdoor(value)
    value ? 'indoor' : 'outdoor'
  end

  def self.stats_data
    all_results = get_all_results
    home_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:home_wifi])
    mobile_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:mobile_data])
    public_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:public_wifi])
    business_submissions = in_zip_code_list.with_connection_type(MAP_FILTERS[:connection_type][:commercial_data])
    total_submissions = home_submissions.count + mobile_submissions.count + public_submissions.count + business_submissions.count
    home_median_speed_by_zipcode = median_speed_by_zipcode(home_submissions)

    [all_results, home_submissions, mobile_submissions, public_submissions, business_submissions, total_submissions, home_median_speed_by_zipcode]
  end
end
