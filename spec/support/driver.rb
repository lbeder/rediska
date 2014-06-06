shared_examples 'driver' do
  describe '#time' do
    before(:each) do
      allow(Time).to receive_message_chain(:now, :to_f).and_return(1397845595.5139461)
    end

    it 'is an array' do
      expect(subject.time).to be_an_instance_of(Array)
    end

    it 'has two elements' do
      expect(subject.time.count).to eq(2)
    end

    it 'has the current time in seconds' do
      expect(subject.time.first).to eq(1397845595)
    end

    it 'has the current leftover microseconds' do
      expect(subject.time.last).to eq(513946)
    end
  end
end
