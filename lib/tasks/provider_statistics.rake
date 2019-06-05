require 'rake'

task update_providers_statistics: [:environment] do
  puts 'Updating provider statistics'

  Submission.unscoped.with_test_type("download").in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    
    if provider_statistic.blank? 
      provider_statistic = ProviderStatistic.new()
      provider_statistic.name = provider
      provider_statistic.provider_type = 'unknown'
    end

    provider_statistic.actual_speed_sum = submissions.collect(&:actual_down_speed).compact.sum
    provider_statistic.provider_speed_sum = submissions.collect(&:provider_down_speed).compact.sum

    actual_prices = submissions.collect(&:actual_price).compact
    if actual_prices.count > 0
      provider_statistic.average_price = actual_prices.sum / actual_prices.count
    end
    
    provider_statistic.applications = submissions.count

    provider_statistic.save
  end

  Submission.valid_rating.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    next if provider_statistic.blank?
    provider_statistic.rating = submissions.collect(&:rating).sum.to_f / submissions.count
    provider_statistic.save
  end

  ProviderStatistic.where("updated_at < ?", 16.hours.ago).destroy_all

  puts 'Updated providers statistics successfully!'
  puts '*' * 50
end

def get_actual_to_provider_difference(actual_speed_sum, provider_speed_sum)
  (actual_speed_sum - provider_speed_sum).to_f / provider_speed_sum
end
