require 'spec_helper'

shared_examples_for 'a bitwise operation' do |operator|
  it 'raises an argument error when not passed any source keys' do
    expect {
      subject.bitop(operator, 'destkey')
    }.to raise_error(Redis::CommandError)
  end

  it 'should not create destination key if nothing found' do
    expect(subject.bitop(operator, 'dest1', 'nothing_here1')).to eq(0)
    expect(subject.exists('dest1')).to eq(0)
  end

  it 'should accept operator as a case-insensitive symbol' do
    subject.set('key1', 'foobar')
    subject.bitop(operator.to_s.downcase.to_sym, 'dest1', 'key1')
    subject.bitop(operator.to_s.upcase.to_sym, 'dest2', 'key1')

    expect(subject.get('dest1')).to eq('foobar')
    expect(subject.get('dest2')).to eq('foobar')
  end

  it 'should accept operator as a case-insensitive string' do
    subject.set('key1', 'foobar')
    subject.bitop(operator.to_s.downcase, 'dest1', 'key1')
    subject.bitop(operator.to_s.upcase, 'dest2', 'key1')

    expect(subject.get('dest1')).to eq('foobar')
    expect(subject.get('dest2')).to eq('foobar')
  end

  it 'should copy original string for single key' do
    subject.set('key1', 'foobar')
    subject.bitop(operator, 'dest1', 'key1')

    expect(subject.get('dest1')).to eq('foobar')
  end

  it 'should copy original string for single key' do
    subject.set('key1', 'foobar')
    subject.bitop(operator, 'dest1', 'key1')

    expect(subject.get('dest1')).to eq('foobar')
  end

  it 'should return length of the string stored in the destination key' do
    subject.set('key1', 'foobar')
    subject.set('key2', 'baz')

    expect(subject.bitop(operator, 'dest1', 'key1')).to eq(6)
    expect(subject.bitop(operator, 'dest2', 'key2')).to eq(3)
  end

  it 'should overwrite previous value with new one' do
    subject.set('key1', 'foobar')
    subject.set('key2', 'baz')
    subject.bitop(operator, 'dest1', 'key1')
    subject.bitop(operator, 'dest1', 'key2')

    expect(subject.get('dest1')).to eq('baz')
  end
end

shared_examples 'bitop' do
  it 'raises an argument error when passed unsupported operation' do
    expect {
      subject.bitop('meh', 'dest1', 'key1')
    }.to raise_error(Redis::CommandError)
  end

  describe 'or' do
    it_should_behave_like 'a bitwise operation', 'or'

    it 'should apply bitwise or operation' do
      subject.setbit('key1', 0, 0)
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 2, 1)
      subject.setbit('key1', 3, 0)

      subject.setbit('key2', 0, 1)
      subject.setbit('key2', 1, 1)
      subject.setbit('key2', 2, 0)
      subject.setbit('key2', 3, 0)

      expect(subject.bitop('or', 'dest1', 'key1', 'key2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(3)
      expect(subject.getbit('dest1', 0)).to eq(1)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(0)
    end

    it 'should apply bitwise or operation with empty values' do
      subject.setbit('key1', 1, 1)

      expect(subject.bitop('or', 'dest1', 'key1', 'nothing_here1', 'nothing_here2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(1)
      expect(subject.getbit('dest1', 0)).to eq(0)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(0)
    end

    it 'should apply bitwise or operation with multiple keys' do
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 3, 1)

      subject.setbit('key2', 5, 1)
      subject.setbit('key2', 10, 1)

      subject.setbit('key3', 13, 1)
      subject.setbit('key3', 15, 1)

      expect(subject.bitop('or', 'dest1', 'key1', 'key2', 'key3')).to eq(2)
      expect(subject.bitcount('dest1')).to eq(6)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(1)
      expect(subject.getbit('dest1', 5)).to eq(1)
      expect(subject.getbit('dest1', 10)).to eq(1)
      expect(subject.getbit('dest1', 13)).to eq(1)
      expect(subject.getbit('dest1', 15)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(0)
      expect(subject.getbit('dest1', 12)).to eq(0)
    end
  end

  describe 'and' do
    it_should_behave_like 'a bitwise operation', 'and'

    it 'should apply bitwise and operation' do
      subject.setbit('key1', 0, 1)
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 2, 0)

      subject.setbit('key2', 0, 0)
      subject.setbit('key2', 1, 1)
      subject.setbit('key2', 2, 1)

      expect(subject.bitop('and', 'dest1', 'key1', 'key2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(1)
      expect(subject.getbit('dest1', 0)).to eq(0)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(0)
    end

    it 'should apply bitwise and operation with empty values' do
      subject.setbit('key1', 1, 1)

      expect(subject.bitop('and', 'dest1', 'key1', 'nothing_here')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(1)
      expect(subject.getbit('dest1', 0)).to eq(0)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(0)
    end

    it 'should apply bitwise and operation with multiple keys' do
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 2, 1)
      subject.setbit('key1', 3, 1)
      subject.setbit('key1', 4, 1)

      subject.setbit('key2', 2, 1)
      subject.setbit('key2', 3, 1)
      subject.setbit('key2', 4, 1)
      subject.setbit('key2', 5, 1)

      subject.setbit('key3', 2, 1)
      subject.setbit('key3', 4, 1)
      subject.setbit('key3', 5, 1)
      subject.setbit('key3', 6, 1)

      expect(subject.bitop('and', 'dest1', 'key1', 'key2', 'key3')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(2)
      expect(subject.getbit('dest1', 1)).to eq(0)
      expect(subject.getbit('dest1', 2)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(0)
      expect(subject.getbit('dest1', 4)).to eq(1)
      expect(subject.getbit('dest1', 5)).to eq(0)
      expect(subject.getbit('dest1', 6)).to eq(0)
    end
  end

  describe 'xor' do
    it_should_behave_like 'a bitwise operation', 'xor'

    it 'should apply bitwise xor operation' do
      subject.setbit('key1', 0, 0)
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 2, 0)
      subject.setbit('key1', 3, 0)

      subject.setbit('key2', 0, 1)
      subject.setbit('key2', 1, 1)
      subject.setbit('key2', 2, 1)
      subject.setbit('key2', 3, 0)

      expect(subject.bitop('xor', 'dest1', 'key1', 'key2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(2)
      expect(subject.getbit('dest1', 0)).to eq(1)
      expect(subject.getbit('dest1', 1)).to eq(0)
      expect(subject.getbit('dest1', 2)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(0)
    end

    it 'should apply bitwise xor operation with empty values' do
      subject.setbit('key1', 1, 1)

      expect(subject.bitop('xor', 'dest1', 'key1', 'nothing_here1', 'nothing_here2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(1)
      expect(subject.getbit('dest1', 0)).to eq(0)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(0)
    end

    it 'should apply bitwise xor operation with multiple keys' do
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 3, 1)
      subject.setbit('key1', 5, 1)
      subject.setbit('key1', 6, 1)

      subject.setbit('key2', 2, 1)
      subject.setbit('key2', 3, 1)
      subject.setbit('key2', 4, 1)
      subject.setbit('key2', 6, 1)

      expect(subject.bitop('xor', 'dest1', 'key1', 'key2')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(4)
      expect(subject.getbit('dest1', 1)).to eq(1)
      expect(subject.getbit('dest1', 2)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(0)
      expect(subject.getbit('dest1', 4)).to eq(1)
      expect(subject.getbit('dest1', 5)).to eq(1)
      expect(subject.getbit('dest1', 6)).to eq(0)
    end
  end

  describe 'not' do
    it 'raises an argument error when not passed any keys' do
      expect {
        subject.bitop('not', 'destkey')
      }.to raise_error(Redis::CommandError)
    end

    it 'raises an argument error when not passed too many keys' do
      expect {
        subject.bitop('not', 'destkey', 'key1', 'key2')
      }.to raise_error(Redis::CommandError)
    end

    it 'should apply bitwise negation operation' do
      subject.setbit('key1', 1, 1)
      subject.setbit('key1', 3, 1)
      subject.setbit('key1', 5, 1)

      expect(subject.bitop('not', 'dest1', 'key1')).to eq(1)
      expect(subject.bitcount('dest1')).to eq(5)
      expect(subject.getbit('dest1', 0)).to eq(1)
      expect(subject.getbit('dest1', 1)).to eq(0)
      expect(subject.getbit('dest1', 2)).to eq(1)
      expect(subject.getbit('dest1', 3)).to eq(0)
      expect(subject.getbit('dest1', 4)).to eq(1)
      expect(subject.getbit('dest1', 5)).to eq(0)
      expect(subject.getbit('dest1', 6)).to eq(1)
      expect(subject.getbit('dest1', 7)).to eq(1)
    end
  end
end
