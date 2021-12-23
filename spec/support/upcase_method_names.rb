shared_examples 'upcase method names' do
  it '#ZCOUNT' do
    expect(subject.ZCOUNT('key', 2, 3)).to eq(subject.zcount('key', 2, 3))
  end
end
