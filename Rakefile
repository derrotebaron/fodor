require 'rake'
require 'yard'
require 'md2man/rakefile'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'docs/*.md']
  t.options = ['--no-private', '--title', 'FODOR']
  t.stats_options = ['--list-undoc']
end
