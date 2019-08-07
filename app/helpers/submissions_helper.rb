module SubmissionsHelper
  def print_speed(speed)
    speed.present? ? "#{speed} Mbps" : '--'
  end

  def print_actual_cost(cost)
    cost.present? ? ['$', '%.2f' % cost].join : '--'
  end

  def print_provider_cost(cost)
    cost.present? ? ['$', '%.2f' % cost].join : '--'
  end

  def filter_rating(rating)
    (rating * 2).ceil.to_f / 2
  end

  def print_provider_ratio(amount)
    "#{sprintf('%+.2f', amount)}%"
  end

  def print_ping(ping)
    ping.present? ? "#{ping} ms" : '--'
  end

  def set_color(ratio)
    ratio < 0 ? 'red-color' : 'green-color'
  end

  def compared_speed_percentage(submission)
    lower_speed_count = Submission.with_type_and_lower_speed(submission.testing_for, submission.actual_down_speed).count
    total_speed_count = Submission.with_connection_type(submission.testing_for).count
    percentage = lower_speed_count/total_speed_count.to_f*100
    css_class = percentage > 50 && 'green-color' || 'red-color'
    "<span class=#{css_class}>Faster than <span class='percent-val'>#{percentage.round(2)}%</span></span>".html_safe
  end

  def actual_speed_percentage(submission)
    speed_difference = submission.provider_down_speed.to_f - submission.actual_down_speed.to_f
    percentage = submission.provider_down_speed.zero? && 0 || speed_difference/submission.provider_down_speed.to_f*100
    return "<span class='red-color'><span class='percent-val'>#{percentage.abs.round(2)}%</span> slower</span>".html_safe if speed_difference >= 0
    return "<span class='green-color'><span class='percent-val'>#{percentage.abs.round(2)}%</span> faster</span>".html_safe if speed_difference < 0
  end

  def internet_speed(submissions, type)
    speeds = submissions.pluck(:actual_down_speed).sort
    return speeds.first if type == 'slowest'
    return (speeds.sum/speeds.count.to_f).round(2) if type == 'average'
    return speeds.last if type == 'fastest'
  end

  def average_cost(provider)
    ProviderStatistic.find_by_name(provider).try(:average_price).to_f
  end

  def average_down_speed(provider)
    statistic = ProviderStatistic.find_by_name(provider)
    (statistic.actual_speed_sum.to_f/statistic.applications).round(2) if statistic.present?
  end

  def target_value
    return '_blank' unless action_name == 'embeddable_view'
  end

  def get_providers_list
    all_option = ['All', 'all']
    ProviderStatistic.all.map { |p| [p.name, p.id] }.unshift(all_option)
  end

  def get_stats_providers_list
    ProviderStatistic.all.map { |p| [p.name, p.id] }
  end

  def get_list_zip_code_values(codes)
    if params[:id].blank?
      all_option = ['All', 'all']
      codes.map { |code| [code, code] }.unshift(all_option)
    else
      submission = Submission.find(params[:id])
      puts 'Get List Zip Code Values'
      puts submission.zip_code.nil?
      zip_code = submission.zip_code if submission.zip_code.nil? || 'All'
      puts zip_code
      all_option = [zip_code, 'all']
      codes.map { |code| [code, code] }.unshift(all_option)
    end
  end

  def get_list_census_code_values(codes)
    all_option = ['All', 'all']
    codes.map { |code| [code, code] }.unshift(all_option)
  end
end
