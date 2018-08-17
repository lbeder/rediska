shared_examples 'connection' do
  it 'should authenticate to the server' do
    begin
      expect(subject.auth('pass')).to eq('OK')
    rescue Redis::CommandError => e
      raise unless e.message == 'ERR Client sent AUTH, but no password is set'
    end
  end

  it 'should re-use the same instance with the same host and port' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379)
    subject2 = Redis.new(host: '127.0.0.1', port: 6379)

    subject1.set('key1', '1')
    expect(subject2.get('key1')).to eq('1')

    subject2.set('key2', '2')
    expect(subject1.get('key2')).to eq('2')

    expect(subject1.get('key3')).to be_nil
    expect(subject2.get('key3')).to be_nil

    expect(subject1.dbsize).to eq(2)
    expect(subject2.dbsize).to eq(2)
  end

  it 'should connect to a specific database' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379, db: 0)
    subject1.set('key1', '1')
    subject1.select(0)
    expect(subject1.get('key1')).to eq('1')

    subject2 = Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    subject2.set('key1', '1')
    subject2.select(1)
    expect(subject2.get('key1')).to eq('1')
  end

  it 'should handle multiple clients using the same db instance' do
    subject1 = Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    subject2 = Redis.new(host: '127.0.0.1', port: 6379, db: 2)

    subject1.set('key1', 'one')
    expect(subject1.get('key1')).to eq('one')

    subject2.set('key2', 'two')
    expect(subject2.get('key2')).to eq('two')

    expect(subject1.get('key1')).to eq('one')
  end

  it 'should not error with a disconnected client' do
    subject1 = Redis.new
    subject1.disconnect
    expect(subject1.get('key1')).to be_nil
  end

  it 'should echo the given string' do
    expect(subject.echo('something')).to eq('something')
  end

  it 'should ping the server' do
    expect(subject.ping).to eq('PONG')
  end
end
