module HomeHelper
  def provider_list(form_type = {first_step: true})
    if form_type[:first_step]
      [
        "Beavercreek Cooperative Telephone Company",
        "Blackfoot Communications, Inc.",
        "Cascade Utilities",
        "Cleer Creek Communications",
        "Colton Telephone Company",
        "Comcast",
        "DirectLink",
        "Frontier Communications Corporation",
        "Molalla Communications Company",
        "Monitor Cooperative Telephone Company",
        "OnlineNW",
        "St Paul Coop Telephone Assoc",
        "StephouseNetworks",
        'Allstream',
        'Century Link',
        'Douglas Fast Net',
        'Earthlink',
        'Emeral Broadband',
        'Freewire',
        'GTT Communications',
        'Hunter Communications',
        'InfoStructure',
        'Integra',
        'King Street Wireless',
        'Lightspeed Networks',
        'Peak Internet',
        'Spectrocel',
        'UnwiredWest',
        'Verizon',
        'Viasat',
        'Wave Broadband',
        'Wave',
        'Windstream',
        'XO',
        'XS Media',
        'Xfinity',
        'Zayo Group',
      ]
    else
      [
        "AT&T Mobility",
        "United_States_Cellular_Corporation",
        "Verizon Wireless",
        'Boost Mobile',
        'Cricket Wireless',
        'Hunter Communications',
        'Sprint',
        'T-Mobile',
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
