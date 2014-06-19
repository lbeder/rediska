shared_examples 'sorted_method' do
  shared_examples_for 'sortable' do
    it 'returns empty array on nil' do
      expect(subject.sort(nil)).to eq([])
    end

    context 'ordering' do
      it 'orders ascending by default' do
        expect(subject.sort(key)).to eq(['1', '2'])
      end

      it 'orders by ascending when specified' do
        expect(subject.sort(key, order: 'ASC')).to eq(['1', '2'])
      end

      it 'orders by descending when specified' do
        expect(subject.sort(key, order: 'DESC')).to eq(['2', '1'])
      end

      it 'orders by ascending when alpha is specified' do
        expect(subject.sort(key, order: 'ALPHA')).to eq(['1', '2'])
      end
    end

    context 'projections' do
      it 'projects element when :get is #' do
        expect(subject.sort(key, get: '#')).to eq(['1', '2'])
      end

      it 'projects through a key pattern' do
        expect(subject.sort(key, get: 'fake-redis-test:values_*')).to eq(['a', 'b'])
      end

      it 'projects through a key pattern and reflects element' do
        expect(subject.sort(key, get: ['#', 'fake-redis-test:values_*'])).to eq([['1', 'a'], ['2', 'b']])
      end

      it 'projects through a hash key pattern' do
        expect(subject.sort(key, get: 'fake-redis-test:hash_*->key')).to eq(['x', 'y'])
      end
    end

    context 'weights' do
      it 'weights by projecting through a key pattern' do
        expect(subject.sort(key, by: 'fake-redis-test:weight_*')).to eq(['2', '1'])
      end

      it 'weights by projecting through a key pattern and a specific order' do
        expect(subject.sort(key, order: 'DESC', by: 'fake-redis-test:weight_*')).to eq(['1', '2'])
      end
    end

    context 'limit' do
      it 'only returns requested window in the enumerable' do
        expect(subject.sort(key, limit: [0, 1])).to eq(['1'])
      end
    end

    context 'store' do
      it 'stores into another key' do
        expect(subject.sort(key, store: 'fake-redis-test:some_bucket')).to eq(2)
        expect(subject.lrange('fake-redis-test:some_bucket', 0, -1)).to eq(['1', '2'])
      end

      it 'stores into another key with other options specified' do
        expect(subject.sort(key, store: 'fake-redis-test:some_bucket', by: 'fake-redis-test:weight_*')).to eq(2)
        expect(subject.lrange('fake-redis-test:some_bucket', 0, -1)).to eq(['2', '1'])
      end
    end
  end

  describe '#sort' do
    before do
      subject.set('fake-redis-test:values_1', 'a')
      subject.set('fake-redis-test:values_2', 'b')

      subject.set('fake-redis-test:weight_1', '2')
      subject.set('fake-redis-test:weight_2', '1')

      subject.hset('fake-redis-test:hash_1', 'key', 'x')
      subject.hset('fake-redis-test:hash_2', 'key', 'y')
    end

    context 'WRONGTYPE Operation' do
      it 'should not allow #sort on Strings' do
        subject.set('key1', 'Hello')

        expect {
          subject.sort('key1')
        }.to raise_error(Redis::CommandError)
      end

      it 'should not allow #sort on Hashes' do
        subject.hset('key1', 'k1', 'val1')
        subject.hset('key1', 'k2', 'val2')

        expect {
          subject.sort('key1')
        }.to raise_error(Redis::CommandError)
      end
    end

    context 'list' do
      let(:key) { 'fake-redis-test:list_sort' }

      before do
        subject.rpush(key, '1')
        subject.rpush(key, '2')
      end

      it_behaves_like 'sortable'
    end

    context 'set' do
      let(:key) { 'ake-redis-test:set_sort' }

      before do
        subject.sadd(key, '1')
        subject.sadd(key, '2')
      end

      it_behaves_like 'sortable'
    end

    context 'zset' do
      let(:key) { 'fake-redis-test:zset_sor' }

      before do
        subject.zadd(key, 100, '1')
        subject.zadd(key, 99, '2')
      end

      it_behaves_like 'sortable'
    end
  end
end
