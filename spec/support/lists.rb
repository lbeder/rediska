shared_examples 'lists' do
  it 'should get an element from a list by its index' do
    subject.lpush('key1', 'val1')
    subject.lpush('key1', 'val2')

    expect(subject.lindex('key1', 0)).to eq('val2')
    expect(subject.lindex('key1', -1)).to eq('val1')
    expect(subject.lindex('key1', 3)).to be_nil
  end

  it 'should insert an element before or after another element in a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v3')
    subject.linsert('key1', :before, 'v3', 'v2')

    expect(subject.lrange('key1', 0, -1)).to eq(['v1', 'v2', 'v3'])
  end

  it 'should allow multiple values to be added to a list in a single rpush' do
    subject.rpush('key1', [1, 2, 3])
    expect(subject.lrange('key1', 0, -1)).to eq(['1', '2', '3'])
  end

  it 'should allow multiple values to be added to a list in a single lpush' do
    subject.lpush('key1', [1, 2, 3])
    expect(subject.lrange('key1', 0, -1)).to eq(['3', '2', '1'])
  end

  it 'should error if an invalid where argument is given' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v3')

    expect {
      subject.linsert('key1', :invalid, 'v3', 'v2')
    }.to raise_error(Redis::CommandError)
  end

  it 'should get the length of a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')

    expect(subject.llen('key1')).to eq(2)
    expect(subject.llen('key2')).to eq(0)
  end

  it 'should remove and get the first element in a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')
    subject.rpush('key1', 'v3')

    expect(subject.lpop('key1')).to eq('v1')
    expect(subject.lrange('key1', 0, -1)).to eq(['v2', 'v3'])
  end

  it 'should prepend a value to a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')

    expect(subject.lrange('key1', 0, -1)).to eq(['v1', 'v2'])
  end

  it 'should prepend a value to a list, only if the list exists' do
    subject.lpush('key1', 'v1')

    subject.lpushx('key1', 'v2')
    subject.lpushx('key2', 'v3')

    expect(subject.lrange('key1', 0, -1)).to eq(['v2', 'v1'])
    expect(subject.llen('key2')).to eq(0)
  end

  it 'should get a range of elements from a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')
    subject.rpush('key1', 'v3')

    expect(subject.lrange('key1', 1, -1)).to eq(['v2', 'v3'])
  end

  it 'should remove elements from a list' do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')
    subject.rpush('key1', 'v2')
    subject.rpush('key1', 'v2')
    subject.rpush('key1', 'v1')

    expect(subject.lrem('key1', 1, 'v1')).to eq(1)
    expect(subject.lrem('key1', -2, 'v2')).to eq(2)
    expect(subject.llen('key1')).to eq(2)
  end

  it "should remove list's key when list is empty" do
    subject.rpush('key1', 'v1')
    subject.rpush('key1', 'v2')
    subject.lrem('key1', 1, 'v1')
    subject.lrem('key1', 1, 'v2')

    expect(subject.exists('key1')).to be_falsey
  end

  it 'should set the value of an element in a list by its index' do
    subject.rpush('key1', 'one')
    subject.rpush('key1', 'two')
    subject.rpush('key1', 'three')

    subject.lset('key1', 0, 'four')
    subject.lset('key1', -2, 'five')
    expect(subject.lrange('key1', 0, -1)).to eq(['four', 'five', 'three'])

    expect {
      subject.lset('key1', 4, 'six')
    }.to raise_error(Redis::CommandError)
  end

  it 'should trim a list to the specified range' do
    subject.rpush('key1', 'one')
    subject.rpush('key1', 'two')
    subject.rpush('key1', 'three')

    subject.ltrim('key1', 1, -1)
    expect(subject.lrange('key1', 0, -1)).to eq(['two', 'three'])
  end

  context 'when the list is smaller than the requested trim' do
    before do
      subject.rpush('listOfOne', 'one')
    end

    context 'trimming with a negative start (specifying a max)' do
      before do
        subject.ltrim('listOfOne', -5, -1)
      end

      it 'returns the unmodified list' do
        expect(subject.lrange('listOfOne', 0, -1)).to  eq(['one'])
      end
    end
  end

  context 'when the list is larger than the requested trim' do
    before do
      subject.rpush('maxTest', 'one')
      subject.rpush('maxTest', 'two')
      subject.rpush('maxTest', 'three')
      subject.rpush('maxTest', 'four')
      subject.rpush('maxTest', 'five')
      subject.rpush('maxTest', 'six')
    end

    context 'trimming with a negative start (specifying a max)' do
      before do
        subject.ltrim('maxTest', -5, -1)
      end

      it 'should trim a list to the specified maximum size' do
        expect(subject.lrange('maxTest', 0, -1)).to eq(['two','three', 'four', 'five', 'six'])
      end
    end
  end

  it 'should remove and return the last element in a list' do
    subject.rpush('key1', 'one')
    subject.rpush('key1', 'two')
    subject.rpush('key1', 'three')

    expect(subject.rpop('key1')).to eq('three')
    expect(subject.lrange('key1', 0, -1)).to eq(['one', 'two'])
  end

  it 'should remove the last element in a list, append it to another list and return it' do
    subject.rpush('key1', 'one')
    subject.rpush('key1', 'two')
    subject.rpush('key1', 'three')

    expect(subject.rpoplpush('key1', 'key2')).to eq('three')

    expect(subject.lrange('key1', 0, -1)).to eq(['one', 'two'])
    expect(subject.lrange('key2', 0, -1)).to eq(['three'])
  end

  context 'when the source list is empty' do
    it 'rpoplpush does not add anything to the destination list' do
      subject.rpoplpush('source', 'destination')
      expect(subject.lrange('destination', 0, -1)).to eq([])
    end
  end

  it 'should append a value to a list' do
    subject.rpush('key1', 'one')
    subject.rpush('key1', 'two')

    expect(subject.lrange('key1', 0, -1)).to eq(['one', 'two'])
  end

  it 'should append a value to a list, only if the list exists' do
    subject.rpush('key1', 'one')
    subject.rpushx('key1', 'two')
    subject.rpushx('key2', 'two')

    expect(subject.lrange('key1', 0, -1)).to eq(['one', 'two'])
    expect(subject.lrange('key2', 0, -1)).to be_empty
  end
end
