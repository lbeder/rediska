require 'redis'
require 'rediska/configuration'
require 'rediska/connection'
require 'rediska/sidekiq'

module Rediska
  extend self

  attr_accessor :configuration

  def configure
    Redis::Connection.drivers << Rediska::Connection

    self.configuration ||= Configuration.new
    yield configuration if block_given?
  end
end

Rediska.configure
