module Rediska
  module Databases
    module Expiring
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend ClassMethods

        attr_reader :expires
      end

      module InstanceMethods
        def initialize
          super

          @expires = {}
        end

        def [](key)
          key = normalize(key)
          delete(key) if expired?(key)

          super
        end

        def []=(key, val)
          key = normalize(key)
          expire(key)

          super
        end

        def delete(key)
          key = normalize(key)
          expire(key)

          super
        end

        def expire(key)
          key = normalize(key)
          expires.delete(key)
        end

        def expired?(key)
          key = normalize(key)
          expires.include?(key) && expires[key] < Time.now
        end

        def key?(key)
          key = normalize(key)
          delete(key) if expired?(key)

          super
        end

        def values_at(*keys)
          keys.each do |key|
            key = normalize(key)
            delete(key) if expired?(key)
          end

          super
        end

        def keys
          super.select do |key|
            key = normalize(key)

            if expired?(key)
              delete(key)
              false
            else
              true
            end
          end
        end

        def normalize(key)
          key.to_s
        end
      end

      module ClassMethods
      end
    end
  end
end
