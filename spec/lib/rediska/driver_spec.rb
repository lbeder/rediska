require 'spec_helper'

describe Rediska::Driver do
  subject { Redis.new }

  describe '#time' do
    before(:each) do
      Time.stub_chain(:now, :to_f).and_return(1397845595.5139461)
    end

    it 'is an array' do
      subject.time.should be_an_instance_of(Array)
    end

    it 'has two elements' do
      subject.time.count.should eq(2)
    end

    it 'has the current time in seconds' do
      subject.time.first.should eq(1397845595)
    end

    it 'has the current leftover microseconds' do
      subject.time.last.should eq(513946)
    end
  end
end
