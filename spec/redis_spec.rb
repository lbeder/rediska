require 'spec_helper'

shared_examples 'redis' do
  it_behaves_like 'compatibility'
  it_behaves_like 'hashes'
  it_behaves_like 'connection'
  it_behaves_like 'keys'
  it_behaves_like 'lists'
  it_behaves_like 'server'
  it_behaves_like 'sets'
  it_behaves_like 'strings'
  it_behaves_like 'transactions'
  it_behaves_like 'sorted sets'
  it_behaves_like 'upcase method names'
end

describe 'Rediska' do
  subject { Redis.new }

  context 'fake redis' do
    pending 'memory' do
      before do
        subject.flushall
      end

      it_behaves_like 'redis'
    end

    context 'PStore' do
      before do
        Rediska.configure do |config|
          config.persistent = true
        end

        subject.flushall
      end

      it_behaves_like 'redis'
    end
  end

  # Remove the pending declaration in order to test interoperability with a local instance of redis.
  pending 'real redis (interoperability)' do
    before do
      subject.flushall
    end

    before(:all) do
      Redis::Connection.drivers.pop
    end

    after(:all) do
      Redis::Connection.drivers << Rediska::Connection
    end

    it_behaves_like 'redis'
  end
end
