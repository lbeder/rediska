shared_examples 'hashes' do
  it 'should delete a hash field' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')
    subject.hdel('key1', 'k1')

    subject.hget('key1', 'k1').should be_nil
    subject.hget('key1', 'k2').should eq('val2')
  end

  it 'should remove a hash with no keys left' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')
    subject.hdel('key1', 'k1')
    subject.hdel('key1', 'k2')

    subject.exists('key1').should be_false
  end

  it 'should convert key to a string for hset' do
    m = double('key')
    m.stub(:to_s).and_return('foo')

    subject.hset('key1', m, 'bar')
    subject.hget('key1', 'foo').should eq('bar')
  end

  it 'should convert key to a string for hget' do
    m = double('key')
    m.stub(:to_s).and_return('foo')

    subject.hset('key1', 'foo', 'bar')
    subject.hget('key1', m).should eq('bar')
  end

  it 'should determine if a hash field exists' do
    subject.hset('key1', 'index', 'value')

    subject.hexists('key1', 'index').should be_true
    subject.hexists('key2', 'i2').should be_false
  end

  it 'should get the value of a hash field' do
    subject.hset('key1', 'index', 'value')

    subject.hget('key1', 'index').should eq('value')
  end

  it 'should get all the fields and values in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    subject.hgetall('key1').should eq({'i1' => 'val1', 'i2' => 'val2'})
  end

  it 'should increment the integer value of a hash field by the given number' do
    subject.hset('key1', 'cont1', '5')
    subject.hincrby('key1', 'cont1', '5').should eq(10)
    subject.hget('key1', 'cont1').should eq('10')
  end

  it 'should increment non existing hash keys' do
    subject.hget('key1', 'cont2').should be_nil
    subject.hincrby('key1', 'cont2', '5').should eq(5)
  end

  it 'should get all the fields in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    subject.hkeys('key1').should eq(['i1', 'i2'])
    subject.hkeys('key2').should be_empty
  end

  it 'should get the number of fields in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    subject.hlen('key1').should eq(2)
  end

  it 'should get the values of all the given hash fields' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    subject.hmget('key1', 'i1', 'i2', 'i3').should eq(['val1', 'val2', nil])
    subject.hmget('key2', 'i1', 'i2').should eq([nil, nil])
  end

  it 'should throw an argument error when you do not ask for any keys' do
    expect {
      subject.hmget('key1')
    }.to raise_error(Redis::CommandError)
  end

  it 'should reject an empty list of values' do
    expect {
      subject.hmset('key')
    }.to raise_error(Redis::CommandError)

    subject.exists('key').should be_false
  end

  it 'rejects an insert with a key but no value' do
    expect {
      subject.hmset('key', 'foo')
    }.to raise_error(Redis::CommandError)

    expect {
      subject.hmset('key', 'foo', 3, 'bar')
    }.to raise_error(Redis::CommandError)

    subject.exists('key').should be_false
  end

  it 'should reject the wrong number of arguments' do
    expect {
      subject.hmset('hash', 'foo1', 'bar1', 'foo2', 'bar2', 'foo3')
    }.to raise_error(Redis::CommandError)
  end

  it 'should set multiple hash fields to multiple values' do
    subject.hmset('key', 'k1', 'value1', 'k2', 'value2')

    subject.hget('key', 'k1').should eq('value1')
    subject.hget('key', 'k2').should eq('value2')
  end

  it 'should set multiple hash fields from a ruby hash to multiple values' do
    subject.mapped_hmset('foo', k1: 'value1', k2: 'value2')

    subject.hget('foo', 'k1').should eq('value1')
    subject.hget('foo', 'k2').should eq('value2')
  end

  it 'should set the string value of a hash field' do
    subject.hset('key1', 'k1', 'val1').should be_true
    subject.hset('key1', 'k1', 'val1').should be_false

    subject.hget('key1', 'k1').should eq('val1')
  end

  it 'should set the value of a hash field, only if the field does not exist' do
    subject.hset('key1', 'k1', 'val1')
    subject.hsetnx('key1', 'k1', 'value').should be_false
    subject.hsetnx('key1', 'k2', 'val2').should be_true
    subject.hsetnx('key1', :k1, 'value').should be_false
    subject.hsetnx('key1', :k3, 'val3').should be_true

    subject.hget('key1', 'k1').should eq('val1')
    subject.hget('key1', 'k2').should eq('val2')
    subject.hget('key1', 'k3').should eq('val3')
  end

  it 'should get all the values in a hash' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')

    subject.hvals('key1').should eq(['val1', 'val2'])
  end

  it 'should accept a list of array pairs as arguments and not throw an invalid argument number error' do
    subject.hmset('key1', [:k1, 'val1'], [:k2, 'val2'], [:k3, 'val3'])
    subject.hget('key1', :k1).should eq('val1')
    subject.hget('key1', :k2).should eq('val2')
    subject.hget('key1', :k3).should eq('val3')
  end

  it 'should reject a list of arrays that contain an invalid number of arguments' do
    expect {
      subject.hmset('key1', [:k1, 'val1'], [:k2, 'val2', 'bogus val'])
    }.to raise_error(Redis::CommandError)
  end

  it 'should convert a integer field name to string for hdel' do
    subject.hset('key1', '1', 1)
    subject.hdel('key1', 1).should eq(1)
  end

  it 'should convert a integer field name to string for hexists' do
    subject.hset('key1', '1', 1)
    subject.hexists('key1', 1).should be_true
  end

  it 'should convert a integer field name to string for hincrby' do
    subject.hset('key1', 1, 0)
    subject.hincrby('key1', 1, 1).should eq(1)
  end
end
