module Rediska
  Redis = ::Redis

  class Configuration
    attr_accessor :database, :namespace

    def initialize
      @database = :memory
    end
  end
end
