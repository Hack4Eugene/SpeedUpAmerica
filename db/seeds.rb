# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

providers = {
              'XS Media' => 'broadband',
              'Emeral Broadband' => 'broadband',
              'Peak Internet' => 'broadband',
              'Wave' => 'broadband',
              'Douglas Fast Net' => 'broadband',
              'Century Link' => 'broadband',
              'Xfinity' => 'broadband',
              'Viasat' => 'broadband',
              'InfoStructure' => 'broadband',
              'Allstream' => 'broadband',
              'King Street Wireless' => 'broadband',
              'UnwiredWest' => 'broadband',
              'Freewire' => 'broadband',
              'Integra' => 'broadband',
              'Zayo Group' => 'broadband',
              'Lightspeed Networks' => 'broadband',
              'GTT Communications' => 'broadband',
              'Hunter Communications' => 'both',
              'Earthlink' => 'broadband',
              'Windstream' => 'broadband',
              'Spectrocel' => 'broadband',
              'Wave Broadband' => 'broadband',
              'Verizon' => 'broadband',
              'XO' => 'broadband',
              "Comcast" => "broadband",
              "Frontier Communications Corporation" => "broadband",
              "DirectLink" => "broadband",
              "Cascade Utilities" => "broadband",
              "Beavercreek Cooperative Telephone Company" => "broadband",
              "Cleer Creek Communications" => "broadband",
              "Molalla Communications Company" => "broadband",
              "OnlineNW" => "broadband",
              "Colton Telephone Company" => "broadband",
              "Monitor Cooperative Telephone Company" => "broadband",
              "StephouseNetworks" => "broadband",
              "Blackfoot Communications, Inc." => "broadband",
              "St Paul Coop Telephone Assoc" => "broadband",
              "AT_T_Mobility" => "wireless",
              "Verizon Wireless" => "wireless",
              "United_States_Cellular_Corporation" => "wireless",
              'T-Mobile' => 'wireless',
              'Sprint' => 'wireless',
              'Cricket Wireless' => 'wireless',
              'Boost Mobile' => 'wireless',
              'US Cellular' => 'wireless',
              'Other' => 'wireless',
            }

providers.each do |name, provider_type|
  ProviderStatistic.find_or_create_by(name: name, provider_type: provider_type)
end
