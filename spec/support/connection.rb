shared_examples 'connection' do
  it 'should authenticate to the server' do
    begin
      subject.auth('pass').should eq('OK')
    rescue Redis::CommandError => e
      raise unless e.message == 'ERR Client sent AUTH, but no password is set'
    end
  end

  it 'should re-use the same instance with the same host and port' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379)
    subject2 = Redis.new(host: '127.0.0.1', port: 6379)

    subject1.set('key1', '1')
    subject2.get('key1').should eq('1')

    subject2.set('key2', '2')
    subject1.get('key2').should eq('2')

    subject1.get('key3').should be_nil
    subject2.get('key3').should be_nil

    subject1.dbsize.should eq(2)
    subject2.dbsize.should eq(2)
  end

  it 'should connect to a specific database' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379, db: 0)
    subject1.set('key1', '1')
    subject1.select(0)
    subject1.get('key1').should eq('1')

    subject2 = Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    subject2.set('key1', '1')
    subject2.select(1)
    subject2.get('key1').should eq('1')
  end

  it 'should handle multiple clients using the same db instance' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    subject2 = Redis.new(host: '127.0.0.1', port: 6379, db: 2)

    subject1.set('key1', 'one')
    subject1.get('key1').should eq('one')

    subject2.set('key2', 'two')
    subject2.get('key2').should eq('two')

    subject1.get('key1').should eq('one')
  end

  it 'should not error with a disconnected client' do
    subject1 = Redis.new
    subject1.client.disconnect
    subject1.get('key1').should be_nil
  end

  it 'should echo the given string' do
    subject.echo('something').should eq('something')
  end

  it 'should ping the server' do
    subject.ping.should eq('PONG')
  end
end
