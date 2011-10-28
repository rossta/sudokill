begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'

  # local jasmine extensions
  load 'lib/tasks/jasmine.rake'

rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

# namespace :jasmine do
#   desc "Run specs via commandline"
#   task :headless do
#     system("ruby spec/javascripts/support/jazz_money_runner.rb")
#   end
# end
