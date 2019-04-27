# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

providers = {
              'XS Media' => 'broadband',
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
              'Hunter' => 'both',
              'Earthlink' => 'broadband',
              'Windstream' => 'broadband',
              'Spectrocel' => 'broadband',
              'Wave Broadband' => 'broadband',
              'Verizon' => 'broadband',
              'XO' => 'broadband',
              'T-Mobile' => 'mobile',
              'Sprint' => 'mobile',
              'Cricket Wireless' => 'mobile',
              'Boost Mobile' => 'mobile',
              'US Cellular' => 'mobile',
              'Other' => 'mobile',
            }

providers.each do |name, provider_type|
  ProviderStatistic.find_or_create_by(name: name, provider_type: provider_type)
end
