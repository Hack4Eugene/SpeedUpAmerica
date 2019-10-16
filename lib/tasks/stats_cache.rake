require 'rake'

task :update_stats_cache => [:environment] do
  puts "Updating stats cache - #{Time.now}"

  start_date = Date.today.at_beginning_of_month - 13.months
  end_date = Date.today.end_of_month
  ranges = Submission.get_date_ranges("month", start_date, end_date)

  puts "Boundaries - #{Time.now}"
  Boundaries.where(:enabled => true).select(:boundary_type, :boundary_id).each do |boundary|
    boundary_type = boundary.boundary_type
    boundary_id = boundary.boundary_id

    # Check if we have new records newer than the cache
    newest = Submission.find_for_boundary(boundary_type, boundary_id).order("updated_at DESC").take
    cached = StatsCache.where(:stat_type => boundary_type, :stat_id => boundary_id,
      :date_type => 'all', :date_value => '1970-01-01').take
    if cached.present? && newest.present? && newest[:updated_at] <= cached[:updated_at]
      next
    end

    all_uploads = Submission.find_for_boundary(boundary_type, boundary_id).with_test_type("upload")
    all_downloads = Submission.find_for_boundary(boundary_type, boundary_id).with_test_type("download")
    sua_uploads = all_uploads.not_from_mlab
    sua_downloads = all_downloads.not_from_mlab

    updateCache(boundary_type, boundary_id, ranges, all_uploads, all_downloads, sua_uploads, sua_downloads)
  end

  # TODO cleanup old records
  # DELETE FROM stats_caches s
  # LEFT JOIN boundary b ON s.stat_id = b.boundary_id AND s.stat_type = b.boundary_type
  # WHERE b.enabled = false

  puts "Providers - #{Time.now}"
  ProviderStatistic.all.select(:name).each do |provider|
    stats_type = 'provider'
    stats_id = provider.name

    # Check if we have new records newer than the cache
    newest = Submission.where(:provider => stats_id).order("updated_at DESC").take
    cached = StatsCache.where(:stat_type => stats_type, :stat_id => stats_id,
      :date_type => 'all', :date_value => '1970-01-01').take
    if cached.present? && newest.present? && newest[:updated_at] <= cached[:updated_at]
      next
    end

    all_uploads = Submission.get_provider_for_stats_cache(stats_id, "upload")
    all_downloads = Submission.get_provider_for_stats_cache(stats_id, "download")
    sua_uploads = all_uploads.not_from_mlab
    sua_downloads = all_downloads.not_from_mlab

    updateCache(stats_type, stats_id, ranges, all_uploads, all_downloads, sua_uploads, sua_downloads)
  end

  # TODO cleanup providers that are not referenced by submissions

  puts "Finished update stats cache. #{Time.now}"
  puts '*' * 50
end

def updateCache(type, id, ranges, all_uploads, all_downloads, sua_uploads, sua_downloads)
  # If no data don't create/update and delete all existing records
  if all_uploads.count() == 0 && all_downloads.count() == 0
    StatsCache.delete_all(:stat_type => type, :stat_id => id)
    return
  end

  # Update "all" record
  upsertStats(type, id, 'all', '1970-01-01', all_uploads, all_downloads, sua_uploads, sua_downloads)

  # Update monthly records
  ranges.each do |range|
    range_start = range[:range][0]
    range_end = range[:range][1]

    all_uploads_month = all_uploads.with_date_range(range_start, range_end)
    all_downloads_month = all_downloads.with_date_range(range_start, range_end)
    sua_uploads_month = sua_uploads.with_date_range(range_start, range_end)
    sua_downloads_month = sua_downloads.with_date_range(range_start, range_end)

    upsertStats(type, id, 'month', range_start.strftime("%Y-%m-%d"), all_uploads_month, all_downloads_month,
      sua_uploads_month, sua_downloads_month)
  end

end

def upsertStats(stats_type, stats_id, date_type, date_value, all_uploads, all_downloads, sua_uploads, sua_downloads)
  key = {
    stat_type: stats_type,
    stat_id: stats_id,
    date_type: date_type,
    date_value: date_value,
  }

  record = StatsCache.where(key).first
  if record.nil?
    record = StatsCache.new(key)
  end

  # all downloads
  all_downloads = all_downloads.select("actual_down_speed")
  all_downloads_array = all_downloads.map(&:"actual_down_speed").compact
  all_count_download = all_downloads_array.length
  if all_count_download > 0
    # calculate basic stats
    all_avg_download, all_median_download, all_fast_download = calculate_basic_stats(all_downloads_array)

    # breakdown (bucket counts)
    all_breakdown_download = calculate_speed_breakdown(all_downloads_array)

    # comparison data
    all_download_less_than_5, all_download_less_than_25, all_download_faster_than_100,
      all_download_faster_than_250 = get_speed_comparison_data(all_downloads_array)
  end

  all_downloads = nil
  all_downloads_array = nil

  # sua downloads
  sua_downloads = sua_downloads.select("actual_down_speed")
  sua_downloads_array = sua_downloads.map(&:"actual_down_speed").compact
  sua_count_downloads = sua_downloads_array.length
  if sua_count_downloads > 0
    # calculate basic stats
    sua_avg_download, sua_median_download, sua_fast_download = calculate_basic_stats(sua_downloads_array)
  end

  sua_downloads = nil
  sua_downloads_array = nil

  # all uploads
  all_uploads = all_uploads.select("actual_upload_speed")
  all_uploads_array = all_uploads.map(&:"actual_upload_speed").compact
  all_count_upload = all_uploads_array.length
  if all_count_upload > 0
    # calculate basic stats
    all_avg_upload, all_median_upload, all_fast_upload = calculate_basic_stats(all_uploads_array)

    # breakdown (bucket counts)
    all_breakdown_upload =  calculate_speed_breakdown(all_uploads_array)

    # comparison data
    all_upload_less_than_5, all_upload_less_than_25, all_upload_faster_than_100,
      all_upload_faster_than_250 = get_speed_comparison_data(all_uploads_array)
  end

  all_uploads = nil
  all_uploads_array = nil

  # sua uploads
  sua_uploads = sua_uploads.select("actual_upload_speed")
  sua_uploads_array = sua_uploads.map(&:"actual_upload_speed").compact
  sua_count_uploads = sua_uploads_array.length
  if sua_count_uploads > 0
     # calculate basic stats
     sua_avg_upload, sua_median_upload, sua_fast_upload = calculate_basic_stats(sua_uploads_array)
  end

  sua_uploads = nil
  sua_uploads_array = nil

  stats = {
    download_avg: all_avg_download.nil? ? 0 : all_avg_download,
    download_median: all_median_download.nil? ? 0 : all_median_download,
    download_max: all_fast_download.nil? ? 0 : all_fast_download,
    download_count: all_count_download,

    download_sua_avg: sua_avg_download.nil? ? 0 : sua_avg_download,
    download_sua_median: sua_median_download.nil? ? 0 : sua_median_download,
    download_sua_max: sua_fast_download.nil? ? 0 : sua_fast_download,
    download_sua_count: sua_count_downloads,

    download_0_5: all_breakdown_download.nil? ? 0 : all_breakdown_download[0],
    download_6_10: all_breakdown_download.nil? ? 0 : all_breakdown_download[1],
    download_11_20: all_breakdown_download.nil? ? 0 : all_breakdown_download[2],
    download_21_40: all_breakdown_download.nil? ? 0 : all_breakdown_download[3],
    download_40_60: all_breakdown_download.nil? ? 0 : all_breakdown_download[4],
    download_61_80: all_breakdown_download.nil? ? 0 : all_breakdown_download[5],
    download_81_100: all_breakdown_download.nil? ? 0 : all_breakdown_download[6],
    download_101_250: all_breakdown_download.nil? ? 0 : all_breakdown_download[7],
    download_251_500: all_breakdown_download.nil? ? 0 : all_breakdown_download[8],
    download_500_1000: all_breakdown_download.nil? ? 0 : all_breakdown_download[9],
    download_1001: all_breakdown_download.nil? ? 0 : all_breakdown_download[10],

    download_less_than_5: all_download_less_than_5.nil? ? 0 : all_download_less_than_5,
    download_less_than_25: all_download_less_than_25.nil? ? 0 : all_download_less_than_25,
    download_faster_than_100: all_download_faster_than_100.nil? ? 0 : all_download_faster_than_100,
    download_faster_than_250: all_download_faster_than_250.nil? ? 0 : all_download_faster_than_250,

    upload_avg: all_avg_upload.nil? ? 0 : all_avg_upload,
    upload_median: all_median_upload.nil? ? 0 : all_median_upload,
    upload_max: all_fast_upload.nil? ? 0 : all_fast_upload,
    upload_count: all_count_upload,

    upload_sua_avg: sua_avg_upload.nil? ? 0 : sua_avg_upload,
    upload_sua_median: sua_median_upload.nil? ? 0 : sua_median_upload,
    upload_sua_max: sua_fast_upload.nil? ? 0 : sua_fast_upload,
    upload_sua_count: sua_count_uploads,

    upload_0_5: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[0],
    upload_6_10: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[1],
    upload_11_20: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[2],
    upload_21_40: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[3],
    upload_40_60: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[4],
    upload_61_80: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[5],
    upload_81_100: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[6],
    upload_101_250: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[7],
    upload_251_500: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[8],
    upload_500_1000: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[9],
    upload_1001: all_breakdown_upload.nil? ? 0 : all_breakdown_upload[10],

    upload_less_than_5: all_upload_less_than_5.nil? ? 0 : all_upload_less_than_5,
    upload_less_than_25: all_upload_less_than_25.nil? ? 0 : all_upload_less_than_25,
    upload_faster_than_100: all_upload_faster_than_100.nil? ? 0 : all_upload_faster_than_100,
    upload_faster_than_250: all_upload_faster_than_250.nil? ? 0 : all_upload_faster_than_250,
  }

  record.update(stats)
  record.save
end

def calculate_basic_stats(speeds)
  avg = get_avg(speeds)
  median = Submission.median(speeds).to_f
  max = speeds.max.to_f

  return avg, median, max
end

def get_avg(speeds)
  speeds.inject(0){|sum,x| sum + x }.to_f / speeds.length
end

def calculate_speed_breakdown(speeds)
  Submission::SPEED_BREAKDOWN_RANGES.map do |range|
    count = count_between(speeds, range)
    Submission.percentage(count, speeds.length)
  end
end

def count_between(speeds, range)
  if '+'.in?(range)
    lower = range.gsub('+', '').to_f
    speeds.count { |val| val >= lower }
  else
    range_values = range.split('..')
    lower = range_values[0].to_f
    upper = range_values[1].to_f
    speeds.count { |val| val >= lower && val <= upper }
  end
end

def get_speed_comparison_data(speeds)
  less_than_5 = speeds.count { |val| val < 5 }
  less_than_25 = speeds.count { |val| val < 25 }
  faster_than_100 = speeds.count { |val| val >= 100 }
  faster_than_250 = speeds.count { |val| val >= 250 }

  return less_than_5, less_than_25, faster_than_100, faster_than_250
end

def all_months_from(start) to
  start, to = to, from if from > to
  m = Date.new from.year, from.month
  result = []
  while m <= to
    result << m
    m >>= 1
  end

  result
end
