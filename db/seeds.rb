# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

providers = {
              'Time Warner' => 'broadband',
              'Toast.net' => 'broadband',
              'ATT' => 'both',
              'Shelby Broadband' => 'broadband',
              'Windstream' => 'broadband',
              'Broadband view' => 'broadband',
              'Inside Connect Cable' => 'broadband',
              'Aero' => 'broadband',
              'Lighttower' => 'broadband',
              'Level 3' => 'broadband',
              'MegaPath' => 'broadband',
              'Birch' => 'broadband',
              'Verizon' => 'both',
              'Us Signal' => 'broadband',
              'Earthlink' => 'broadband',
              'Bluegrass.net' => 'broadband',
              'Iglou' => 'broadband',
              'Silica Broadband' => 'broadband',
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

unless Rails.env.production?
  connection = ActiveRecord::Base.connection
  connection.execute("TRUNCATE submissions;")

  sql = File.read('db/submissions.sql')
  connection.execute(sql)
end
