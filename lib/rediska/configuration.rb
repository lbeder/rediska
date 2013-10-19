module Rediska
  Redis = ::Redis

  class Configuration
    attr_accessor :database

    def initialize
      database = :memory
    end
  end
end
