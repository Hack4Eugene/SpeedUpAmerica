module ApplicationHelper

  def body_css_class
    action_name == 'internet_stats' && 'in-stats' || ''
  end

  def header_file_name
    action_name == 'embeddable_view' ? 'social_share' : 'header'
  end

  def body_css_class
    return 'result-page' if action_name == 'result_page' || action_name == 'show'
    return 'in-stats' if action_name == 'internet_stats'
    return ''
  end

end
