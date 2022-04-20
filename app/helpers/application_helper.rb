module ApplicationHelper

  def header_file_name
    action_name == 'embeddable_view' ? 'social_share' : 'header'
  end

  def body_css_class
    return 'result-page' if action_name == 'result_page'
    return 'in-stats' if action_name == 'internet_stats'
    return ''
  end

  def region_body_css_class
    return 'region-result-page' if action_name == 'region_result_page'
    return 'region-in-stats' if action_name == 'region_internet_stats'
    return 'region'
  end

end
