shared_examples 'keys' do
  it 'should delete a key' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.del('key1', 'key2')

    subject.get('key1').should be_nil
  end

  it 'should delete multiple keys' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.del(['key1', 'key2'])

    subject.get('key1').should be_nil
    subject.get('key2').should be_nil
  end

  it 'should error deleting no keys' do
    expect {
      subject.del
    }.to raise_error(Redis::CommandError)

    expect {
      subject.del []
    }.to raise_error(Redis::CommandError)
  end

  it 'should determine if a key exists' do
    subject.set('key1', '1')

    subject.exists('key1').should be_true
    subject.exists('key2').should be_false
  end

  it "should set a key's time to live in seconds" do
    subject.set('key1', '1')
    subject.expire('key1', 1)

    subject.ttl('key1').should eq(1)
  end

  it "should set the expiration for a key as a UNIX timestamp" do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 100)

    subject.ttl('key1').should_not eq(-1)
  end

  it 'should not have an expiration after re-set' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 2)
    subject.set('key1', '1')

    subject.ttl('key1').should eq(-1)
  end

  it 'should not have a ttl if expired' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    subject.ttl('key1').should eq(-1)
  end

  it 'should not find a key if expired' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    subject.get('key1').should be_nil
  end

  it 'should not find multiple keys if expired' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.expireat('key1', Time.now.to_i)

    subject.mget('key1', 'key2').should eq([nil, '2'])
  end

  it 'should only find keys that are not expired' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.expireat('key1', Time.now.to_i)

    subject.keys.should eq(['key2'])
  end

  it 'should not exist if expired' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    subject.exists('key1').should be_false
  end

  it 'should find all keys matching the given pattern' do
    subject.set('key:a', '1')
    subject.set('key:b', '2')
    subject.set('key:c', '3')
    subject.set('akeyd', '4')
    subject.set('key1', '5')

    subject.mset('database', 1, 'above', 2, 'suitability', 3, 'able', 4)

    subject.keys('key:*').should =~ ['key:a', 'key:b', 'key:c']
    subject.keys('ab*').should =~ ['above', 'able']
  end

  it 'should remove the expiration from a key' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 1)
    subject.persist('key1').should be_true
    subject.persist('key1').should be_false

    subject.ttl('key1').should eq(-1)
  end

  it 'should return a random key from the keyspace' do
    subject.set('key1', '1')
    subject.set('key2', '2')

    ['key1', 'key2'].should include(subject.randomkey)
  end

  it 'should rename a key' do
    subject.set('key1', '2')
    subject.rename('key1', 'key2')

    subject.get('key1').should be_nil
    subject.get('key2').should eq('2')
  end

  it 'should rename a key, only if new key does not exist' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.set('key3', '3')
    subject.renamenx('key1', 'key2')
    subject.renamenx('key3', 'key4')

    subject.get('key1').should eq('1')
    subject.get('key2').should eq('2')
    subject.get('key3').should be_nil
    subject.get('key4').should eq('3')
  end

  it 'should sort the elements in a list, set or sorted set' do
    pending 'SORT Command not implemented yet'
  end

  it 'should determine the type stored at key' do
    subject.set('key1', '1')

    subject.type('key1').should eq('string')
    subject.type('key0').should eq('none')
  end

  it 'should convert the value into a string before storing' do
    subject.set('key1', 1)
    subject.get('key1').should eq('1')

    subject.setex('key2', 30, 1)
    subject.get('key2').should eq('1')

    subject.getset('key3', 1)
    subject.get('key3').should eq('1')
  end

  it "should return 'OK' for the setex command" do
    subject.setex('key4', 30, 1).should eq('OK')
  end

  it 'should convert the key into a string before storing' do
    subject.set(123, 'foo')
    subject.keys.should include('123')
    subject.get('123').should eq('foo')

    subject.setex(456, 30, 'foo')
    subject.keys.should include('456')
    subject.get('456').should eq('foo')

    subject.getset(789, 'foo')
    subject.keys.should include('789')
    subject.get('789').should eq('foo')
  end

  it 'should only operate against keys containing string values' do
    subject.sadd('key1', 'one')

    expect {
      subject.get('key1')
    }.to raise_error(Redis::CommandError, 'ERR Operation against a key holding the wrong kind of value')

    expect {
      subject.getset('key1', 1)
    }.to raise_error(Redis::CommandError, 'ERR Operation against a key holding the wrong kind of value')

    subject.hset('key2', 'one', 'two')

    expect {
      subject.get('key2')
    }.to raise_error(Redis::CommandError, 'ERR Operation against a key holding the wrong kind of value')

    expect {
      subject.getset('key2', 1)
    }.to raise_error(Redis::CommandError, 'ERR Operation against a key holding the wrong kind of value')
  end

  it 'should move a key from one database to another successfully' do
    subject.select(0)
    subject.set('key1', '1')

    subject.move('key1', 1).should be_true

    subject.select(0)
    subject.get('key1').should be_nil

    subject.select(1)
    subject.get('key1').should eq('1')
  end

  it 'should fail to move a key that does not exist in the source database' do
    subject.select(0)
    subject.get('key1').should be_nil

    subject.move('key1', 1).should be_false

    subject.select(0)
    subject.get('key1').should be_nil

    subject.select(1)
    subject.get('key1').should be_nil
  end

  it 'should fail to move a key that exists in the destination database' do
    subject.select(0)
    subject.set('key1', '1')

    subject.select(1)
    subject.set('key1', '2')

    subject.select(0)
    subject.move('key1', 1).should be_false

    subject.select(0)
    subject.get('key1').should eq('1')

    subject.select(1)
    subject.get('key1').should eq('2')
  end

  it 'should fail to move a key to the same database' do
    subject.select(0)
    subject.set('key1', '1')

    expect {
      subject.move('key1', 0)
    }.to raise_error(Redis::CommandError, 'ERR source and destination objects are the same')

    subject.select(0)
    subject.get('key1').should eq('1')
  end
end
