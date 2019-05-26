require 'rake'

task update_providers_statistics: [:environment] do
  Submission.completed.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
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

  Submission.completed.valid_rating.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    next if provider_statistic.blank?
    provider_statistic.rating = submissions.collect(&:rating).sum.to_f / submissions.count
    provider_statistic.save
  end

  ProviderStatistic.where(applications: 0).destroy_all

  puts 'Updated providers statistics successfully!'
end

def get_actual_to_provider_difference(actual_speed_sum, provider_speed_sum)
  (actual_speed_sum - provider_speed_sum).to_f / provider_speed_sum
end
