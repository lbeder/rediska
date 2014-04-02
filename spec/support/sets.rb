shared_examples 'sets' do
  it 'should add a member to a set' do
    subject.sadd('key', 'value').should be_true
    subject.sadd('key', 'value').should be_false

    subject.smembers('key').should =~ ['value']
  end

  it 'should raise error if command arguments count is not enough' do
    expect {
      subject.sadd('key', [])
    }.to raise_error(Redis::CommandError)

    expect {
      subject.sinter(*[])
    }.to raise_error(Redis::CommandError)

    subject.smembers('key').should be_empty
  end

  it 'should add multiple members to a set' do
    subject.sadd('key', %w(value other something more)).should eq(4)
    subject.sadd('key', %w(and additional values)).should eq(3)
    subject.smembers('key').should =~ ['value', 'other', 'something', 'more', 'and', 'additional', 'values']
  end

  it 'should get the number of members in a set' do
    subject.sadd('key', 'val1')
    subject.sadd('key', 'val2')

    subject.scard('key').should eq(2)
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

    subject.sdiff('key1', 'key2', 'key3').should =~ ['b', 'd']
  end

  it 'should subtract from a nonexistent set' do
    subject.sadd('key2', 'a')
    subject.sadd('key2', 'b')
    subject.sdiff('key1', 'key2').should be_empty
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

    subject.smembers('key').should =~ ['b', 'd']
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

    subject.sinter('key1', 'key2', 'key3').should =~ ['c']
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
    subject.smembers('key').should =~ ['c']
  end

  it 'should determine if a given value is a member of a set' do
    subject.sadd('key1', 'a')

    subject.sismember('key1', 'a').should be_true
    subject.sismember('key1', 'b').should be_false
    subject.sismember('key2', 'a').should be_false
  end

  it 'should get all the members in a set' do
    subject.sadd('key', 'a')
    subject.sadd('key', 'b')
    subject.sadd('key', 'c')
    subject.sadd('key', 'd')

    subject.smembers('key').should =~ ['a', 'b', 'c', 'd']
  end

  it 'should move a member from one set to another' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.sadd('key2', 'c')
    subject.smove('key1', 'key2', 'a').should be_true
    subject.smove('key1', 'key2', 'a').should be_false

    subject.smembers('key1').should =~ ['b']
    subject.smembers('key2').should =~ ['c', 'a']
  end

  it 'should remove and return a random member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')

    ['a', 'b'].include?(subject.spop('key1')).should be_true
    ['a', 'b'].include?(subject.spop('key1')).should be_true
    subject.spop('key1').should be_nil
  end

  it 'should get a random member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')

    ['a', 'b'].include?(subject.spop('key1')).should be_true
  end

  it 'should remove a member from a set' do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.srem('key1', 'a').should be_true
    subject.srem('key1', 'a').should be_false

    subject.smembers('key1').should =~ ['b']
  end

  it "should remove the set's key once it's empty" do
    subject.sadd('key1', 'a')
    subject.sadd('key1', 'b')
    subject.srem('key1', 'b')
    subject.srem('key1', 'a')

    subject.exists('key1').should be_false
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

    subject.sunion('key1', 'key2', 'key3').should =~ ['a', 'b', 'c', 'd', 'e']
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

    subject.smembers('key').should =~ ['a', 'b', 'c', 'd', 'e']
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

          ['a', 'b', 'c'].should include(random_element)
        end
      end

      context 'when called with the optional number parameter of 1' do
        it 'is an array of one random element from the set' do
          subject.srandmember('key1', 1)

          [['a'], ['b'], ['c']].should include(subject.srandmember('key1', 1))
        end
      end

      context 'when called with the optional number parameter of 2' do
        it 'is an array of two unique, random elements from the set' do
          random_elements = subject.srandmember('key1', 2)

          random_elements.should have(2).items
          random_elements.uniq.should have(2).items
          random_elements.all? do |element|
            ['a', 'b', 'c'].should include(element)
          end
        end
      end

      context 'when called with an optional parameter of -100' do
        it 'is an array of 100 random elements from the set, some of which are repeated' do
          random_elements = subject.srandmember('key1', -100)

          random_elements.should have(100).items
          random_elements.uniq.should have_at_most(3).items
          random_elements.all? do |element|
            ['a', 'b', 'c'].should include(element)
          end
        end
      end

      context 'when called with an optional parameter of 100' do
        it 'is an array of all of the elements from the set, none of which are repeated' do
          random_elements = subject.srandmember('key1', 100)

          random_elements.should have(3).items
          random_elements.uniq.should have(3).items
          random_elements.should =~ ['a', 'b', 'c']
        end
      end
    end

    context 'with an empty set' do
      before { subject.del('key1') }

      it 'is nil without the extra parameter' do
        subject.srandmember('key1').should be_nil
      end

      it 'is an empty array with an extra parameter' do
        subject.srandmember('key1', 1).should == []
      end
    end
  end
end
