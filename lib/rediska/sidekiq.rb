if defined?(Sidekiq)
  # For seamless integration with Sidekiq, we need to patch its configuration and pass down our
  # driver.
  #
  # Note: currently, this is being achieved by monkey patching Sidekiq directly. Better solutions
  # are more than welcome! :).
  module Sidekiq
    class RedisConnection
      class << self
        alias_method :old_create, :create

        def create(options = {})
          old_create(options.merge!(driver: Rediska::Connection))
        end
      end
    end
  end
end
