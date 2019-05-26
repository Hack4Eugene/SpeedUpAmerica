module HomeHelper
  def provider_list(form_type = {first_step: true})
    ProviderStatistic.pluck(:name)
  end

  def connected_list
    [
      'Wired connection',
      'Wireless connection, single device',
      'Wireless connection, multiple devices in household',
    ]
  end
end
