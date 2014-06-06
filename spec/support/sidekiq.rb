shared_examples 'sidekiq' do
  describe Sidekiq do
    class Worker
      include Sidekiq::Worker

      def perform(data)
      end
    end

    it 'integrates with sidekiq' do
      expect {
        Worker.perform_async('spec')
      }.not_to raise_error
    end
  end
end
