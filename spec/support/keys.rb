shared_examples 'keys' do
  it 'should delete a key' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.del('key1', 'key2')

    expect(subject.get('key1')).to be_nil
  end

  it 'should delete multiple keys' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.del(['key1', 'key2'])

    expect(subject.get('key1')).to be_nil
    expect(subject.get('key2')).to be_nil
  end

  it 'should error deleting no keys' do
    expect {
      subject.del
    }.to raise_error(Redis::CommandError)

    expect {
      subject.del []
    }.to raise_error(Redis::CommandError)
  end

   it "should return true when setnx keys that don't exist" do
     expect(subject.setnx('key1', '1')).to be_truthy
   end

   it 'should return false when setnx keys exist' do
     subject.set('key1', '1')
     expect(subject.setnx('key1', '1')).to be_falsey
   end

  it 'should return true when setting expires on keys that exist' do
    subject.set('key1', '1')
    expect(subject.expire('key1', 1)).to be_truthy
  end

  it 'should return true when setting pexpires on keys that exist' do
    subject.set('key1', '1')
    expect(subject.pexpire('key1', 1)).to be_truthy
  end

  it 'should return true when setting pexpires on keys that exist' do
    subject.set('key1', '1')
    expect(subject.pexpire('key1', 1)).to be_truthy
  end

  it 'should return false when attempting to set expires on a key that does not exist' do
    expect(subject.expire('key1', 1)).to be_falsey
  end

  it 'should determine if a key exists' do
    subject.set('key1', '1')

    expect(subject.exists('key1')).to be_truthy
    expect(subject.exists('key2')).to be_falsey
  end

  it "should set a key's time to live in seconds" do
    subject.set('key1', '1')
    subject.expire('key1', 1)

    expect(subject.ttl('key1')).to eq(1)
  end

  it "should set a key's time to live in miliseconds" do
    subject.set('key1', '1')
    subject.pexpire('key1', 2200)
    expect(subject.pttl('key1')).to be_within(1).of(2200)
  end

  it 'should set the expiration for a key as a UNIX timestamp' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 100)

    expect(subject.ttl('key1')).not_to eq(-1)
  end

  it 'should not have an expiration after re-set' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 2)
    subject.set('key1', '1')

    expect(subject.ttl('key1')).to eq(-1)
  end

  it 'should not have a ttl if expired (and thus key does not exist)' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    expect(subject.ttl('key1')).to eq(-2)
  end

  it 'should not find a key if expired' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    expect(subject.get('key1')).to be_nil
  end

  it 'should not find multiple keys if expired' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.expireat('key1', Time.now.to_i)

    expect(subject.mget('key1', 'key2')).to eq([nil, '2'])
  end

  it 'should only find keys that are not expired' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.expireat('key1', Time.now.to_i)

    expect(subject.keys).to eq(['key2'])
  end

  it 'should not exist if expired' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i)

    expect(subject.exists('key1')).to be_falsey
  end

  it 'should find all keys matching the given pattern' do
    subject.set('key:a', '1')
    subject.set('key:b', '2')
    subject.set('key:c', '3')
    subject.set('akeyd', '4')
    subject.set('key1', '5')

    subject.mset('database', 1, 'above', 2, 'suitability', 3, 'able', 4)

    expect(subject.keys('key:*')).to match_array(['key:a', 'key:b', 'key:c'])
    expect(subject.keys('ab*')).to match_array(['above', 'able'])
  end

  it 'should remove the expiration from a key' do
    subject.set('key1', '1')
    subject.expireat('key1', Time.now.to_i + 1)
    expect(subject.persist('key1')).to be_truthy
    expect(subject.persist('key1')).to be_falsey

    expect(subject.ttl('key1')).to eq(-1)
  end

  it 'should return a random key from the keyspace' do
    subject.set('key1', '1')
    subject.set('key2', '2')

    expect(['key1', 'key2']).to include(subject.randomkey)
  end

  it 'should rename a key' do
    subject.set('key1', '2')
    subject.rename('key1', 'key2')

    expect(subject.get('key1')).to be_nil
    expect(subject.get('key2')).to eq('2')
  end

  it 'should rename a key, only if new key does not exist' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.set('key3', '3')
    subject.renamenx('key1', 'key2')
    subject.renamenx('key3', 'key4')

    expect(subject.get('key1')).to eq('1')
    expect(subject.get('key2')).to eq('2')
    expect(subject.get('key3')).to be_nil
    expect(subject.get('key4')).to eq('3')
  end

  it 'should determine the type stored at key' do
    subject.set('key1', '1')

    # Non-existing key.
    expect(subject.type('key0')).to eq('none')

    # String.
    subject.set('key1', '1')
    expect(subject.type('key1')).to eq('string')


    # List.
    subject.lpush('key2', '1')
    expect(subject.type('key2')).to eq('list')

    # Set.
    subject.sadd('key3', '1')
    expect(subject.type('key3')).to eq('set')

    # Sorted Set.
    subject.zadd('key4', 1.0, '1')
    expect(subject.type('key4')).to eq('zset')

    # Hash.
    subject.hset('key5', 'a', '1')
    expect(subject.type('key5')).to eq('hash')
  end

  it 'should convert the value into a string before storing' do
    subject.set('key1', 1)
    expect(subject.get('key1')).to eq('1')

    subject.setex('key2', 30, 1)
    expect(subject.get('key2')).to eq('1')

    subject.getset('key3', 1)
    expect(subject.get('key3')).to eq('1')
  end

  it "should return 'OK' for the setex command" do
    expect(subject.setex('key4', 30, 1)).to eq('OK')
  end

  it 'should convert the key into a string before storing' do
    subject.set(123, 'foo')
    expect(subject.keys).to include('123')
    expect(subject.get('123')).to eq('foo')

    subject.setex(456, 30, 'foo')
    expect(subject.keys).to include('456')
    expect(subject.get('456')).to eq('foo')

    subject.getset(789, 'foo')
    expect(subject.keys).to include('789')
    expect(subject.get('789')).to eq('foo')
  end

  it 'should only operate against keys containing string values' do
    subject.sadd('key1', 'one')

    expect {
      subject.get('key1')
    }.to raise_error(Redis::CommandError, 'WRONGTYPE Operation against a key holding the wrong kind of value')

    expect {
      subject.getset('key1', 1)
    }.to raise_error(Redis::CommandError, 'WRONGTYPE Operation against a key holding the wrong kind of value')

    subject.hset('key2', 'one', 'two')

    expect {
      subject.get('key2')
    }.to raise_error(Redis::CommandError, 'WRONGTYPE Operation against a key holding the wrong kind of value')

    expect {
      subject.getset('key2', 1)
    }.to raise_error(Redis::CommandError, 'WRONGTYPE Operation against a key holding the wrong kind of value')
  end

  it 'should move a key from one database to another successfully' do
    subject.select(0)
    subject.set('key1', '1')

    expect(subject.move('key1', 1)).to be_truthy

    subject.select(0)
    expect(subject.get('key1')).to be_nil

    subject.select(1)
    expect(subject.get('key1')).to eq('1')
  end

  it 'should fail to move a key that does not exist in the source database' do
    subject.select(0)
    expect(subject.get('key1')).to be_nil

    expect(subject.move('key1', 1)).to be_falsey

    subject.select(0)
    expect(subject.get('key1')).to be_nil

    subject.select(1)
    expect(subject.get('key1')).to be_nil
  end

  it 'should fail to move a key that exists in the destination database' do
    subject.select(0)
    subject.set('key1', '1')

    subject.select(1)
    subject.set('key1', '2')

    subject.select(0)
    expect(subject.move('key1', 1)).to be_falsey

    subject.select(0)
    expect(subject.get('key1')).to eq('1')

    subject.select(1)
    expect(subject.get('key1')).to eq('2')
  end

  it 'should fail to move a key to the same database' do
    subject.select(0)
    subject.set('key1', '1')

    expect {
      subject.move('key1', 0)
    }.to raise_error(Redis::CommandError, 'ERR source and destination objects are the same')

    subject.select(0)
    expect(subject.get('key1')).to eq('1')
  end

  it 'should scan all keys in the database' do
    100.times do |x|
      subject.set("key#{x}", "#{x}")
    end

    cursor = 0
    all_keys = []
    loop do
      cursor, keys = subject.scan(cursor)
      all_keys += keys
      break if cursor == '0'
    end

    expect(all_keys.uniq.size).to eq(100)
    expect(all_keys[0]).to match(/key\d+/)
  end

  it "should match keys to a pattern when scanning" do
    50.times do |x|
      subject.set("key#{x}", "#{x}")
    end

    subject.set('miss_me', 1)
    subject.set('pass_me', 2)

    cursor = 0
    all_keys = []
    loop do
      cursor, keys = subject.scan(cursor, match: 'key*')
      all_keys += keys
      break if cursor == '0'
    end

    expect(all_keys.uniq.size).to eq(50)
  end

  it 'should specify doing more work when scanning' do
    100.times do |x|
      subject.set("key#{x}", "#{x}")
    end

    cursor, all_keys = subject.scan(cursor, count: 100)

    expect(cursor).to eq('0')
    expect(all_keys.uniq.size).to eq(100)
  end

  context 'with extended options' do
    it 'uses ex option to set the expire time, in seconds' do
      ttl = 7

      expect(subject.set('key1', '1', ex: ttl)).to eq('OK')
      expect(subject.ttl('key1')).to eq(ttl)
    end

    it 'uses px option to set the expire time, in miliseconds' do
      ttl = 7000

      expect(subject.set('key1', '1', px: ttl)).to eq('OK')
      expect(subject.ttl('key1')).to eq(ttl / 1000)
    end

    # Note that the redis-rb implementation will always give PX last.
    # Redis seems to process each expiration option and the last one wins.
    it 'prefers the finer-grained PX expiration option over EX' do
      ttl_px = 6000
      ttl_ex = 10

      subject.set('key1', '1', px: ttl_px, ex: ttl_ex)
      expect(subject.ttl('key1')).to eq(ttl_px / 1000)

      subject.set('key1', '1', ex: ttl_ex, px: ttl_px)
      expect(subject.ttl('key1')).to eq(ttl_px / 1000)
    end

    it 'uses nx option to only set the key if it does not already exist' do
      expect(subject.set('key1', '1', nx: true)).to be_truthy
      expect(subject.set('key1', '2', nx: true)).to be_falsey

      expect(subject.get('key1')).to eq('1')
    end

    it 'uses xx option to only set the key if it already exists' do
      expect(subject.set('key2', '1', xx: true)).to be_falsey
      subject.set('key2', '2')
      expect(subject.set('key2', '1', xx: true)).to be_truthy

      expect(subject.get('key2')).to eq('1')
    end

    it 'does not set the key if both xx and nx option are specified' do
      expect(subject.set('key2', '1', nx: true, xx: true)).to be_falsey
      expect(subject.get('key2')).to be_nil
    end

    describe '#dump' do
      it 'returns nil for unknown key' do
        expect(subject.exists('key1')).to be_falsey
        expect(subject.dump('key1')).to be_nil
      end

      it 'dumps a single known key successfully' do
        subject.set('key1', 'zomgwtf')

        value = subject.dump('key1')
        expect(value).not_to be_nil
        expect(value).to be_a_kind_of(String)
      end

      it 'errors with more than one argument' do
        expect {
          subject.dump('key1', 'key2')
        }.to raise_error(ArgumentError)
      end
    end

    describe "#restore" do
      it 'errors with a missing payload' do
        expect {
          subject.restore('key1', 0, nil)
        }.to raise_error(Redis::CommandError, 'ERR DUMP payload version or checksum are wrong')
      end

      it 'errors with an invalid payload' do
        expect {
          subject.restore('key1', 0, 'zomgwtf not valid')
        }.to raise_error(Redis::CommandError, 'ERR DUMP payload version or checksum are wrong')
      end

      describe 'with a dumped value' do
        before do
          subject.set('key1', 'original value')
          @dumped_value = subject.dump('key1')

          subject.del('key1')
          expect(subject.exists('key1')).to be_falsey
        end

        it 'restores to a new key successfully' do
          response = subject.restore('key1', 0, @dumped_value)
          expect(response).to eq('OK')
        end

        it 'errors trying to restore to an existing key' do
          subject.set('key1', 'something else')

          expect {
            subject.restore('key1', 0, @dumped_value)
          }.to raise_error(Redis::CommandError, 'ERR Target key name is busy.')
        end

        it 'restores successfully with a given expire time' do
          subject.restore('key2', 2000, @dumped_value)

          expect(subject.ttl('key2')).to eq(2)
        end

        it 'restores a list successfully' do
          subject.lpush('key1', 'val1')
          subject.lpush('key1', 'val2')

          expect(subject.type('key1')).to eq('list')

          dumped_value = subject.dump('key1')

          response = subject.restore('key2', 0, dumped_value)
          expect(response).to eq('OK')

          expect(subject.type('key2')).to eq('list')
        end

        it 'restores a set successfully' do
          subject.sadd('key1', 'val1')
          subject.sadd('key1', 'val2')

          expect(subject.type('key1')).to eq('set')

          dumped_value = subject.dump('key1')

          response = subject.restore('key2', 0, dumped_value)
          expect(response).to eq('OK')

          expect(subject.type('key2')).to eq('set')
        end
      end
    end
  end
end
