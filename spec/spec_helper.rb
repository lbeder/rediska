ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'coveralls'
require 'pry'
require 'pry-debugger'
require 'rediska'

Coveralls.wear!

Dir['./spec/support/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
end
