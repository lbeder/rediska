shared_examples 'transactions' do
  context '#multi' do
    it "should respond with 'OK'" do
      expect(subject.multi).to eq('OK')
    end

    it "should forbid nesting" do
      subject.multi
      expect{subject.multi}.to raise_error(Redis::CommandError)
    end

    it "should mark the start of a transaction block" do
      transaction = subject.multi do |multi|
        multi.set('key1', '1')
        multi.set('key2', '2')
        multi.mget('key1', 'key2')
      end

      expect(transaction).to eq(['OK', 'OK', ['1', '2']])
    end
  end

  context '#discard' do
    it "should responde with 'OK' after #multi" do
      subject.multi
      expect(subject.discard).to eq('OK')
    end

    it "can't be run outside of #multi/#exec" do
      expect{subject.discard}.to raise_error(Redis::CommandError)
    end
  end

  context '#exec' do
    it "can't be run outside of #multi" do
      expect{subject.exec}.to raise_error(Redis::CommandError)
    end
  end

  context 'saving up commands for later' do
    before(:each) do
      subject.multi
    end

    let(:string) { 'fake-redis-test:string' }
    let(:list) { 'fake-redis-test:list' }

    it "makes commands respond with 'QUEUED'" do
      expect(subject.set(string, 'string')).to eq('QUEUED')
      expect(subject.lpush(list, 'list')).to eq('QUEUED')
    end

    it "gives you the commands' responses when you call #exec" do
      subject.set(string, 'string')
      subject.lpush(list, 'list')
      subject.lpush(list, 'list')

      expect(subject.exec).to eq(['OK', 1, 2])
    end

    it "does not raise exceptions, but rather puts them in #exec's response" do
      subject.set(string, 'string')
      subject.lpush(string, 'oops!')
      subject.lpush(list, 'list')

      responses = subject.exec
      expect(responses[0]).to eq('OK')
      expect(responses[1]).to be_a(RuntimeError)
      expect(responses[2]).to eq(1)
    end
  end
end
