shared_examples 'compatibility' do
  it 'should be accessible through Rediska::Redis' do
    expect {
      Rediska::Redis.new
    }.not_to raise_error
  end
end
