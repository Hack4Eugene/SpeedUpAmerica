require 'rake'

task update_providers_rating: [:environment] do
  Submission.completed.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    next if provider_statistic.blank?
    provider_statistic.rating = submissions.collect(&:rating).sum.to_f / submissions.count
    provider_statistic.applications = submissions.count
    provider_statistic.save
  end
end

task update_providers_statistics: [:environment] do
  Submission.completed.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    next if provider_statistic.blank?
    provider_statistic.rating = submissions.collect(&:rating).sum.to_f / submissions.count
    provider_statistic.actual_speed_sum = submissions.collect(&:actual_down_speed).sum
    provider_statistic.provider_speed_sum = submissions.collect(&:provider_down_speed).sum
    provider_statistic.advertised_to_actual_ratio = get_actual_to_provider_difference(provider_statistic.actual_speed_sum, provider_statistic.provider_speed_sum)
    provider_statistic.average_price = submissions.collect(&:actual_price).sum.to_f / submissions.count
    provider_statistic.applications = submissions.count
    provider_statistic.save
  end

  Submission.completed.valid_rating.in_zip_code_list.group_by(&:provider).each do |provider, submissions|
    provider_statistic = ProviderStatistic.get_by_name(provider).first
    next if provider_statistic.blank?
    provider_statistic.rating = submissions.collect(&:rating).sum.to_f / submissions.count
    provider_statistic.save
  end

  puts 'Updated providers statistics successfully!'
end

def get_actual_to_provider_difference(actual_speed_sum, provider_speed_sum)
  (actual_speed_sum - provider_speed_sum).to_f / provider_speed_sum
end
