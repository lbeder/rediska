shared_examples 'sorted sets' do
  let(:infinity) { 1.0 / 0.0 }

  it 'should add a member to a sorted set, or update its score if it already exists' do
    subject.zadd('key', 1, 'val').should be_true
    subject.zscore('key', 'val').should eq(1.0)

    subject.zadd('key', 2, 'val').should be_false
    subject.zscore('key', 'val').should eq(2.0)

    subject.zadd('key2', 'inf', 'val').should be_true
    subject.zscore('key2', 'val').should eq(infinity)

    subject.zadd('key3', '+inf', 'val').should be_true
    subject.zscore('key3', 'val').should eq(infinity)

    subject.zadd('key4', '-inf', 'val').should be_true
    subject.zscore('key4', 'val').should eq(-infinity)
  end

  it 'should return a nil score for value not in a sorted set or empty key' do
    subject.zadd('key', 1, 'val')

    subject.zscore('key', 'val').should eq(1.0)
    subject.zscore('key', 'val2').should be_nil
    subject.zscore('key2', 'val').should be_nil
  end

  it 'should add multiple members to a sorted set, or update its score if it already exists' do
    subject.zadd('key', [1, 'val', 2, 'val2']).should eq(2)
    subject.zscore('key', 'val').should eq(1)
    subject.zscore('key', 'val2').should eq(2)

    subject.zadd('key', [[5, 'val'], [3, 'val3'], [4, 'val4']]).should eq(2)
    subject.zscore('key', 'val').should eq(5)
    subject.zscore('key', 'val2').should eq(2)
    subject.zscore('key', 'val3').should eq(3)
    subject.zscore('key', 'val4').should eq(4)

    subject.zadd('key', [[5, 'val5'], [3, 'val6']]).should eq(2)
    subject.zscore('key', 'val5').should eq(5)
    subject.zscore('key', 'val6').should eq(3)
  end

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

  it 'should allow floats as scores when adding or updating' do
    subject.zadd('key', 4.321, 'val').should be_true
    subject.zscore('key', 'val').should eq(4.321)

    subject.zadd('key', 54.3210, 'val').should be_false
    subject.zscore('key', 'val').should eq(54.321)
  end

  it 'should remove members from sorted sets' do
    subject.zrem('key', 'val').should be_false
    subject.zadd('key', 1, 'val').should be_true
    subject.zrem('key', 'val').should be_true
  end

  it 'should remove multiple members from sorted sets' do
    subject.zrem('key2', %w(val)).should eq(0)
    subject.zrem('key2', %w(val val2 val3)).should eq(0)

    subject.zadd('key2', 1, 'val')
    subject.zadd('key2', 1, 'val2')
    subject.zadd('key2', 1, 'val3')

    subject.zrem('key2', %w(val val2 val3 val4)).should eq(3)
  end

  it "should remove sorted set's key when it is empty" do
    subject.zadd('key', 1, 'val')
    subject.zrem('key', 'val')
    subject.exists('key').should be_false
  end

  it 'should get the number of members in a sorted set' do
    subject.zadd('key', 1, 'val2')
    subject.zadd('key', 2, 'val1')
    subject.zadd('key', 5, 'val3')

    subject.zcard('key').should eq(3)
  end

  it 'should count the members in a sorted set with scores within the given values' do
    subject.zadd('key', 1, 'val1')
    subject.zadd('key', 2, 'val2')
    subject.zadd('key', 3, 'val3')

    subject.zcount('key', 2, 3).should eq(2)
  end

  it 'should increment the score of a member in a sorted set' do
    subject.zadd('key', 1, 'val1')
    subject.zincrby('key', 2, 'val1').should eq(3)
    subject.zscore('key', 'val1').should eq(3)
  end

  it 'initializes the sorted set if the key wasnt already set' do
    subject.zincrby('key', 1, 'val1').should eq(1)
  end

  it 'should convert the key to a string for zscore' do
    subject.zadd('key', 1, 1)
    subject.zscore('key', 1).should eq(1)
  end

  it 'should handle infinity values when incrementing a sorted set key' do
    subject.zincrby('bar', '+inf', 's2').should eq(infinity)
    subject.zincrby('bar', '-inf', 's1').should eq(-infinity)
  end

  it 'should return a range of members in a sorted set, by index' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrange('key', 0, -1).should eq(['one', 'two', 'three'])
    subject.zrange('key', 1, 2).should eq(['two', 'three'])
    subject.zrange('key', 0, -1, with_scores: true).should eq([['one', 1], ['two', 2], ['three', 3]])
      subject.zrange('key', 1, 2, with_scores: true).should eq([['two', 2], ['three', 3]])
    end

  it 'should sort zrange results logically' do
    subject.zadd('key', 5, 'val2')
    subject.zadd('key', 5, 'val3')
    subject.zadd('key', 5, 'val1')

    subject.zrange('key', 0, -1).should eq(%w(val1 val2 val3))
    subject.zrange('key', 0, -1, with_scores: true).should eq([['val1', 5], ['val2', 5], ['val3', 5]])
  end

  it 'should return a reversed range of members in a sorted set, by index' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrevrange('key', 0, -1).should eq(['three', 'two', 'one'])
    subject.zrevrange('key', 1, 2).should eq(['two', 'one'])
    subject.zrevrange('key', 0, -1, with_scores: true).should eq([['three', 3], ['two', 2], ['one', 1]])
    subject.zrevrange('key', 0, -1, with_scores: true).should eq([['three', 3], ['two', 2], ['one', 1]])
  end

  it 'should return a range of members in a sorted set, by score' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrangebyscore('key', 0, 100).should eq(['one', 'two', 'three'])
    subject.zrangebyscore('key', 1, 2).should eq(['one', 'two'])
    subject.zrangebyscore('key', 1, '(2').should eq(['one'])
    subject.zrangebyscore('key', '(1', 2).should eq(['two'])
    subject.zrangebyscore('key', '(1', '(2').should eq([])
    subject.zrangebyscore('key', 0, 100, with_scores: true).should eq([['one', 1], ['two', 2], ['three', 3]])
    subject.zrangebyscore('key', 1, 2, with_scores: true).should eq([['one', 1], ['two', 2]])
    subject.zrangebyscore('key', 0, 100, limit: [0, 1]).should eq(['one'])
    subject.zrangebyscore('key', 0, 100, limit: [0, -1]).should eq(['one', 'two', 'three'])
    subject.zrangebyscore('key', 0, 100, limit: [1, -1], with_scores: true).should eq([['two', 2], ['three', 3]])
    subject.zrangebyscore('key', '-inf', '+inf').should eq(['one', 'two', 'three'])
    subject.zrangebyscore('key', 2, '+inf').should eq(['two', 'three'])
    subject.zrangebyscore('key', '-inf', 2).should eq(['one', 'two'])

    subject.zrangebyscore('badkey', 1, 2).should eq([])
  end

  it 'should return a reversed range of members in a sorted set, by score' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrevrangebyscore('key', 100, 0).should eq(['three', 'two', 'one'])
    subject.zrevrangebyscore('key', 2, 1).should eq(['two', 'one'])
    subject.zrevrangebyscore('key', 1, 2).should be_empty
    subject.zrevrangebyscore('key', 2, 1, with_scores: true).should eq([['two', 2.0], ['one', 1.0]])
    subject.zrevrangebyscore('key', 100, 0, limit: [0, 1]).should eq(['three'])
    subject.zrevrangebyscore('key', 100, 0, limit: [0, -1]).should eq(['three', 'two', 'one'])
    subject.zrevrangebyscore('key', 100, 0, limit: [1, -1], with_scores: true).should eq([['two', 2.0], ['one', 1.0]])
  end

  it 'should determine the index of a member in a sorted set' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrank('key', 'three').should eq(2)
    subject.zrank('key', 'four').should be_nil
  end

  it 'should determine the reversed index of a member in a sorted set' do
    subject.zadd('key', 1, 'one')
    subject.zadd('key', 2, 'two')
    subject.zadd('key', 3, 'three')

    subject.zrevrank('key', 'three').should eq(0)
    subject.zrevrank('key', 'four').should be_nil
  end

  it 'should not raise errors for zrank() on accessing a non-existing key in a sorted set' do
    subject.zrank('no_such_key', 'no_suck_id').should be_nil
  end

  it 'should not raise errors for zrevrank() on accessing a non-existing key in a sorted set' do
    subject.zrevrank('no_such_key', 'no_suck_id').should be_nil
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
      subject.zinterstore('out', ['key1', 'key2']).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', (2 + 5)], ['three', (3 + 7)]])
    end

    it 'should intersect two keys with a default score' do
      subject.zinterstore('out', ['key1', 'key3']).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['one', (1 + 1)], ['two', (2 + 1)]])
    end

    it 'should intersect more than two keys' do
      subject.zinterstore('out', ['key1', 'key2', 'key3']).should eq(1)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', (2 + 5 + 1)]])
    end

    it 'should not intersect an unknown key' do
      subject.zinterstore('out', ['key1', 'no_key']).should eq(0)
      subject.zrange('out', 0, -1, with_scores: true).should be_empty
    end

    it 'should intersect two keys by minimum values' do
      subject.zinterstore('out', ['key1', 'key2'], aggregate: :min).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', 2], ['three', 3]])
    end

    it 'should intersect two keys by maximum values' do
      subject.zinterstore('out', ['key1', 'key2'], aggregate: :max).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', 5], ['three', 7]])
    end

    it 'should intersect two keys by explicitly summing values' do
      subject.zinterstore('out', %w(key1 key2), aggregate: :sum).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', (2 + 5)], ['three', (3 + 7)]])
    end

    it 'should intersect two keys with weighted values' do
      subject.zinterstore('out', %w(key1 key2), weights: [10, 1]).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', (2 * 10 + 5)], ['three', (3 * 10 + 7)]])
    end

    it 'should intersect two keys with weighted minimum values' do
      subject.zinterstore('out', %w(key1 key2), weights: [10, 1], aggregate: :min).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', 5], ['three', 7]])
    end

    it 'should intersect two keys with weighted maximum values' do
      subject.zinterstore('out', %w(key1 key2), weights: [10, 1], aggregate: :max).should eq(2)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['two', (2 * 10)], ['three', (3 * 10)]])
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

      subject.zremrangebyscore('key', 0, 2).should eq(2)
      subject.zcard('key').should eq(1)
    end

    it 'should remove items by score with infinity' do # Issue #50
      subject.zadd('key', 10.0, 'one')
      subject.zadd('key', 20.0, 'two')
      subject.zadd('key', 30.0, 'three')
      subject.zremrangebyscore('key', '-inf', '+inf').should eq(3)
      subject.zcard('key').should eq(0)
      subject.zscore('key', 'one').should be_nil
      subject.zscore('key', 'two').should be_nil
      subject.zscore('key', 'three').should be_nil
    end

    it 'should return 0 if the key did not exist' do
      subject.zremrangebyscore('key', 0, 2).should eq(0)
    end
  end

  describe '#zremrangebyrank' do
    it 'removes all elements with in the given range' do
      subject.zadd('key', 1, 'one')
      subject.zadd('key', 2, 'two')
      subject.zadd('key', 3, 'three')

      subject.zremrangebyrank('key', 0, 1).should eq(2)
      subject.zcard('key').should eq(1)
    end

    it 'handles out of range requests' do
      subject.zadd('key', 1, 'one')
      subject.zadd('key', 2, 'two')
      subject.zadd('key', 3, 'three')

      subject.zremrangebyrank('key', 25, -1).should eq(0)
      subject.zcard('key').should eq(3)
    end

    it "should return 0 if the key didn't exist" do
      subject.zremrangebyrank('key', 0, 1).should eq(0)
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
      subject.zunionstore('out', %w(key1 key2)).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', 1], ['val2', (2 + 5)], ['val3', (3 + 7)]])
    end

    it 'should union two keys with a default score' do
      subject.zunionstore('out', %w(key1 key3)).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', (1 + 1)], ['val2', (2 + 1)], ['val3', 3]])
    end

    it 'should union more than two keys' do
      subject.zunionstore('out', %w(key1 key2 key3)).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', (1 + 1)], ['val2', (2 + 5 + 1)], ['val3', (3 + 7)]])
    end

    it 'should union with an unknown key' do
      subject.zunionstore('out', %w(key1 no_key)).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', 1], ['val2', 2], ['val3', 3]])
    end

    it 'should union two keys by minimum values' do
      subject.zunionstore('out', %w(key1 key2), aggregate: :min).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', 1], ['val2', 2], ['val3', 3]])
    end

    it 'should union two keys by maximum values' do
      subject.zunionstore('out', %w(key1 key2), aggregate: :max).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', 1], ['val2', 5], ['val3', 7]])
    end

    it 'should union two keys by explicitly summing values' do
      subject.zunionstore('out', %w(key1 key2), aggregate: :sum).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', 1], ['val2', (2 + 5)], ['val3', (3 + 7)]])
    end

    it 'should union two keys with weighted values' do
      subject.zunionstore('out', %w(key1 key2), :weights => [10, 1]).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', (1 * 10)], ['val2', (2 * 10 + 5)], ['val3', (3 * 10 + 7)]])
    end

    it 'should union two keys with weighted minimum values' do
      subject.zunionstore('out', %w(key1 key2), weights: [10, 1], aggregate: :min).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val2', 5], ['val3', 7], ['val1', (1 * 10)]])
    end

    it 'should union two keys with weighted maximum values' do
      subject.zunionstore('out', %w(key1 key2), weights: [10, 1], aggregate: :max).should eq(3)
      subject.zrange('out', 0, -1, with_scores: true).should eq([['val1', (1 * 10)], ['val2', (2 * 10)], ['val3', (3 * 10)]])
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

  it 'zrem should remove members add by zadd' do
    subject.zadd('key1', 1, 3)
    subject.zrem('key1', 3)
    subject.zscore('key1', 3).should be_nil
  end

  #it 'should remove all members in a sorted set within the given indexes'
  #it 'should return a range of members in a sorted set, by index, with scores ordered from high to low'
  #it 'should return a range of members in a sorted set, by score, with scores ordered from high to low'
  #it 'should determine the index of a member in a sorted set, with scores ordered from high to low'
  #it 'should get the score associated with the given member in a sorted set'
  #it 'should add multiple sorted sets and store the resulting sorted set in a new key'
end
