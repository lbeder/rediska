module Rediska
  class SortedSetStore
    attr_accessor :data, :weights, :aggregate, :keys

    def initialize(params, data)
      @data = data
      @weights = params.weights
      @aggregate = params.aggregate
      @keys = params.keys
    end

    def hashes
      @hashes ||= keys.map do |src|
        case data[src]
        when ::Set
          Hash[data[src].map {|k,v| [k, 1]}]
        when Hash
          data[src]
        else
          {}
        end
      end
    end

    def computed_values
      @computed_values ||= begin
        # Do nothing if all weights are 1, as n * 1 is n.
        if weights.all? {|weight| weight == 1 }
          values = hashes
        # Otherwise, multiply the values in each hash by that hash's weighting
        else
          values = hashes.each_with_index.map do |hash, index|
            weight = weights[index]
            Hash[hash.map {|k, v| [k, (v * weight)]}]
          end
        end
      end
    end

    def aggregate_sum(out)
      selected_keys.each do |key|
        out[key] = computed_values.inject(0) do |n, hash|
          n + (hash[key] || 0)
        end
      end
    end

    def aggregate_min(out)
      selected_keys.each do |key|
        out[key] = computed_values.map {|h| h[key] }.compact.min
      end
    end

    def aggregate_max(out)
      selected_keys.each do |key|
        out[key] = computed_values.map {|h| h[key] }.compact.max
      end
    end

    def selected_keys
      raise NotImplemented, "subclass needs to implement #selected_keys"
    end

    def call
      ZSet.new.tap {|out| send("aggregate_#{aggregate}", out) }
    end
  end

  class SortedSetIntersectStore < SortedSetStore
    def selected_keys
      @values ||= hashes.inject([]) { |r, h| r.empty? ? h.keys : (r & h.keys) }
    end
  end

  class SortedSetUnionStore < SortedSetStore
    def selected_keys
      @values ||= hashes.map(&:keys).flatten.uniq
    end
  end
end
