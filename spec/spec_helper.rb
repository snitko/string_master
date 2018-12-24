require "rubygems"
require "bundler/setup"

Dir[File.dirname(__FILE__) + "/../lib/string_master/*.rb"].each {|f| require f }

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.default_formatter = "doc"
end
