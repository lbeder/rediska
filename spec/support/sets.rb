shared_examples 'sets' do
  it 'should add a member to a set' do
    expect(subject.sadd('key', 'value')).to be_truthy
    expect(subject.sadd('key', 'value')).to be_falsey

    expect(subject.smembers('key')).to match_array(['value'])
  end

  it 'should raise error if command arguments count is not enough' do
    expect {
      subject.sadd('key', [])
    }.to raise_error(Redis::CommandError)

    expect {
      subject.sinter(*[])
    }.to raise_error(Redis::CommandError)

    expect(subject.smembers('key')).to be_empty
  end

  it 'should add multiple members to a set' do
    expect(subject.sadd('key', %w(value other something more))).to eq(4)
    expect(subject.sadd('key', %w(and additional values))).to eq(3)
    expect(subject.smembers('key')).to match_array(['value', 'other', 'something', 'more', 'and', 'additional', 'values'])
  end

  it 'should get the number of members in a set' do
    subject.sadd('key', 'val1')
    subject.sadd('key', 'val2')

    expect(subject.scard('key')).to eq(2)
  end

  it 'should subtract multiple sets' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')

    expect(subject.sdiff('key1', 'key2', 'key3')).to match_array(['b', 'd'])
  end

  it 'should subtract from a nonexistent set' do
    subject.sadd('key2', 'a')
    subject.sadd('key2', 'b')
    expect(subject.sdiff('key1', 'key2')).to be_empty
  end

  it 'should subtract multiple sets and store the resulting set in a key' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')
    subject.sdiffstore('key', 'key1', 'key2', 'key3')

    expect(subject.smembers('key')).to match_array(['b', 'd'])
  end

  it 'should intersect multiple sets' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')

    expect(subject.sinter('key1', 'key2', 'key3')).to match_array(['c'])
  end

  it 'should intersect multiple sets and store the resulting set in a key' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')
    subject.sinterstore('key', 'key1', 'key2', 'key3')
    expect(subject.smembers('key')).to match_array(['c'])
  end

  it 'should determine if a given value is a member of a set' do
    subject.sadd('key1', 'a')

    expect(subject.sismember('key1', 'a')).to be_truthy
    expect(subject.sismember('key1', 'b')).to be_falsey
    expect(subject.sismember('key2', 'a')).to be_falsey
  end

  it 'should get all the members in a set' do
    subject.sadd('key', 'a')
    subject.sadd('key', 'b')
    subject.sadd('key', 'c')
    subject.sadd('key', 'd')

    expect(subject.smembers('key')).to match_array(['a', 'b', 'c', 'd'])
  end

  it 'should move a member from one set to another' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key2', 'c')
    expect(subject.smove('key1', 'key2', 'a')).to be_truthy
    expect(subject.smove('key1', 'key2', 'a')).to be_falsey

    expect(subject.smembers('key1')).to match_array(['b'])
    expect(subject.smembers('key2')).to match_array(['c', 'a'])
  end

  it 'should remove and return a random member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')

    expect(['a', 'b'].include?(subject.spop('key1'))).to be_truthy
    expect(['a', 'b'].include?(subject.spop('key1'))).to be_truthy
    expect(subject.spop('key1')).to be_nil
  end

  it 'should get a random member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')

    expect(['a', 'b'].include?(subject.spop('key1'))).to be_truthy
  end

  it 'should remove a member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    expect(subject.srem('key1', 'a')).to be_truthy
    expect(subject.srem('key1', 'a')).to be_falsey

    expect(subject.smembers('key1')).to match_array(['b'])
  end

  it "should remove multiple members from a set" do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')

    expect(subject.srem('key1', [ 'a', 'b'])).to eq(2)
    expect(subject.smembers('key1')).to be_empty
  end

  it "should remove the set's key once it's empty" do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.srem('key1', 'b')
    subject.srem('key1', 'a')

    expect(subject.exists('key1')).to be_falsey
  end

  it 'should add multiple sets' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')

    expect(subject.sunion('key1', 'key2', 'key3')).to match_array(['a', 'b', 'c', 'd', 'e'])
  end

  it 'should add multiple sets and store the resulting set in a key' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key1', 'c')
    subject.sadd('key1', 'd')
    subject.sadd('key2', 'c')
    subject.sadd('key3', 'a')
    subject.sadd('key3', 'c')
    subject.sadd('key3', 'e')
    subject.sunionstore('key', 'key1', 'key2', 'key3')

    expect(subject.smembers('key')).to match_array(['a', 'b', 'c', 'd', 'e'])
  end

  describe 'srandmember' do
    before(:each) do
      @client = Redis.new
    end

    context 'with a set that has three elements' do
      before do
        subject.sadd('key1', 'a')
        subject.sadd('key1', 'b')
        subject.sadd('key1', 'c')
      end

      context 'when called without the optional number parameter' do
        it 'is a random element from the set' do
          random_element = subject.srandmember('key1')

          expect(['a', 'b', 'c']).to include(random_element)
        end
      end

      context 'when called with the optional number parameter of 1' do
        it 'is an array of one random element from the set' do
          subject.srandmember('key1', 1)

          expect([['a'], ['b'], ['c']]).to include(subject.srandmember('key1', 1))
        end
      end

      context 'when called with the optional number parameter of 2' do
        it 'is an array of two unique, random elements from the set' do
          random_elements = subject.srandmember('key1', 2)

          expect(random_elements.size).to eq(2)
          expect(random_elements.uniq.size).to eq(2)
          random_elements.all? do |element|
            expect(['a', 'b', 'c']).to include(element)
          end
        end
      end

      context 'when called with an optional parameter of -100' do
        it 'is an array of 100 random elements from the set, some of which are repeated' do
          random_elements = subject.srandmember('key1', -100)

          expect(random_elements.size).to eq(100)
          expect(random_elements.uniq.size).to be <= 3
          random_elements.all? do |element|
            expect(['a', 'b', 'c']).to include(element)
          end
        end
      end

      context 'when called with an optional parameter of 100' do
        it 'is an array of all of the elements from the set, none of which are repeated' do
          random_elements = subject.srandmember('key1', 100)

          expect(random_elements.size).to eq(3)
          expect(random_elements.uniq.size).to eq(3)
          expect(random_elements).to match_array(['a', 'b', 'c'])
        end
      end
    end

    context 'with an empty set' do
      before { subject.del('key1') }

      it 'is nil without the extra parameter' do
        expect(subject.srandmember('key1')).to be_nil
      end

      it 'is an empty array with an extra parameter' do
        expect(subject.srandmember('key1', 1)).to eq([])
      end
    end
  end
end
