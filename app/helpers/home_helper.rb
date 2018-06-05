module HomeHelper
  def provider_list(form_type = {provider_list_type: 'residential-form'})
    if form_type[:provider_list_type] == 'residential-form'
      [
        'ATT',
        'AccessOne',
        'Comcast business',
        'Comcast xfinity',
        'Cruzio',
        'Dish',
        'Earthlink',
        'Frontier',
        'HughesNet',
        'Integra',
        'Level3',
        'Megapath',
        'Razzolink',
        'Sonic',
        'Sunesys',
        'TelePacific',
        'Unwired',
        'Voyant',
        'Windstream',
        'XO Communications',
        'Other',
      ]
    elsif form_type[:provider_list_type] == 'mobile-form'
      [
        'ATT',
        'Boost Mobile',
        'Cricket Wireless',
        'Sprint',
        'T-Mobile',
        'Verizon',
        'Other',
      ]
    elsif form_type[:provider_list_type] == 'public-form'
      [
        'Wickedly Fast San Jose Public',
        'Library',
        'Community Center',
        'Work2Future Center',
        'City Hall',
        'Convention Center',
        'Airport',
        'Public Parks',
        'Other Free San Jose Public',
        'Center of Faith',
        'Retail / Restaurant',
        'School / University',
        'At Work',
      ]
    end
  end

  def connected_list
    [
      'Wired connection',
      'Wireless connection, single device',
      'Wireless connection, multiple devices in household',
    ]
  end

  def public_connected_list
    [
      'Wired',
      'Wifi',
    ]
  end
end
