shared_examples 'upcase method names' do
  it '#ZCOUNT' do
    subject.ZCOUNT('key', 2, 3).should eq(subject.zcount('key', 2, 3))
  end

  it '#ZSCORE' do
    subject.ZSCORE('key', 2).should eq(subject.zscore('key', 2))
  end
end
