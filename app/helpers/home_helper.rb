module HomeHelper
  def provider_list(form_type = {first_step: true})
    if form_type[:first_step]
      [
        'Time Warner',
        'Toast.net',
        'ATT',
        'Shelby Broadband',
        'Windstream',
        'Broadband view',
        'Inside Connect Cable',
        'Aero',
        'Lighttower',
        'Level 3',
        'MegaPath',
        'Birch',
        'Verizon',
        'Us Signal',
        'Earthlink',
        'Bluegrass.net',
        'Iglou',
        'Silica Broadband',
      ]
    else
      [
        'ATT',
        'Verizon',
        'T-Mobile',
        'Sprint',
        'Cricket Wireless',
        'Boost Mobile',
        'US Cellular',
        'Other',
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
end
