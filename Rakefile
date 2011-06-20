# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "string_master"
  gem.homepage = "http://github.com/snitko/string_master"
  gem.license = "MIT"
  gem.summary = %Q{Most common string manipulations for a webapp}
  gem.description = %Q{Because every time I create a new webapp, I think about how I should process user-generated content. Should convert urls to links and images? Should I allow certain tags? Should I convert all new lines to *br* tags? Well, now all that is as simple as calling a single method.}
  gem.email = "roman.snitko@gmail.com"
  gem.authors = ["Roman Snitko"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end


require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "string_master #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
