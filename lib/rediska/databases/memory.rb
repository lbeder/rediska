require 'rediska/databases/expiring'

module Rediska
  module Databases
    class Memory < Hash
      include Expiring

      class << self
        def flushdb(instance_key, id)
        end

        def flushall(instance_key)
        end
      end
    end
  end
end
