# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
require File.expand_path('../..//config/environment.rb', __FILE__)
# Example:
#
set :output, 'log/cron.log'
set :environment, Rails.env
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

every :sunday, at: '11:30pm' do
  rake 'import_mlab_submissions'
end

every :monday, at: '11:30pm' do
  rake 'update_pending_census_codes'
end

# Learn more: http://github.com/javan/whenever
