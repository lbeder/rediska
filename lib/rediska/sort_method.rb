# Codes are mostly referenced from MockRedis' implementation.
module Rediska
  module SortMethod
    def sort(key, *redis_options_array)
      return [] if !key || type(key) == 'none'

      unless %w(list set zset).include? type(key)
        warn "Operation against a key holding the wrong kind of value: Expected list, set or zset at #{key}."
        raise Redis::CommandError.new('WRONGTYPE Operation against a key holding the wrong kind of value')
      end

      options = extract_options_from(redis_options_array)

      projected = project(data[key], options[:by], options[:get])
      sorted = sort_by(projected, options[:order])
      sliced = slice(sorted, options[:limit])

      options[:store] ? rpush(options[:store], sliced) : sliced.flatten(1)
    end

    private
    ASCENDING_SORT = Proc.new { |a, b| a.first <=> b.first }
    DESCENDING_SORT = Proc.new { |a, b| b.first <=> a.first }

    def extract_options_from(options_array)
      options = {
        limit: [],
        order: 'ASC',
        get: []
      }

      if options_array.first == 'BY'
        options_array.shift
        options[:by] = options_array.shift
      end

      if options_array.first == 'LIMIT'
        options_array.shift
        options[:limit] = [options_array.shift, options_array.shift]
      end

      while options_array.first == 'GET'
        options_array.shift
        options[:get] << options_array.shift
      end

      if %w(ASC DESC ALPHA).include?(options_array.first)
        options[:order] = options_array.shift
        options[:order] = 'ASC' if options[:order] == 'ALPHA'
      end

      if options_array.first == 'STORE'
        options_array.shift
        options[:store] = options_array.shift
      end

      options
    end

    def project(enumerable, by, get_patterns)
      enumerable.map do |*elements|
        element = elements.flatten.first
        weight = by ? lookup_from_pattern(by, element) : element
        value = element

        if get_patterns.length > 0
          value = get_patterns.map do |pattern|
            pattern == '#' ? element : lookup_from_pattern(pattern, element)
          end
          value = value.first if value.length == 1
        end

        [weight, value]
      end
    end

    def sort_by(projected, direction)
      sorter =
        case direction.upcase
          when 'DESC'
            DESCENDING_SORT
          when 'ASC', 'ALPHA'
            ASCENDING_SORT
          else
            raise "Invalid direction '#{direction}'"
        end

      projected.sort(&sorter).map(&:last)
    end

    def slice(sorted, limit)
      skip = limit.first || 0
      take = limit.last || sorted.length

      sorted[skip...(skip + take)] || sorted
    end

    def lookup_from_pattern(pattern, element)
      key = pattern.sub('*', element)

      if (hash_parts = key.split('->')).length > 1
        hget hash_parts.first, hash_parts.last
      else
        get key
      end
    end
  end
end
