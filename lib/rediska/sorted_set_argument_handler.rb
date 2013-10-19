module Rediska
  class SortedSetArgumentHandler
    attr_reader :aggregate
    attr_accessor :number_of_keys, :keys, :weights, :type

    def initialize(args)
      @number_of_keys = args.shift
      @keys = args.shift(number_of_keys)
      args.inject(self) {|handler, item| handler.handle(item) }

      # Defaults.
      @weights ||= Array.new(number_of_keys) { 1 }
      @aggregate ||= :sum

      # Validation.
      raise Redis::CommandError, 'ERR syntax error' unless weights.size == number_of_keys
      raise Redis::CommandError, 'ERR syntax error' unless [:min, :max, :sum].include?(aggregate)
    end

    def aggregate=(str)
      raise Redis::CommandError, 'ERR syntax error' if @aggregate

      @aggregate = str.to_s.downcase.to_sym
    end

    def handle(item)
      case item
      when 'WEIGHTS'
        @type = :weights
        @weights = []
      when 'AGGREGATE'
        @type = :aggregate
      when nil
        raise Redis::CommandError, 'ERR syntax error'
      else
        send "handle_#{type}", item
      end

      self
    end

    def handle_weights(item)
      @weights << item
    end

    def handle_aggregate(item)
      @aggregate = item
    end

    def inject_block
      lambda { |handler, item| handler.handle(item) }
    end
  end
end
