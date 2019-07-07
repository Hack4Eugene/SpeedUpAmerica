require 'rake'

task update_providers_statistics: [:environment] do
  puts 'Updating provider statistics'

  Submission.unscoped.select(:provider).where('provider IS NOT NULL').group(:provider).each do |provider|
    provider = provider[:provider]

    provider_statistic = ProviderStatistic.get_by_name(provider).take
    if provider_statistic.blank? 
      provider_statistic = ProviderStatistic.new()
      provider_statistic.name = provider
      provider_statistic.provider_type = 'unknown'
    end

    actual_download_sum = 0
    actual_download_count = 0

    actual_download = Submission.with_test_type("download")
      .select("SUM(actual_down_speed) AS speed_sum, COUNT(id) AS speed_count")
      .where('provider = ? AND actual_down_speed > 0', provider).group(:provider).take
    if actual_download.present?
      actual_download_sum = actual_download[:speed_sum]
      actual_download_count = actual_download[:speed_count]
    end

    provider_statistic.actual_speed_sum = actual_download_sum

    provider_download_sum = 0
    provider_download_count = 0

    provider_download = Submission.with_test_type("download")
      .select("SUM(provider_down_speed) AS speed_sum, COUNT(id) AS speed_count")
      .where('provider = ? AND provider_down_speed > 0', provider).group(:provider).take
    if provider_download.present?
      provider_download_sum = provider_download[:speed_sum]
      provider_download_count = provider_download[:speed_count]
    end
    
    provider_statistic.provider_speed_sum = provider_download_sum

    price_sum = 0
    price_count = 0

    actual_prices = Submission.with_test_type("download")
      .select("SUM(actual_price) AS price_sum, COUNT(id) AS price_count")
      .where('provider = ? AND actual_price > 0', provider).group(:provider).take
    if actual_prices.present?
      price_sum = actual_prices[:price_sum]
      price_count = actual_prices[:price_count]
    end

    if price_count > 0
      provider_statistic.average_price = price_sum / price_count
    end
    
    provider_statistic.applications = actual_download_count

    provider_statistic.save
  end

  Submission.valid_rating.select(:provider).group(:provider).each do |provider|
    provider = provider[:provider]

    ratings = Submission.select("SUM(rating) AS rating_sum, COUNT(id) AS rating_count")
      .where('provider = ? AND rating IS NOT NULL', provider).group(:provider).take
    if ratings.present?
      rating_sum = ratings[:rating_sum]
      rating_count = ratings[:rating_count]
    end

    provider_statistic = ProviderStatistic.get_by_name(provider).take
    next if provider_statistic.blank?

    provider_statistic.rating = rating_sum / rating_count
    provider_statistic.save
  end

  ProviderStatistic.where("updated_at < ?", 16.hours.ago).destroy_all

  puts 'Updated providers statistics successfully!'
  puts '*' * 50
end
