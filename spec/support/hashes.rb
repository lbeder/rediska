shared_examples 'hashes' do
  it 'should delete a hash field' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')
    expect(subject.hdel('key1', 'k1')).to eq(1)

    expect(subject.hget('key1', 'k1')).to be_nil
    expect(subject.hget('key1', 'k2')).to eq('val2')
  end

  it 'should remove a hash with no keys left' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')
    expect(subject.hdel('key1', 'k1')).to eq(1)
    expect(subject.hdel('key1', 'k2')).to eq(1)

    expect(subject.exists('key1')).to be_falsey
  end

  it 'should convert key to a string for hset' do
    m = double('key')
    allow(m).to receive(:to_s).and_return('foo')

    subject.hset('key1', m, 'bar')
    expect(subject.hget('key1', 'foo')).to eq('bar')
  end

  it 'should convert key to a string for hget' do
    m = double('key')
    allow(m).to receive(:to_s).and_return('foo')

    subject.hset('key1', 'foo', 'bar')
    expect(subject.hget('key1', m)).to eq('bar')
  end

  it 'should determine if a hash field exists' do
    subject.hset('key1', 'index', 'value')

    expect(subject.hexists('key1', 'index')).to be_truthy
    expect(subject.hexists('key2', 'i2')).to be_falsey
  end

  it 'should get the value of a hash field' do
    subject.hset('key1', 'index', 'value')

    expect(subject.hget('key1', 'index')).to eq('value')
  end

  it 'should get all the fields and values in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    expect(subject.hgetall('key1')).to eq({'i1' => 'val1', 'i2' => 'val2'})
  end

  it 'should increment the integer value of a hash field by the given number' do
    subject.hset('key1', 'cont1', '5')
    expect(subject.hincrby('key1', 'cont1', '5')).to eq(10)
    expect(subject.hget('key1', 'cont1')).to eq('10')
  end

  it 'should increment non existing hash keys' do
    expect(subject.hget('key1', 'cont2')).to be_nil
    expect(subject.hincrby('key1', 'cont2', '5')).to eq(5)
  end

  it 'should increment the float value of a hash field by the given float' do
    subject.hset('key1', 'cont1', 5.0)
    expect(subject.hincrbyfloat('key1', 'cont1', 4.1)).to eq(9.1)
    expect(subject.hget('key1', 'cont1')).to eq('9.1')
  end

  it 'should increment non existing hash keys' do
    expect(subject.hget('key1', 'cont2')).to be_nil
    expect(subject.hincrbyfloat('key1', 'cont2', 5.5)).to eq(5.5)
  end

  it 'should get all the fields in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    expect(subject.hkeys('key1')).to eq(['i1', 'i2'])
    expect(subject.hkeys('key2')).to be_empty
  end

  it 'should get the number of fields in a hash' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    expect(subject.hlen('key1')).to eq(2)
  end

  it 'should get the values of all the given hash fields' do
    subject.hset('key1', 'i1', 'val1')
    subject.hset('key1', 'i2', 'val2')

    expect(subject.hmget('key1', 'i1', 'i2', 'i3')).to eq(['val1', 'val2', nil])
    expect(subject.hmget('key1', ['i1', 'i2', 'i3'])).to match_array(['val1', 'val2', nil])

    expect(subject.hmget('key2', 'i1', 'i2')).to eq([nil, nil])
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

    expect(subject.exists('key')).to be_falsey
  end

  it 'rejects an insert with a key but no value' do
    expect {
      subject.hmset('key', 'foo')
    }.to raise_error(Redis::CommandError)

    expect {
      subject.hmset('key', 'foo', 3, 'bar')
    }.to raise_error(Redis::CommandError)

    expect(subject.exists('key')).to be_falsey
  end

  it 'should reject the wrong number of arguments' do
    expect {
      subject.hmset('hash', 'foo1', 'bar1', 'foo2', 'bar2', 'foo3')
    }.to raise_error(Redis::CommandError, 'ERR wrong number of arguments for HMSET')
  end

  it 'should set multiple hash fields to multiple values' do
    subject.hmset('key', 'k1', 'value1', 'k2', 'value2')

    expect(subject.hget('key', 'k1')).to eq('value1')
    expect(subject.hget('key', 'k2')).to eq('value2')
  end

  it 'should set multiple hash fields from a ruby hash to multiple values' do
    subject.mapped_hmset('foo', k1: 'value1', k2: 'value2')

    expect(subject.hget('foo', 'k1')).to eq('value1')
    expect(subject.hget('foo', 'k2')).to eq('value2')
  end

  it 'should set the string value of a hash field' do
    expect(subject.hset('key1', 'k1', 'val1')).to be_truthy
    expect(subject.hset('key1', 'k1', 'val1')).to be_falsey

    expect(subject.hget('key1', 'k1')).to eq('val1')
  end

  it 'should set the value of a hash field, only if the field does not exist' do
    subject.hset('key1', 'k1', 'val1')
    expect(subject.hsetnx('key1', 'k1', 'value')).to be_falsey
    expect(subject.hsetnx('key1', 'k2', 'val2')).to be_truthy
    expect(subject.hsetnx('key1', :k1, 'value')).to be_falsey
    expect(subject.hsetnx('key1', :k3, 'val3')).to be_truthy

    expect(subject.hget('key1', 'k1')).to eq('val1')
    expect(subject.hget('key1', 'k2')).to eq('val2')
    expect(subject.hget('key1', 'k3')).to eq('val3')
  end

  it 'should get all the values in a hash' do
    subject.hset('key1', 'k1', 'val1')
    subject.hset('key1', 'k2', 'val2')

    expect(subject.hvals('key1')).to eq(['val1', 'val2'])
  end

  it 'should accept a list of array pairs as arguments and not throw an invalid argument number error' do
    subject.hmset('key1', [:k1, 'val1'], [:k2, 'val2'], [:k3, 'val3'])
    expect(subject.hget('key1', :k1)).to eq('val1')
    expect(subject.hget('key1', :k2)).to eq('val2')
    expect(subject.hget('key1', :k3)).to eq('val3')
  end

  it 'should reject a list of arrays that contain an invalid number of arguments' do
    expect {
      subject.hmset('key1', [:k1, 'val1'], [:k2, 'val2', 'bogus val'])
    }.to raise_error(Redis::CommandError, 'ERR wrong number of arguments for HMSET')
  end

  it 'should convert a integer field name to string for hdel' do
    subject.hset('key1', '1', 1)
    expect(subject.hdel('key1', 1)).to eq(1)
  end

  it 'should convert a integer field name to string for hexists' do
    subject.hset('key1', '1', 1)
    expect(subject.hexists('key1', 1)).to be_truthy
  end

  it 'should convert a integer field name to string for hincrby' do
    subject.hset('key1', 1, 0)
    expect(subject.hincrby('key1', 1, 1)).to eq(1)
  end
end
