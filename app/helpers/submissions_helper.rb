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
    return (speeds[(speeds.size.to_f - 1) / 2] + speeds[speeds.size.to_f / 2]) / 2.0 if type == 'median'
    return speeds.first if type == 'slowest'
    return (speeds.sum/speeds.count.to_f).round(2) if type == 'average'
    return speeds.last if type == 'fastest'
  end

  def average_cost(provider)
    ProviderStatistic.find_by_name(provider).try(:average_price).to_f
  end

  def median_down_speed(submissions, provider)
    speeds = submissions.with_provider(provider).pluck(:actual_down_speed).sort
    len = speeds.size.to_f
    ((speeds[(len - 1) / 2] + speeds[len / 2]) / 2.0).round(2)
  end

  def commercial_test_without_download_speed?(submission)
    return false unless submission.testing_for == Submission::MAP_FILTERS[:connection_type][:commercial_data]
    return false if submission.provider_down_speed
    return true
  end

  def commercial_test_with_download_speed?(submission)
    return false unless submission.testing_for == Submission::MAP_FILTERS[:connection_type][:commercial_data]
    return false unless submission.provider_down_speed
    return true
  end

  def export_csv_form_target
    user_agent = UserAgent.parse(request.env['HTTP_USER_AGENT'])
    '_blank' unless user_agent.browser == 'Chrome'
  end
end
