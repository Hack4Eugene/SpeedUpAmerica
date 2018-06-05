require 'rake'

task :delete_invalid_tests => [:environment] do
  Submission.invalid_test.delete_all
  puts 'All invalid tests are deleted successfully!'
end
