shared_examples 'strings' do
  it 'should append a value to key' do
    subject.set('key1', 'Hello')
    subject.append('key1', ' World')

    subject.get('key1').should eq('Hello World')
  end

  it 'should decrement the integer value of a key by one' do
    subject.set('counter', '1')
    subject.decr('counter')

    subject.get('counter').should eq('0')
  end

  it 'should decrement the integer value of a key by the given number' do
    subject.set('counter', '10')
    subject.decrby('counter', '5')

    subject.get('counter').should eq('5')
  end

  it 'should get the value of a key' do
    subject.get('key2').should be_nil
  end

  it 'should returns the bit value at offset in the string value stored at key' do
    subject.set('key1', 'a')

    subject.getbit('key1', 1).should eq(1)
    subject.getbit('key1', 2).should eq(1)
    subject.getbit('key1', 3).should eq(0)
    subject.getbit('key1', 4).should eq(0)
    subject.getbit('key1', 5).should eq(0)
    subject.getbit('key1', 6).should eq(0)
    subject.getbit('key1', 7).should eq(1)
  end

  it 'should allow direct bit manipulation even if the string is not set' do
    subject.setbit('key1', 10, 1)
    subject.getbit('key1', 10).should eq(1)
  end

  it 'should get a substring of the string stored at a key' do
    subject.set('key1', 'This a message')

    subject.getrange('key1', 0, 3).should eq('This')
    subject.substr('key1', 0, 3).should eq('This')
  end

  it 'should set the string value of a key and return its old value' do
    subject.set('key1','value1')

    subject.getset('key1', 'value2').should eq('value1')
    subject.get('key1').should eq('value2')
  end

  it 'should return nil for #getset if the key does not exist when setting' do
    subject.getset('key1', 'value1').should be_nil
    subject.get('key1').should eq('value1')
  end

  it 'should increment the integer value of a key by one' do
    subject.set('counter', '1')
    subject.incr('counter').should eq(2)

    subject.get('counter').should eq('2')
  end

  it 'should not change the expire value of the key during incr' do
    subject.set('counter', '1')
    subject.expire('counter', 600).should be_true

    subject.ttl('counter').should eq(600)
    subject.incr('counter').should eq(2)
    subject.ttl('counter').should be_within(10).of(600)
  end

  it 'should decrement the integer value of a key by one' do
    subject.set('counter', '1')
    subject.decr('counter').should eq(0)

    subject.get('counter').should eq('0')
  end

  it 'should not change the expire value of the key during decr' do
    subject.set('counter', '2')
    subject.expire('counter', 600).should be_true

    subject.ttl('counter').should eq(600)
    subject.decr('counter').should eq(1)
    subject.ttl('counter').should be_within(10).of(600)
  end

  it 'should increment the integer value of a key by the given number' do
    subject.set('counter', '10')
    subject.incrby('counter', '5').should eq(15)
    subject.incrby('counter', 2).should eq(17)
    subject.get('counter').should eq('17')
  end

  it 'should not change the expire value of the key during incrby' do
    subject.set('counter', '1')
    subject.expire('counter', 600).should be_true

    subject.ttl('counter').should eq(600)
    subject.incrby('counter', '5').should eq(6)
    subject.ttl('counter').should be_within(10).of(600)
  end

  it 'should decrement the integer value of a key by the given number' do
    subject.set('counter', '10')
    subject.decrby('counter', '5').should eq(5)
    subject.decrby('counter', 2).should eq(3)
    subject.get('counter').should eq('3')
  end

  it 'should not change the expire value of the key during decrby' do
    subject.set('counter', '8')
    subject.expire('counter', 600).should be_true

    subject.ttl('counter').should eq(600)
    subject.decrby('counter', '3').should eq(5)
    subject.ttl('counter').should be_within(10).of(600)
  end

  it 'should get the values of all the given keys' do
    subject.set('key1', 'value1')
    subject.set('key2', 'value2')
    subject.set('key3', 'value3')

    subject.mget('key1', 'key2', 'key3').should eq(['value1', 'value2', 'value3'])
    subject.mget(['key1', 'key2', 'key3']).should eq(['value1', 'value2', 'value3'])
  end

  it 'returns nil for non existent keys' do
    subject.set('key1', 'value1')
    subject.set('key3', 'value3')

    subject.mget('key1', 'key2', 'key3', 'key4').should eq(['value1', nil, 'value3', nil])
    subject.mget(['key1', 'key2', 'key3', 'key4']).should eq(['value1', nil, 'value3', nil])
  end

  it 'raises an argument error when not passed any fields' do
    subject.set('key3', 'value3')

    expect {
      subject.mget
    }.to raise_error(Redis::CommandError)
  end

  it 'should set multiple keys to multiple values' do
    subject.mset(:key1, 'value1', :key2, 'value2')

    subject.get('key1').should eq('value1')
    subject.get('key2').should eq('value2')
  end

  it 'should raise error if command arguments count is wrong' do
    expect {
      subject.mset
    }.to raise_error(Redis::CommandError)

    expect {
      subject.mset(:key1)
    }.to raise_error(Redis::CommandError)

    expect {
      subject.mset(:key1, 'value', :key2)
    }.to raise_error(Redis::CommandError)

    subject.get('key1').should be_nil
    subject.get('key2').should be_nil
  end

  it 'should set multiple keys to multiple values, only if none of the keys exist' do
    subject.msetnx(:key1, 'value1', :key2, 'value2').should be_true
    subject.msetnx(:key1, 'value3', :key2, 'value4').should be_false

    subject.get('key1').should eq('value1')
    subject.get('key2').should eq('value2')
  end

  it 'should set multiple keys to multiple values with a hash' do
    subject.mapped_mset(key1: 'value1', key2: 'value2')

    subject.get('key1').should eq('value1')
    subject.get('key2').should eq('value2')
  end

  it 'should set multiple keys to multiple values with a hash, only if none of the keys exist' do
    subject.mapped_msetnx(key1: 'value1', key2: 'value2').should be_true
    subject.mapped_msetnx(key1: 'value3', key2: 'value4').should be_false

    subject.get('key1').should eq('value1')
    subject.get('key2').should eq('value2')
  end

  it 'should set the string value of a key' do
    subject.set('key1', '1')

    subject.get('key1').should eq('1')
  end

  it 'should sets or clears the bit at offset in the string value stored at key' do
    subject.set('key1', 'abc')
    subject.setbit('key1', 11, 1)

    subject.get('key1').should eq('arc')
  end

  it 'should set the value and expiration of a key' do
    subject.setex('key1', 30, 'value1')

    subject.get('key1').should eq('value1')
    subject.ttl('key1').should eq(30)
  end

  it 'should set the value of a key, only if the key does not exist' do
    subject.set('key1', 'test value')
    subject.setnx('key1', 'new value')
    subject.setnx('key2', 'another value')

    subject.get('key1').should eq('test value')
    subject.get('key2').should eq('another value')
  end

  it 'should overwrite part of a string at key starting at the specified offset' do
    subject.set('key1', 'Hello World')
    subject.setrange('key1', 6, 'Redis')

    subject.get('key1').should eq('Hello Redis')
  end

  it 'should get the length of the value stored in a key' do
    subject.set('key1', 'abc')

    subject.strlen('key1').should eq(3)
  end
end
