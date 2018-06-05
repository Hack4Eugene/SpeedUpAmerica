module ApplicationHelper

  def body_css_class
    action_name == 'internet_stats' && 'in-stats' || ''
  end

end
