require 'redis'
require 'rediska/configuration'
require 'rediska/connection'

module Rediska
  extend self

  attr_accessor :configuration

  def configure
    Redis::Connection.drivers << Rediska::Connection

    self.configuration ||= Configuration.new
    yield configuration
  end
end

Rediska.configure {}


