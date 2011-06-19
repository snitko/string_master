require "rubygems"
require "bundler/setup"

Dir[File.dirname(__FILE__) + "/../lib/**/*.rb"].each {|f| require f}
plugin_spec_dir = File.dirname(__FILE__)
