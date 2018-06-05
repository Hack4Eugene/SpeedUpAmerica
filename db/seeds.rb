# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

providers = {
              'AccessOne' => 'broadband',
              'Comcast business' => 'broadband',
              'Comcast xfinity' => 'broadband',
              'ATT' => 'both',
              'Cruzio' => 'broadband',
              'Dish' => 'broadband',
              'Earthlink' => 'broadband',
              'Frontier' => 'broadband',
              'HughesNet' => 'broadband',
              'Integra' => 'broadband',
              'Level3' => 'broadband',
              'Megapath' => 'broadband',
              'Razzolink' => 'broadband',
              'Sonic' => 'broadband',
              'Sunesys' => 'broadband',
              'TelePacific' => 'broadband',
              'Unwired' => 'broadband',
              'Voyant' => 'broadband',
              'Windstream' => 'broadband',
              'XO Communications' => 'broadband',
              'Cricket Wireless' => 'mobile',
              'Boost Mobile' => 'mobile',
              'T-Mobile' => 'mobile',
              'Sprint' => 'mobile',
              'Verizon' => 'mobile',
              'Other' => 'both',
            }

providers.each do |name, provider_type|
  ProviderStatistic.find_or_create_by(name: name, provider_type: provider_type)
end
