require 'rediska/databases/expiring'

module Rediska
  module Databases
    class Memory < Hash
      include Expiring

      def initialize(instance_key, id)
        super()
      end

      class << self
        def flushdb(instance_key, id)
        end

        def flushall(instance_key)
        end
      end
    end
  end
end
