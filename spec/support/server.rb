shared_examples 'server' do
  it 'should return the number of keys in the selected database' do
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.set('key2', 'two')

    subject.dbsize.should eq(2)
  end

  it 'should get information and statistics about the server' do
    subject.info.key?('redis_version').should be_true
  end

  it 'should handle non-existent methods' do
    expect {
      subject.idontexist
    }.to raise_error(Redis::CommandError)
  end

  describe 'multiple databases' do
    it 'should default to database 0' do
      subject.inspect.should =~ %r#/0>$#
    end

    it 'should select another database' do
      subject.select(1)
      subject.inspect.should =~ %r#/1>$#
    end

    it 'should store keys separately in each database' do
      subject.select(0).should eq('OK')
      subject.set('key1', '1')
      subject.set('key2', '2')

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      subject.set('key5', '5')

      subject.select(0)
      subject.dbsize.should eq(2)
      subject.exists('key1').should be_true
      subject.exists('key3').should be_false

      subject.select(1)
      subject.dbsize.should eq(3)
      subject.exists('key4').should be_true
      subject.exists('key2').should be_false

      subject.flushall
      subject.dbsize.should eq(0)

      subject.select(0)
      subject.dbsize.should eq(0)
    end

    it 'should flush a database' do
      subject.select(0)
      subject.set('key1', '1')
      subject.set('key2', '2')
      subject.dbsize.should eq(2)

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      subject.dbsize.should eq(2)

      subject.flushdb.should eq('OK')

      subject.dbsize.should eq(0)
      subject.select(0)
      subject.dbsize.should eq(2)
    end

    it 'should flush all databases' do
      subject.select(0)
      subject.set('key3', '3')
      subject.set('key4', '4')
      subject.dbsize.should eq(2)

      subject.select(1)
      subject.set('key3', '3')
      subject.set('key4', '4')
      subject.dbsize.should eq(2)

      subject.flushall.should eq('OK')

      subject.dbsize.should eq(0)
      subject.select(0)
      subject.dbsize.should eq(0)
    end
  end
end
