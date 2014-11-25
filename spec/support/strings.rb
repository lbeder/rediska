# encoding: UTF-8

shared_examples 'strings' do
  it 'should append a value to key' do
    subject.set('key1', 'Hello')
    subject.append('key1', ' World')

    expect(subject.get('key1')).to eq('Hello World')
  end

  it 'should decrement the integer value of a key by one' do
    subject.set('counter', '1')
    subject.decr('counter')

    expect(subject.get('counter')).to eq('0')
  end

  it 'should decrement the integer value of a key by the given number' do
    subject.set('counter', '10')
    subject.decrby('counter', '5')

    expect(subject.get('counter')).to eq('5')
  end

  it 'should get the value of a key' do
    expect(subject.get('key2')).to be_nil
  end

  it 'should returns the bit value at offset in the string value stored at key' do
    subject.set('key1', 'a')

    expect(subject.getbit('key1', 1)).to eq(1)
    expect(subject.getbit('key1', 2)).to eq(1)
    expect(subject.getbit('key1', 3)).to eq(0)
    expect(subject.getbit('key1', 4)).to eq(0)
    expect(subject.getbit('key1', 5)).to eq(0)
    expect(subject.getbit('key1', 6)).to eq(0)
    expect(subject.getbit('key1', 7)).to eq(1)
  end

  it 'should allow direct bit manipulation even if the string is not set' do
    subject.setbit('key1', 10, 1)
    expect(subject.getbit('key1', 10)).to eq(1)
  end

  context 'when a bit is previously set to 0' do
    before do
      subject.setbit('key1', 10, 0)
    end

    it 'setting it to 1 returns 0' do
      expect(subject.setbit('key1', 10, 1)).to eq(0)
    end

    it 'setting it to 0 returns 0' do
      expect(subject.setbit('key1', 10, 0)).to eq(0)
    end
  end

  context 'when a bit is previously set to 1' do
    before do
      subject.setbit('key1', 10, 1)
    end

    it 'setting it to 0 returns 1' do
      expect(subject.setbit('key1', 10, 0)).to eq(1)
    end

    it 'setting it to 1 returns 1' do
      expect(subject.setbit('key1', 10, 1)).to eq(1)
    end
  end

  it 'should get a substring of the string stored at a key' do
    subject.set('key1', 'This a message')

    expect(subject.getrange('key1', 0, 3)).to eq('This')
    expect(subject.substr('key1', 0, 3)).to eq('This')
  end

  it 'should set the string value of a key and return its old value' do
    subject.set('key1','value1')

    expect(subject.getset('key1', 'value2')).to eq('value1')
    expect(subject.get('key1')).to eq('value2')
  end

  it 'should return nil for #getset if the key does not exist when setting' do
    expect(subject.getset('key1', 'value1')).to be_nil
    expect(subject.get('key1')).to eq('value1')
  end

  it 'should increment the integer value of a key by one' do
    subject.set('counter', '1')
    expect(subject.incr('counter')).to eq(2)

    expect(subject.get('counter')).to eq('2')
  end

  it 'should not change the expire value of the key during incr' do
    subject.set('counter', '1')
    expect(subject.expire('counter', 600)).to be_truthy

    expect(subject.ttl('counter')).to eq(600)
    expect(subject.incr('counter')).to eq(2)
    expect(subject.ttl('counter')).to be_within(10).of(600)
  end

  it 'should decrement the integer value of a key by one' do
    subject.set('counter', '1')
    expect(subject.decr('counter')).to eq(0)

    expect(subject.get('counter')).to eq('0')
  end

  it 'should not change the expire value of the key during decr' do
    subject.set('counter', '2')
    expect(subject.expire('counter', 600)).to be_truthy

    expect(subject.ttl('counter')).to eq(600)
    expect(subject.decr('counter')).to eq(1)
    expect(subject.ttl('counter')).to be_within(10).of(600)
  end

  it 'should increment the integer value of a key by the given number' do
    subject.set('counter', '10')
    expect(subject.incrby('counter', '5')).to eq(15)
    expect(subject.incrby('counter', 2)).to eq(17)
    expect(subject.get('counter')).to eq('17')
  end

  it 'should increment the float value of a key by the given number' do
    subject.set('counter', 10.0)
    expect(subject.incrbyfloat('counter', 2.1)).to eq(12.1)
    expect(subject.get('counter')).to eq('12.1')
  end

  it 'should not change the expire value of the key during incrby' do
    subject.set('counter', '1')
    expect(subject.expire('counter', 600)).to be_truthy

    expect(subject.ttl('counter')).to eq(600)
    expect(subject.incrby('counter', '5')).to eq(6)
    expect(subject.ttl('counter')).to be_within(10).of(600)
  end

  it 'should decrement the integer value of a key by the given number' do
    subject.set('counter', '10')
    expect(subject.decrby('counter', '5')).to eq(5)
    expect(subject.decrby('counter', 2)).to eq(3)
    expect(subject.get('counter')).to eq('3')
  end

  it 'should not change the expire value of the key during decrby' do
    subject.set('counter', '8')
    expect(subject.expire('counter', 600)).to be_truthy

    expect(subject.ttl('counter')).to eq(600)
    expect(subject.decrby('counter', '3')).to eq(5)
    expect(subject.ttl('counter')).to be_within(10).of(600)
  end

  it 'should get the values of all the given keys' do
    subject.set('key1', 'value1')
    subject.set('key2', 'value2')
    subject.set('key3', 'value3')

    expect(subject.mget('key1', 'key2', 'key3')).to eq(['value1', 'value2', 'value3'])
    expect(subject.mget(['key1', 'key2', 'key3'])).to eq(['value1', 'value2', 'value3'])
  end

  it 'returns nil for non existent keys' do
    subject.set('key1', 'value1')
    subject.set('key3', 'value3')

    expect(subject.mget('key1', 'key2', 'key3', 'key4')).to eq(['value1', nil, 'value3', nil])
    expect(subject.mget(['key1', 'key2', 'key3', 'key4'])).to eq(['value1', nil, 'value3', nil])
  end

  it 'raises an argument error when not passed any fields' do
    subject.set('key3', 'value3')

    expect {
      subject.mget
    }.to raise_error(Redis::CommandError)
  end

  it 'should set multiple keys to multiple values' do
    subject.mset(:key1, 'value1', :key2, 'value2')

    expect(subject.get('key1')).to eq('value1')
    expect(subject.get('key2')).to eq('value2')
  end

  it 'should raise error if command arguments count is wrong' do
    expect {
      subject.mset
    }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'mset' command")

    expect {
      subject.mset(:key1)
    }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'mset' command")

    expect {
      subject.mset(:key1, 'value', :key2)
    }.to raise_error(Redis::CommandError, 'ERR wrong number of arguments for MSET')

    expect(subject.get('key1')).to be_nil
    expect(subject.get('key2')).to be_nil
  end

  it 'should set multiple keys to multiple values, only if none of the keys exist' do
    expect(subject.msetnx(:key1, 'value1', :key2, 'value2')).to be_truthy
    expect(subject.msetnx(:key1, 'value3', :key2, 'value4')).to be_falsey

    expect(subject.get('key1')).to eq('value1')
    expect(subject.get('key2')).to eq('value2')
  end

  it 'should set multiple keys to multiple values with a hash' do
    subject.mapped_mset(key1: 'value1', key2: 'value2')

    expect(subject.get('key1')).to eq('value1')
    expect(subject.get('key2')).to eq('value2')
  end

  it 'should set multiple keys to multiple values with a hash, only if none of the keys exist' do
    expect(subject.mapped_msetnx(key1: 'value1', key2: 'value2')).to be_truthy
    expect(subject.mapped_msetnx(key1: 'value3', key2: 'value4')).to be_falsey

    expect(subject.get('key1')).to eq('value1')
    expect(subject.get('key2')).to eq('value2')
  end

  it 'should set the string value of a key' do
    subject.set('key1', '1')

    expect(subject.get('key1')).to eq('1')
  end

  it 'should sets or clears the bit at offset in the string value stored at key' do
    subject.set('key1', 'abc')
    subject.setbit('key1', 11, 1)

    expect(subject.get('key1')).to eq('arc')
  end

  it 'should set the value and expiration of a key' do
    subject.setex('key1', 30, 'value1')

    expect(subject.get('key1')).to eq('value1')
    expect(subject.ttl('key1')).to eq(30)
  end

  it 'should set the value of a key, only if the key does not exist' do
    subject.set('key1', 'test value')
    subject.setnx('key1', 'new value')
    subject.setnx('key2', 'another value')

    expect(subject.get('key1')).to eq('test value')
    expect(subject.get('key2')).to eq('another value')
  end

  it 'should overwrite part of a string at key starting at the specified offset' do
    subject.set('key1', 'Hello World')
    subject.setrange('key1', 6, 'Redis')

    expect(subject.get('key1')).to eq('Hello Redis')
  end

  it 'should get the length of the value stored in a key' do
    subject.set('key1', 'abc')

    expect(subject.strlen('key1')).to eq(3)
  end

  it "should return 0 bits when there's no key" do
    expect(subject.bitcount('key1')).to eq(0)
  end

  it 'should count the number of bits of a string' do
    subject.set('key1', 'foobar')

    expect(subject.bitcount('key1')).to eq(26)
  end

  it 'should count correctly with UTF-8 strings' do
    subject.set('key1', '判')

    expect(subject.bitcount('key1')).to eq(10)
  end

  it 'should count the number of bits of a string given a range' do
    subject.set('key1', 'foobar')

    expect(subject.bitcount('key1', 0, 0)).to eq(4)
    expect(subject.bitcount('key1', 1, 1)).to eq(6)
    expect(subject.bitcount('key1', 0, 1)).to eq(10)
  end
end
