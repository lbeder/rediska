shared_examples 'transactions' do
  it 'should mark the start of a transaction block' do
    transaction = subject.multi do
      subject.set('key1', '1')
      subject.set('key2', '2')
      subject.mget('key1', 'key2')
    end

    transaction.should eq(['OK', 'OK', ['1', '2']])
  end

  it 'should execute all command after multi' do
    subject.multi
    subject.set('key1', '1')
    subject.set('key2', '2')
    subject.mget('key1', 'key2')
    subject.exec.should be == ['OK', 'OK', ['1', '2']]
  end
end
