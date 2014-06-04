shared_examples 'server' do
  it 'should return the number of keys in the selected database' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.set('key2', 'two')

    expect(subject.dbsize).to eq(2)
  end

  it 'should get information and statistics about the server' do
    expect(subject.info.key?('redis_version')).to be_truthy
  end

  it 'should handle non-existent methods' do
    expect {
      subject.idontexist
    }.to raise_error(Redis::CommandError)
  end

  describe 'multiple databases' do
    it 'should default to database 0' do
      expect(subject.inspect).to match(%r#/0>$#)
    end

    it 'should select another database' do
      subject.select(1)
      expect(subject.inspect).to match(%r#/1>$#)
    end

    it 'should store keys separately in each database' do
      expect(subject.select(0)).to eq('OK')
      subject.set('key1', '1')
      subject.set('key2', '2')

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      subject.set('key5', '5')

      subject.select(0)
      expect(subject.dbsize).to eq(2)
      expect(subject.exists('key1')).to be_truthy
      expect(subject.exists('key3')).to be_falsey

      subject.select(1)
      expect(subject.dbsize).to eq(3)
      expect(subject.exists('key4')).to be_truthy
      expect(subject.exists('key2')).to be_falsey

      subject.flushall
      expect(subject.dbsize).to eq(0)

      subject.select(0)
      expect(subject.dbsize).to eq(0)
    end

    it 'should flush a database' do
      subject.select(0)
      subject.set('key1', '1')
      subject.set('key2', '2')
      expect(subject.dbsize).to eq(2)

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      expect(subject.dbsize).to eq(2)

      expect(subject.flushdb).to eq('OK')

      expect(subject.dbsize).to eq(0)
      subject.select(0)
      expect(subject.dbsize).to eq(2)
    end

    it 'should flush all databases' do
      subject.select(0)
      subject.set('key3', '3')
      subject.set('key4', '4')
      expect(subject.dbsize).to eq(2)

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      expect(subject.dbsize).to eq(2)

      expect(subject.flushall).to eq('OK')

      expect(subject.dbsize).to eq(0)
      subject.select(0)
      expect(subject.dbsize).to eq(0)
    end
  end
end
