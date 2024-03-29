module Rediska
  module Driver
    attr_accessor :database_id
    attr_writer :replies

    def replies
      @replies ||= []
    end

    def connected?
      true
    end

    def connect_unix(path, timeout)
    end

    def disconnect
    end

    def client(command, _options = {})
      case command
      when :setname then true
      when :getname then nil
      when :client then true
      else
        raise Redis::CommandError, "ERR unknown command '#{command}'"
      end
    end

    def timeout=(usecs)
    end

    def read
      replies.shift
    end

    # NOT IMPLEMENTED:
    # * subscribe
    # * psubscribe
    # * publish

    def flushdb
      db_class.flushdb(database_instance_key, database_id)
      databases.delete_at(database_id)

      'OK'
    end

    def flushall
      db_class.flushall(database_instance_key)
      self.class.databases[database_instance_key] = []

      'OK'
    end

    def auth(*args)
      'OK'
    end

    def select(index)
      data_type_check(index, Integer)
      self.database_id = index

      'OK'
    end

    def info
      {
        'redis_version' => '3.0.5',
      }
    end

    def monitor
    end

    def save
    end

    def bgsave
    end

    def bgrewriteaof
    end

    def move(key, destination_id)
      raise Redis::CommandError, 'ERR source and destination objects are the same' if destination_id == database_id
      destination = find_database(destination_id)
      return false unless data.has_key?(key)
      return false if destination.has_key?(key)
      destination[key] = data.delete(key)
      true
    end

    def dump(key)
      return nil unless exists(key)

      Marshal.dump(value: data[key], version: Rediska::VERSION)
    end

    def restore(key, ttl, serialized_value)
      raise Redis::CommandError, 'ERR Target key name is busy.' if exists(key)

      if serialized_value.nil?
        raise Redis::CommandError, 'ERR DUMP payload version or checksum are wrong'
      end

      parsed_value = begin
        Marshal.load(serialized_value)
      rescue TypeError
        raise Redis::CommandError, 'ERR DUMP payload version or checksum are wrong'
      end

      if parsed_value[:version] != Rediska::VERSION
        raise Redis::CommandError, 'ERR DUMP payload version or checksum are wrong'
      end

      # We could figure out what type the key was and set it with the public API here, or we could
      # just assign the value. If we presume the serialized_value is only ever a return value from
      # `dump` then we've only been given something that was in the internal data structure anyway.
      data[key] = parsed_value[:value]

      # Set a TTL if one has been passed
      ttl = ttl.to_i # Makes nil into 0
      expire(key, ttl / 1000) unless ttl.zero?

      'OK'
    end

    def get(key)
      data_type_check(key, String)
      data[key]
    end

    def getbit(key, offset)
      return unless data[key]
      data[key].unpack('B*')[0].split('')[offset].to_i
    end

    def bitcount(key, start_index = 0, end_index = -1)
      return 0 unless data[key]

      data[key][start_index..end_index].unpack('B*')[0].count('1')
    end

    def getrange(key, start, ending)
      return unless data[key]
      data[key][start..ending]
    end
    alias :substr :getrange

    def getset(key, value)
      data_type_check(key, String)
      data[key].tap do
        set(key, value)
      end
    end

    def mget(*keys)
      raise_argument_error('mget') if keys.empty?

      # We work with either an array, or list of arguments
      keys = keys.first if keys.size == 1
      data.values_at(*keys)
    end

    def append(key, value)
      data[key] = (data[key] || '')
      data[key] = data[key] + value.to_s
    end

    def strlen(key)
      return unless data[key]
      data[key].size
    end

    def hgetall(key)
      data_type_check(key, Hash)
      data[key].to_a.flatten || {}
    end

    def hget(key, field)
      data_type_check(key, Hash)
      data[key] && data[key][field.to_s]
    end

    def hdel(key, field)
      data_type_check(key, Hash)
      return 0 unless data[key]

      if field.is_a?(Array)
        old_keys_count = data[key].size
        fields = field.map(&:to_s)

        data[key].delete_if { |k, v| fields.include? k }
        deleted = old_keys_count - data[key].size
      else
        field = field.to_s
        deleted = data[key].delete(field) ? 1 : 0
      end

      remove_key_for_empty_collection(key)
      deleted
    end

    def hkeys(key)
      data_type_check(key, Hash)
      return [] if data[key].nil?
      data[key].keys
    end

    def hscan(key, start_cursor, *args)
      data_type_check(key, Hash)
      return ['0', []] unless data[key]

      match = '*'
      count = 10

      raise_argument_error('hscan') if args.size.odd?

      if idx = args.index('MATCH')
        match = args[idx + 1]
      end

      if idx = args.index('COUNT')
        count = args[idx + 1]
      end

      start_cursor = start_cursor.to_i

      cursor = start_cursor
      next_keys = []

      if start_cursor + count >= data[key].length
        next_keys = (data[key].to_a)[start_cursor..-1]
        cursor = 0
      else
        cursor = start_cursor + count
        next_keys = (data[key].to_a)[start_cursor..cursor-1]
      end

      filtered_next_keys = next_keys.select{|k,v| File.fnmatch(match, k)}
      result = filtered_next_keys.flatten.map(&:to_s)

      return ["#{cursor}", result]
    end

    def keys(pattern = '*')
      data.keys.select { |key| File.fnmatch(pattern, key) }
    end

    def randomkey
      data.keys[rand(dbsize)]
    end

    def echo(string)
      string
    end

    def ping
      'PONG'
    end

    def lastsave
      Time.now.to_i
    end

    def time
      microseconds = (Time.now.to_f * 1000000).to_i
      [microseconds / 1000000, microseconds % 1000000]
    end

    def dbsize
      data.keys.count
    end

    def exists(key)
      data.key?(key)
    end

    def llen(key)
      data_type_check(key, Array)
      return 0 unless data[key]
      data[key].size
    end

    def lrange(key, startidx, endidx)
      data_type_check(key, Array)
      (data[key] && data[key][startidx..endidx]) || []
    end

    def ltrim(key, start, stop)
      data_type_check(key, Array)
      return unless data[key]

      # Example: we have a list of 3 elements and we give it a ltrim list, -5, -1. This means it
      # should trim to a max of 5. Since 3 < 5 we should not touch the list. This is consistent
      # with behavior of real Redis's ltrim with a negative start argument.
      unless start < 0 && data[key].count < start.abs
        data[key] = data[key][start..stop]
      end

      'OK'
    end

    def lindex(key, index)
      data_type_check(key, Array)
      data[key] && data[key][index]
    end

    def linsert(key, where, pivot, value)
      data_type_check(key, Array)
      return unless data[key]
      index = data[key].index(pivot)
      case where
        when :before then data[key].insert(index, value)
        when :after  then data[key].insert(index + 1, value)
        else raise_syntax_error
      end
    end

    def lset(key, index, value)
      data_type_check(key, Array)
      return unless data[key]
      raise Redis::CommandError, 'ERR index out of range' if index >= data[key].size
      data[key][index] = value
    end

    def lrem(key, count, value)
      data_type_check(key, Array)
      return 0 unless data[key]
      old_size = data[key].size
      diff =
        if count == 0
          data[key].delete(value)
          old_size - data[key].size
        else
          array = count > 0 ? data[key].dup : data[key].reverse
          count.abs.times{ array.delete_at(array.index(value) || array.length) }
          data[key] = count > 0 ? array.dup : array.reverse
          old_size - data[key].size
        end
      remove_key_for_empty_collection(key)
      diff
    end

    def rpush(key, value)
      raise_argument_error('rpush') if value.respond_to?(:each) && value.empty?

      data_type_check(key, Array)
      data[key] ||= []
      [value].flatten.each do |val|
        data[key].push(val.to_s)
      end
      data[key].size
    end

    def rpushx(key, value)
      raise_argument_error('rpushx') if value.respond_to?(:each) && value.empty?

      data_type_check(key, Array)
      return unless data[key]
      rpush(key, value)
    end

    def lpush(key, value)
      raise_argument_error('lpush') if value.respond_to?(:each) && value.empty?

      data_type_check(key, Array)
      data[key] ||= []
      [value].flatten.each do |val|
        data[key].unshift(val.to_s)
      end
      data[key].size
    end

    def lpushx(key, value)
      raise_argument_error('lpushx') if value.respond_to?(:each) && value.empty?

      data_type_check(key, Array)
      return unless data[key]
      lpush(key, value)
    end

    def rpop(key)
      data_type_check(key, Array)
      return unless data[key]
      data[key].pop
    end

    def brpop(keys, timeout = 0)
      keys = Array(keys)
      keys.each do |key|
        if data[key] && data[key].size > 0
          return [key, data[key].pop]
        end
      end
      sleep(timeout.to_f)
      nil
    end

    def rpoplpush(key1, key2)
      data_type_check(key1, Array)
      rpop(key1).tap do |elem|
        lpush(key2, elem) unless elem.nil?
      end
    end

    def brpoplpush(key1, key2, opts = {})
      data_type_check(key1, Array)
      brpop(key1).tap do |elem|
        lpush(key2, elem) unless elem.nil?
      end
    end

    def lpop(key)
      data_type_check(key, Array)
      return unless data[key]
      data[key].shift
    end

    def blpop(keys, timeout = 0)
      keys = Array(keys)
      keys.each do |key|
        if data[key] && data[key].size > 0
          return [key, data[key].shift]
        end
      end
      sleep(timeout.to_f)
      nil
    end

    def smembers(key)
      data_type_check(key, ::Set)
      return [] unless data[key]
      data[key].to_a.reverse
    end

    def sismember(key, value)
      data_type_check(key, ::Set)
      return false unless data[key]
      data[key].include?(value.to_s)
    end

    def sadd(key, value)
      data_type_check(key, ::Set)
      value = Array(value)
      raise_argument_error('sadd') if value.empty?

      result = if data[key]
        old_set = data[key].dup
        data[key].merge(value.map(&:to_s))
        (data[key] - old_set).size
      else
        data[key] = ::Set.new(value.map(&:to_s))
        data[key].size
      end

      # 0 = false, 1 = true, 2+ untouched
      return result == 1 if result < 2
      result
    end

    def srem(key, value)
      data_type_check(key, ::Set)
      return false unless data[key]

      if value.is_a?(Array)
        old_size = data[key].size
        value.map(&:to_s).each { |v| data[key].delete(v) }
        deleted = old_size - data[key].size
      else
        deleted = !!data[key].delete?(value.to_s)
      end

      remove_key_for_empty_collection(key)
      deleted
    end

    def smove(source, destination, value)
      data_type_check(destination, ::Set)
      result = self.srem(source, value)
      self.sadd(destination, value) if result
      result
    end

    def spop(key)
      data_type_check(key, ::Set)
      elem = srandmember(key)
      srem(key, elem)
      elem
    end

    def scard(key)
      data_type_check(key, ::Set)
      return 0 unless data[key]
      data[key].size
    end

    def sinter(*keys)
      raise_argument_error('sinter') if keys.empty?

      keys.each { |k| data_type_check(k, ::Set) }
      return ::Set.new if keys.any? { |k| data[k].nil? }
      keys = keys.map { |k| data[k] || ::Set.new }
      keys.inject do |set, key|
        set & key
      end.to_a
    end

    def sinterstore(destination, *keys)
      data_type_check(destination, ::Set)
      result = sinter(*keys)
      data[destination] = ::Set.new(result)
    end

    def sunion(*keys)
      keys.each { |k| data_type_check(k, ::Set) }
      keys = keys.map { |k| data[k] || ::Set.new }
      keys.inject(::Set.new) do |set, key|
        set | key
      end.to_a
    end

    def sunionstore(destination, *keys)
      data_type_check(destination, ::Set)
      result = sunion(*keys)
      data[destination] = ::Set.new(result)
    end

    def sdiff(key1, *keys)
      [key1, *keys].each { |k| data_type_check(k, ::Set) }
      keys = keys.map { |k| data[k] || ::Set.new }
      keys.inject(data[key1] || Set.new) do |memo, set|
        memo - set
      end.to_a
    end

    def sdiffstore(destination, key1, *keys)
      data_type_check(destination, ::Set)
      result = sdiff(key1, *keys)
      data[destination] = ::Set.new(result)
    end

    def srandmember(key, number = nil)
      number.nil? ? srandmember_single(key) : srandmember_multiple(key, number)
    end

    def sscan(key, start_cursor, *args)
      data_type_check(key, ::Set)
      return ['0', []] unless data[key]

      match = '*'
      count = 10

      if args.size.odd?
        raise_argument_error('sscan')
      end

      if idx = args.index('MATCH')
        match = args[idx + 1]
      end

      if idx = args.index('COUNT')
        count = args[idx + 1]
      end

      start_cursor = start_cursor.to_i

      cursor = start_cursor
      next_keys = []

      if start_cursor + count >= data[key].length
        next_keys = (data[key].to_a)[start_cursor..-1]
        cursor = 0
      else
        cursor = start_cursor + count
        next_keys = (data[key].to_a)[start_cursor..cursor-1]
      end

      filtered_next_keys = next_keys.select{ |k,v| File.fnmatch(match, k)}
      result = filtered_next_keys.flatten.map(&:to_s)

      return ["#{cursor}", result]
    end

    def del(*keys)
      keys = keys.flatten(1)
      raise_argument_error('del') if keys.empty?

      old_count = data.keys.size
      keys.each do |key|
        data.delete(key)
      end
      old_count - data.keys.size
    end

    def setnx(key, value)
      if exists(key)
        0
      else
        set(key, value)
        1
      end
    end

    def rename(key, new_key)
      return unless data[key]
      data[new_key] = data[key]
      data.expires[new_key] = data.expires[key] if data.expires.include?(key)
      data.delete(key)
    end

    def renamenx(key, new_key)
      if exists(new_key)
        false
      else
        rename(key, new_key)
        true
      end
    end

    def expire(key, ttl)
      return 0 unless data[key]
      data.expires[key] = Time.now + ttl
      1
    end

    def pexpire(key, ttl)
      return 0 unless data[key]

      data.expires[key] = Time.now + (ttl / 1000.0)

      1
    end

    def ttl(key)
      if data.expires.include?(key) && (ttl = data.expires[key].to_i - Time.now.to_i) > 0
        ttl
      else
        exists(key) ? -1 : -2
      end
    end

    def pttl(key)
      if data.expires.include?(key) && (ttl = data.expires[key].to_f - Time.now.to_f) > 0
        ttl * 1000
      else
        exists(key) ? -1 : -2
      end
    end

    def expireat(key, timestamp)
      data.expires[key] = Time.at(timestamp)
      true
    end

    def persist(key)
      !!data.expires.delete(key)
    end

    def hset(key, field, value)
      data_type_check(key, Hash)
      field = field.to_s
      if data[key]
        result = !data[key].include?(field)
        data[key][field] = value.to_s
        result
      else
        data[key] = { field => value.to_s }
        true
      end
    end

    def hsetnx(key, field, value)
      data_type_check(key, Hash)
      field = field.to_s
      return false if data[key] && data[key][field]
      hset(key, field, value)
    end

    def hmset(key, *fields)
      fields = fields[0] if mapped_param?(fields)
      raise_argument_error('hmset') if fields.empty?

      is_list_of_arrays = fields.all?{|field| field.instance_of?(Array)}

      raise_argument_error('hmset') if fields.size.odd? and !is_list_of_arrays
      raise_argument_error('hmset') if is_list_of_arrays and !fields.all?{|field| field.length == 2}

      data_type_check(key, Hash)
      data[key] ||= {}

      if is_list_of_arrays
        fields.each do |pair|
          data[key][pair[0].to_s] = pair[1].to_s
        end
      else
        fields.each_slice(2) do |field|
          data[key][field[0].to_s] = field[1].to_s
        end
      end
    end

    def hmget(key, *fields)
      raise_argument_error('hmget') if fields.empty?

      data_type_check(key, Hash)
      fields.flatten.map do |field|
        field = field.to_s
        if data[key]
          data[key][field]
        else
          nil
        end
      end
    end

    def hlen(key)
      data_type_check(key, Hash)
      return 0 unless data[key]
      data[key].size
    end

    def hvals(key)
      data_type_check(key, Hash)
      return [] unless data[key]
      data[key].values
    end

    def hincrby(key, field, increment)
      data_type_check(key, Hash)
      field = field.to_s
      if data[key]
        data[key][field] = (data[key][field].to_i + increment.to_i).to_s
      else
        data[key] = { field => increment.to_s }
      end
      data[key][field].to_i
    end

    def hincrbyfloat(key, field, increment)
      data_type_check(key, Hash)
      field = field.to_s
      if data[key]
        data[key][field] = (data[key][field].to_f + increment.to_f).to_s
      else
        data[key] = { field => increment.to_s }
      end
      data[key][field]
    end

    def hexists(key, field)
      data_type_check(key, Hash)
      return false unless data[key]
      data[key].key?(field.to_s)
    end

    def sync ; end

    def [](key)
      get(key)
    end

    def []=(key, value)
      set(key, value)
    end

    def set(key, value, *array_options)
      option_nx = array_options.delete('NX')
      option_xx = array_options.delete('XX')

      return false if option_nx && option_xx

      return false if option_nx && exists(key)
      return false if option_xx && !exists(key)

      data[key] = value.to_s

      options = Hash[array_options.each_slice(2).to_a]
      ttl_in_seconds = options['EX'] if options['EX']
      ttl_in_seconds = options['PX'] / 1000.0 if options['PX']

      expire(key, ttl_in_seconds) if ttl_in_seconds

      'OK'
    end

    def setbit(key, offset, bit)
      old_val = data[key] ? data[key].unpack('B*')[0].split('') : []
      size_increment = [((offset/8)+1)*8-old_val.length, 0].max
      old_val += Array.new(size_increment).map{'0'}
      original_val = old_val[offset].to_i
      old_val[offset] = bit.to_s
      new_val = ''
      old_val.each_slice(8){|b| new_val = new_val + b.join('').to_i(2).chr }
      data[key] = new_val
      original_val
    end

    def setex(key, seconds, value)
      data[key] = value.to_s
      expire(key, seconds)

      'OK'
    end

    def setrange(key, offset, value)
      return unless data[key]
      s = data[key][offset,value.size]
      data[key][s] = value
    end

    def mset(*pairs)
      # Handle pairs for mapped_mset command
      pairs = pairs[0] if mapped_param?(pairs)
      raise_argument_error('mset') if pairs.empty? || pairs.size == 1
      # We have to reply with a different error message here to be consistent with
      # redis-rb 3.0.6 / redis-server 2.8.1.
      raise_argument_error('mset', 'mset_odd') if pairs.size.odd?

      pairs.each_slice(2) do |pair|
        data[pair[0].to_s] = pair[1].to_s
      end

      'OK'
    end

    def msetnx(*pairs)
      # Handle pairs for mapped_msetnx command
      pairs = pairs[0] if mapped_param?(pairs)
      keys = []
      pairs.each_with_index{|item, index| keys << item.to_s if index % 2 == 0}
      return false if keys.any?{|key| data.key?(key) }
      mset(*pairs)
      true
    end

    def incr(key)
      data.merge!({ key => (data[key].to_i + 1).to_s || '1'})
      data[key].to_i
    end

    def incrby(key, by)
      data.merge!({ key => (data[key].to_i + by.to_i).to_s || by })
      data[key].to_i
    end

    def incrbyfloat(key, by)
      data.merge!({ key => (data[key].to_f + by.to_f).to_s || by })
      data[key]
    end

    def decr(key)
      data.merge!({ key => (data[key].to_i - 1).to_s || '-1'})
      data[key].to_i
    end

    def decrby(key, by)
      data.merge!({ key => ((data[key].to_i - by.to_i) || (by.to_i * -1)).to_s })
      data[key].to_i
    end

    def type(key)
      case data[key]
        when nil then 'none'
        when String then 'string'
        when ZSet then 'zset'
        when Hash then 'hash'
        when Array then 'list'
        when ::Set then 'set'
      end
    end

    def quit
    end

    def shutdown
    end

    def slaveof(host, port)
    end

    def scan(start_cursor, *args)
      match = '*'
      count = 10

      if args.size.odd?
        raise_argument_error('scan')
      end

      if idx = args.index('MATCH')
        match = args[idx + 1]
      end

      if idx = args.index('COUNT')
        count = args[idx + 1]
      end

      start_cursor = start_cursor.to_i
      data_type_check(start_cursor, Integer)

      cursor = start_cursor
      next_keys = []

      if start_cursor + count >= data.length
        next_keys = keys(match)[start_cursor..-1]
        cursor = 0
      else
        cursor = start_cursor + 10
        next_keys = keys(match)[start_cursor..cursor]
      end

      return "#{cursor}", next_keys
    end

    def zadd(key, *args)
      if !args.first.is_a?(Array)
        if args.size < 2
          raise_argument_error('zadd')
        elsif args.size.odd?
          raise_syntax_error
        end
      else
        unless args.all? {|pair| pair.size == 2 }
          raise_syntax_error
        end
      end

      data_type_check(key, ZSet)
      data[key] ||= ZSet.new

      if args.size == 2 && !(Array === args.first)
        score, value = args
        exists = !data[key].key?(value.to_s)
        data[key][value.to_s] = score
      else
        # Turn [1, 2, 3, 4] into [[1, 2], [3, 4]] unless it is already
        args = args.each_slice(2).to_a unless args.first.is_a?(Array)
        exists = args.map(&:last).map { |el| data[key].key?(el.to_s) }.count(false)
        args.each { |s, v| data[key][v.to_s] = s }
      end

      exists
    end

    def zrem(key, value)
      data_type_check(key, ZSet)
      values = Array(value)
      return 0 unless data[key]

      response = values.map do |v|
        data[key].delete(v.to_s) if data[key].has_key?(v.to_s)
      end.compact.size

      remove_key_for_empty_collection(key)
      response
    end

    def zcard(key)
      data_type_check(key, ZSet)
      data[key] ? data[key].size : 0
    end

    def zcount(key, min, max)
      data_type_check(key, ZSet)
      return 0 unless data[key]
      data[key].select_by_score(min, max).size
    end

    def zrank(key, value)
      data_type_check(key, ZSet)
      z = data[key]
      return unless z
      z.keys.sort_by {|k| z[k] }.index(value.to_s)
    end

    def zrevrank(key, value)
      data_type_check(key, ZSet)
      z = data[key]
      return unless z
      z.keys.sort_by {|k| -z[k] }.index(value.to_s)
    end

    def zrange(key, start, stop, with_scores = nil)
      data_type_check(key, ZSet)
      return [] unless data[key]

      results = sort_keys(data[key])

      # Select just the keys unless we want scores
      results = results.map(&:first) unless with_scores
      results[start..stop].flatten.map(&:to_s)
    end

    def zrevrange(key, start, stop, with_scores = nil)
      data_type_check(key, ZSet)
      return [] unless data[key]

      if with_scores
        data[key].sort_by {|_,v| -v }
      else
        data[key].keys.sort_by {|k| -data[key][k] }
      end[start..stop].flatten.map(&:to_s)
    end

    def zrangebyscore(key, min, max, *opts)
      data_type_check(key, ZSet)
      return [] unless data[key]

      range = data[key].select_by_score(min, max)
      vals = if opts.include?('WITHSCORES')
        range.sort_by {|_,v| v }
      else
        range.keys.sort_by {|k| range[k] }
      end

      limit = get_limit(opts, vals)
      vals = vals[*limit] if limit

      vals.flatten.map(&:to_s)
    end

    def zrevrangebyscore(key, max, min, *opts)
      opts = opts.flatten
      data_type_check(key, ZSet)
      return [] unless data[key]

      range = data[key].select_by_score(min, max)
      vals = if opts.include?('WITHSCORES')
        range.sort_by {|_,v| -v }
      else
        range.keys.sort_by {|k| -range[k] }
      end

      limit = get_limit(opts, vals)
      vals = vals[*limit] if limit

      vals.flatten.map(&:to_s)
    end

    def zremrangebyscore(key, min, max)
      data_type_check(key, ZSet)
      return 0 unless data[key]

      range = data[key].select_by_score(min, max)
      range.each {|k,_| data[key].delete(k) }
      range.size
    end

    def zremrangebyrank(key, start, stop)
      data_type_check(key, ZSet)
      return 0 unless data[key]

      sorted_elements = data[key].sort_by { |k, v| v }
      start = sorted_elements.length if start > sorted_elements.length
      elements_to_delete = sorted_elements[start..stop]
      elements_to_delete.each { |elem, rank| data[key].delete(elem) }
      elements_to_delete.size
    end

    def zinterstore(out, *args)
      data_type_check(out, ZSet)
      args_handler = SortedSetArgumentHandler.new(args)
      data[out] = SortedSetIntersectStore.new(args_handler, data).call
      data[out].size
    end

    def zunionstore(out, *args)
      data_type_check(out, ZSet)
      args_handler = SortedSetArgumentHandler.new(args)
      data[out] = SortedSetUnionStore.new(args_handler, data).call
      data[out].size
    end

    def zscan(key, start_cursor, *args)
      data_type_check(key, ZSet)
      return [] unless data[key]

      match = '*'
      count = 10

      if args.size.odd?
        raise_argument_error('zscan')
      end

      if idx = args.index('MATCH')
        match = args[idx + 1]
      end

      if idx = args.index('COUNT')
        count = args[idx + 1]
      end

      start_cursor = start_cursor.to_i
      data_type_check(start_cursor, Integer)

      cursor = start_cursor
      next_keys = []

      sorted_keys = sort_keys(data[key])

      if start_cursor + count >= sorted_keys.length
        next_keys = sorted_keys.to_a.select { |k| File.fnmatch(match, k[0]) } [start_cursor..-1]
        cursor = 0
      else
       cursor = start_cursor + count
       next_keys = sorted_keys.to_a.select { |k| File.fnmatch(match, k[0]) } [start_cursor..cursor-1]
      end

      return "#{cursor}", next_keys.flatten.map(&:to_s)
    end

    # Originally from redis-rb
    def zscan_each(key, *args, &block)
      data_type_check(key, ZSet)
      return [] unless data[key]

      return to_enum(:zscan_each, key, options) unless block_given?
      cursor = 0
      loop do
        cursor, values = zscan(key, cursor, options)
        values.each(&block)
        break if cursor == '0'
      end
    end

    private
    def raise_argument_error(command, match_string = command)
      error_message = if %w(hmset mset_odd).include?(match_string.downcase)
        "ERR wrong number of arguments for #{command.upcase}"
      else
        "ERR wrong number of arguments for '#{command}' command"
      end

      raise Redis::CommandError, error_message
    end

    def raise_syntax_error
      raise Redis::CommandError, 'ERR syntax error'
    end

    def remove_key_for_empty_collection(key)
      del(key) if data[key] && data[key].empty?
    end

    def data_type_check(key, klass)
      if data[key] && !data[key].is_a?(klass)
        raise Redis::CommandError.new('WRONGTYPE Operation against a key holding the wrong kind of value')
      end
    end

    def get_limit(opts, vals)
      index = opts.index('LIMIT')

      if index
        offset = opts[index + 1]

        count = opts[index + 2]
        count = vals.size if count < 0

        [offset, count]
      end
    end

    def mapped_param? param
      param.size == 1 && param[0].is_a?(Array)
    end

    def srandmember_single(key)
      data_type_check(key, ::Set)
      return nil unless data[key]
      data[key].to_a[rand(data[key].size)]
    end

    def srandmember_multiple(key, number)
      return [] unless data[key]
      if number >= 0
        data[key].to_a.sample(number)
      else
        (1..-number).map { data[key].to_a[rand(data[key].size)] }.flatten
      end
    end

    def sort_keys(arr)
      # Sort by score, or if scores are equal, key alphanum
      arr.sort do |(k1, v1), (k2, v2)|
        if v1 == v2
          k1 <=> k2
        else
          v1 <=> v2
        end
      end
    end
  end
end
