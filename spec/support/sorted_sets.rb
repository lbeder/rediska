shared_examples 'sorted sets' do
  it 'should error with wrong number of arguments when adding members' do
    expect {
      subject.zadd('key')
    }.to raise_error(ArgumentError)

    expect {
      subject.zadd('key', 1)
    }.to raise_error(ArgumentError)

    expect {
      subject.zadd('key', [1])
    }.to raise_error(Redis::CommandError)

    expect {
      subject.zadd('key', [1, 'val', 2])
    }.to raise_error(Redis::CommandError)

    expect {
      subject.zadd('key', [[1, 'val'], [2]])
    }.to raise_error(Redis::CommandError)
  end

  it 'should remove members from sorted sets' do
    expect(subject.zrem('key', 'val')).to be_falsey
    expect(subject.zadd('key', 1, 'val')).to be_truthy
    expect(subject.zrem('key', 'val')).to be_truthy
  end

  it 'should remove multiple members from sorted sets' do
    expect(subject.zrem('key2', %w(val))).to eq(0)
    expect(subject.zrem('key2', %w(val val2 val3))).to eq(0)

    subject.zadd('key2', 1, 'val')
    subject.zadd('key2', 1, 'val2')
    subject.zadd('key2', 1, 'val3')

    expect(subject.zrem('key2', %w(val val2 val3 val4))).to eq(3)
  end

  it "should remove sorted set's key when it is empty" do
    subject.zadd('key', 1, 'val')
    subject.zrem('key', 'val')
    expect(subject.exists('key')).to eq(0)
  end

  it 'should get the number of members in a sorted set' do
    subject.zadd('key', 1, 'val2')
    subject.zadd('key', 2, 'val1')
    subject.zadd('key', 5, 'val3')

    expect(subject.zcard('key')).to eq(3)
  end

  it 'should count the members in a sorted set with scores within the given values' do
    subject.zadd('key', 1, 'val1')
    subject.zadd('key', 2, 'val2')
    subject.zadd('key', 3, 'val3')

    expect(subject.zcount('key', 2, 3)).to eq(2)
  end

  it 'should return a range of members in a sorted set, by index' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrange('key', 0, -1)).to eq(['one', 'two', 'three'])
    expect(subject.zrange('key', 1, 2)).to eq(['two', 'three'])
    expect(subject.zrange('key', 0, -1, with_scores: true)).to eq([['one', 1], ['two', 2], ['three', 3]])
    expect(subject.zrange('key', 1, 2, with_scores: true)).to eq([['two', 2], ['three', 3]])
  end

  it 'should sort zrange results logically' do
    subject.zadd('key', 5, 'val2')
    subject.zadd('key', 5, 'val3')
    subject.zadd('key', 5, 'val1')

    expect(subject.zrange('key', 0, -1)).to eq(%w(val1 val2 val3))
    expect(subject.zrange('key', 0, -1, with_scores: true)).to eq([['val1', 5], ['val2', 5], ['val3', 5]])
  end

  it 'should return a reversed range of members in a sorted set, by index' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrevrange('key', 0, -1)).to eq(['three', 'two', 'one'])
    expect(subject.zrevrange('key', 1, 2)).to eq(['two', 'one'])
    expect(subject.zrevrange('key', 0, -1, with_scores: true)).to eq([['three', 3], ['two', 2], ['one', 1]])
    expect(subject.zrevrange('key', 0, -1, with_scores: true)).to eq([['three', 3], ['two', 2], ['one', 1]])
  end

  it 'should return a range of members in a sorted set, by score' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrangebyscore('key', 0, 100)).to eq(['one', 'two', 'three'])
    expect(subject.zrangebyscore('key', 1, 2)).to eq(['one', 'two'])
    expect(subject.zrangebyscore('key', 1, '(2')).to eq(['one'])
    expect(subject.zrangebyscore('key', '(1', 2)).to eq(['two'])
    expect(subject.zrangebyscore('key', '(1', '(2')).to eq([])
    expect(subject.zrangebyscore('key', 0, 100, with_scores: true)).to eq([['one', 1], ['two', 2], ['three', 3]])
    expect(subject.zrangebyscore('key', 1, 2, with_scores: true)).to eq([['one', 1], ['two', 2]])
    expect(subject.zrangebyscore('key', 0, 100, limit: [0, 1])).to eq(['one'])
    expect(subject.zrangebyscore('key', 0, 100, limit: [0, -1])).to eq(['one', 'two', 'three'])
    expect(subject.zrangebyscore('key', 0, 100, limit: [1, -1], with_scores: true)).to eq([['two', 2], ['three', 3]])
    expect(subject.zrangebyscore('key', '-inf', '+inf')).to eq(['one', 'two', 'three'])
    expect(subject.zrangebyscore('key', 2, '+inf')).to eq(['two', 'three'])
    expect(subject.zrangebyscore('key', '-inf', 2)).to eq(['one', 'two'])

    expect(subject.zrangebyscore('badkey', 1, 2)).to eq([])
  end

  it 'should return a reversed range of members in a sorted set, by score' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrevrangebyscore('key', 100, 0)).to eq(['three', 'two', 'one'])
    expect(subject.zrevrangebyscore('key', 2, 1)).to eq(['two', 'one'])
    expect(subject.zrevrangebyscore('key', 1, 2)).to be_empty
    expect(subject.zrevrangebyscore('key', 2, 1, with_scores: true)).to eq([['two', 2.0], ['one', 1.0]])
    expect(subject.zrevrangebyscore('key', 100, 0, limit: [0, 1])).to eq(['three'])
    expect(subject.zrevrangebyscore('key', 100, 0, limit: [0, -1])).to eq(['three', 'two', 'one'])
    expect(subject.zrevrangebyscore('key', 100, 0, limit: [1, -1], with_scores: true)).to eq([['two', 2.0], ['one', 1.0]])
  end

  it 'should determine the index of a member in a sorted set' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrank('key', 'three')).to eq(2)
    expect(subject.zrank('key', 'four')).to be_nil
  end

  it 'should determine the reversed index of a member in a sorted set' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    expect(subject.zrevrank('key', 'three')).to eq(0)
    expect(subject.zrevrank('key', 'four')).to be_nil
  end

  it 'should not raise errors for zrank() on accessing a non-existing key in a sorted set' do
    expect(subject.zrank('no_such_key', 'no_suck_id')).to be_nil
  end

  it 'should not raise errors for zrevrank() on accessing a non-existing key in a sorted set' do
    expect(subject.zrevrank('no_such_key', 'no_suck_id')).to be_nil
  end

  describe '#zinterstore' do
    before do
      subject.zadd('key1', 1, 'one')
      subject.zadd('key1', 2, 'two')
      subject.zadd('key1', 3, 'three')
      subject.zadd('key2', 5, 'two')
      subject.zadd('key2', 7, 'three')
      subject.sadd('key3', 'one')
      subject.sadd('key3', 'two')
    end

    it 'should intersect two keys with custom scores' do
      expect(subject.zinterstore('out', ['key1', 'key2'])).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', (2 + 5)], ['three', (3 + 7)]])
    end

    it 'should intersect two keys with a default score' do
      expect(subject.zinterstore('out', ['key1', 'key3'])).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['one', (1 + 1)], ['two', (2 + 1)]])
    end

    it 'should intersect more than two keys' do
      expect(subject.zinterstore('out', ['key1', 'key2', 'key3'])).to eq(1)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', (2 + 5 + 1)]])
    end

    it 'should not intersect an unknown key' do
      expect(subject.zinterstore('out', ['key1', 'no_key'])).to eq(0)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to be_empty
    end

    it 'should intersect two keys by minimum values' do
      expect(subject.zinterstore('out', ['key1', 'key2'], aggregate: :min)).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', 2], ['three', 3]])
    end

    it 'should intersect two keys by maximum values' do
      expect(subject.zinterstore('out', ['key1', 'key2'], aggregate: :max)).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', 5], ['three', 7]])
    end

    it 'should intersect two keys by explicitly summing values' do
      expect(subject.zinterstore('out', %w(key1 key2), aggregate: :sum)).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', (2 + 5)], ['three', (3 + 7)]])
    end

    it 'should intersect two keys with weighted values' do
      expect(subject.zinterstore('out', %w(key1 key2), weights: [10, 1])).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', (2 * 10 + 5)], ['three', (3 * 10 + 7)]])
    end

    it 'should intersect two keys with weighted minimum values' do
      expect(subject.zinterstore('out', %w(key1 key2), weights: [10, 1], aggregate: :min)).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', 5], ['three', 7]])
    end

    it 'should intersect two keys with weighted maximum values' do
      expect(subject.zinterstore('out', %w(key1 key2), weights: [10, 1], aggregate: :max)).to eq(2)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['two', (2 * 10)], ['three', (3 * 10)]])
    end

    it 'should error without enough weights given' do
      expect {
        subject.zinterstore('out', %w(key1 key2), weights: [])
      }.to raise_error(Redis::CommandError)

      expect {
        subject.zinterstore('out', %w(key1 key2), weights: [10])
      }.to raise_error(Redis::CommandError)
    end

    it 'should error with too many weights given' do
      expect {
        subject.zinterstore('out', %w(key1 key2), weights: [10, 1, 1])
      }.to raise_error(Redis::CommandError)
    end

    it 'should error with an invalid aggregate' do
      expect {
        subject.zinterstore('out', %w(key1 key2), aggregate: :invalid)
      }.to raise_error(Redis::CommandError)
    end
  end

  describe 'zremrangebyscore' do
    it 'should remove items by score' do
      subject.zadd('key', 1, 'one')
      subject.zadd('key', 2, 'two')
      subject.zadd('key', 3, 'three')

      expect(subject.zremrangebyscore('key', 0, 2)).to eq(2)
      expect(subject.zcard('key')).to eq(1)
    end

    it 'should return 0 if the key did not exist' do
      expect(subject.zremrangebyscore('key', 0, 2)).to eq(0)
    end
  end

  describe '#zremrangebyrank' do
    it 'removes all elements with in the given range' do
      subject.zadd('key', 1, 'one')
      subject.zadd('key', 2, 'two')
      subject.zadd('key', 3, 'three')

      expect(subject.zremrangebyrank('key', 0, 1)).to eq(2)
      expect(subject.zcard('key')).to eq(1)
    end

    it 'handles out of range requests' do
      subject.zadd('key', 1, 'one')
      subject.zadd('key', 2, 'two')
      subject.zadd('key', 3, 'three')

      expect(subject.zremrangebyrank('key', 25, -1)).to eq(0)
      expect(subject.zcard('key')).to eq(3)
    end

    it "should return 0 if the key didn't exist" do
      expect(subject.zremrangebyrank('key', 0, 1)).to eq(0)
    end
  end

  describe '#zunionstore' do
    before do
      subject.zadd('key1', 1, 'val1')
      subject.zadd('key1', 2, 'val2')
      subject.zadd('key1', 3, 'val3')
      subject.zadd('key2', 5, 'val2')
      subject.zadd('key2', 7, 'val3')
      subject.sadd('key3', 'val1')
      subject.sadd('key3', 'val2')
    end

    it 'should union two keys with custom scores' do
      expect(subject.zunionstore('out', %w(key1 key2))).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', 1], ['val2', (2 + 5)], ['val3', (3 + 7)]])
    end

    it 'should union two keys with a default score' do
      expect(subject.zunionstore('out', %w(key1 key3))).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', (1 + 1)], ['val2', (2 + 1)], ['val3', 3]])
    end

    it 'should union more than two keys' do
      expect(subject.zunionstore('out', %w(key1 key2 key3))).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', (1 + 1)], ['val2', (2 + 5 + 1)], ['val3', (3 + 7)]])
    end

    it 'should union with an unknown key' do
      expect(subject.zunionstore('out', %w(key1 no_key))).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', 1], ['val2', 2], ['val3', 3]])
    end

    it 'should union two keys by minimum values' do
      expect(subject.zunionstore('out', %w(key1 key2), aggregate: :min)).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', 1], ['val2', 2], ['val3', 3]])
    end

    it 'should union two keys by maximum values' do
      expect(subject.zunionstore('out', %w(key1 key2), aggregate: :max)).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', 1], ['val2', 5], ['val3', 7]])
    end

    it 'should union two keys by explicitly summing values' do
      expect(subject.zunionstore('out', %w(key1 key2), aggregate: :sum)).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', 1], ['val2', (2 + 5)], ['val3', (3 + 7)]])
    end

    it 'should union two keys with weighted values' do
      expect(subject.zunionstore('out', %w(key1 key2), :weights => [10, 1])).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', (1 * 10)], ['val2', (2 * 10 + 5)], ['val3', (3 * 10 + 7)]])
    end

    it 'should union two keys with weighted minimum values' do
      expect(subject.zunionstore('out', %w(key1 key2), weights: [10, 1], aggregate: :min)).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val2', 5], ['val3', 7], ['val1', (1 * 10)]])
    end

    it 'should union two keys with weighted maximum values' do
      expect(subject.zunionstore('out', %w(key1 key2), weights: [10, 1], aggregate: :max)).to eq(3)
      expect(subject.zrange('out', 0, -1, with_scores: true)).to eq([['val1', (1 * 10)], ['val2', (2 * 10)], ['val3', (3 * 10)]])
    end

    it 'should error without enough weights given' do
      expect {
        subject.zunionstore('out', %w(key1 key2), weights: [])
      }.to raise_error(Redis::CommandError)

      expect {
        subject.zunionstore('out', %w(key1 key2), weights: [10])
      }.to raise_error(Redis::CommandError)
    end

    it 'should error with too many weights given' do
      expect {
        subject.zunionstore('out', %w(key1 key2), weights: [10, 1, 1])
      }.to raise_error(Redis::CommandError)
    end

    it 'should error with an invalid aggregate' do
      expect {
        subject.zunionstore('out', %w(key1 key2), aggregate: :invalid)
      }.to raise_error(Redis::CommandError)
    end
  end

  describe '#zscan' do
    before do
      50.times { |x| subject.zadd('key', x, "key #{x}") }
    end

    it 'with no arguments should return 10 numbers in ascending order' do
      result = subject.zscan('key', 0)[1]
      expect(result).to eq(result.sort { |x, y| x[1] <=> y[1] })
      expect(result.count).to eq(10)
    end

    it 'with a count should return that number of members' do
      expect(subject.zscan('key', 0, count: 2)).to eq(['2', [['key 0', 0.0], ['key 1', 1.0]]])
    end

    it 'with a count greater than the number of members, returns all the members in asc order' do
      result = subject.zscan('key', 0, count: 1000)[1]
      expect(result).to eq(result.sort { |x, y| x[1] <=> y[1] })
      expect(result.size).to eq(50)
    end

    it 'with match, should return key-values where the key matches' do
      subject.zadd('key', 1.0, 'blah')
      subject.zadd('key', 2.0, 'bluh')
      result = subject.zscan('key', 0, count: 100, match: 'key*')[1]
      expect(result).to_not include(['blah', 1.0])
      expect(result).to_not include(['bluh', 2.0])
    end
  end

  describe '#zscan_each' do
    before do
      50.times { |x| subject.zadd('key', x, "key #{x}") }
    end

    it 'enumerates over the items in the sorted set' do
      expect(subject.zscan_each('key').to_a).to eq(subject.zscan('key', 0, count: 50)[1])
    end
  end

  #it 'should remove all members in a sorted set within the given indexes'
  #it 'should return a range of members in a sorted set, by index, with scores ordered from high to low'
  #it 'should return a range of members in a sorted set, by score, with scores ordered from high to low'
  #it 'should determine the index of a member in a sorted set, with scores ordered from high to low'
  #it 'should get the score associated with the given member in a sorted set'
  #it 'should add multiple sorted sets and store the resulting sorted set in a new key'
end
