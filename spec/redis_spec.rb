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
  it_behaves_like 'bitop'

  it_behaves_like 'driver'
  it_behaves_like 'sidekiq'
end

describe 'Rediska' do
  subject { Redis.new }

  before do
    Rediska.configure do |config|
      config.namespace = 'rediska_test'
    end

    subject.flushall
    subject.discard rescue nil
  end

  context 'fake redis' do
    context 'memory' do
      it_behaves_like 'redis'
    end

    context 'PStore' do
      before do
        Rediska.configure do |config|
          config.database = :filesystem
        end
      end

      it_behaves_like 'redis'
    end
  end

  context 'real redis (interoperability)' do
    before(:all) do
      Redis::Connection.drivers.pop
    end

    after(:all) do
      Redis::Connection.drivers << Rediska::Connection
    end

    it_behaves_like 'redis'
  end
end
