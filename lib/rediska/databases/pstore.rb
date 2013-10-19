require 'pstore'
require 'tmpdir'

require 'rediska/databases/expiring'

module Rediska
  module Utilities
    class SyncedPStore < ::PStore
      def initialize(file)
        super(file, false)
      end

      def transaction(read_only = false, &block)
        @flock ||= path + '.lock'

        File.open(@flock, File::RDWR | File::CREAT) do
          super
        end
      end
    end
  end

  module Databases
    class PStore
      include Expiring

      def initialize(instance_key, id)
        @id = id

        @store = self.class.pstore(instance_key)
        @store.transaction do
          @store[db_name] ||= {}
          @db = @store[db_name]
        end

        super()
      end

      def method_missing(*args, &block)
        @store.transaction do
          hash = @db
          hash.send(*args, &block)
        end
      end

      class << self
        def flushdb(instance_key, id)
          store = pstore(instance_key)
          store.transaction { store.delete(db_name(id)) }
        end

        def flushall(instance_key)
          store = pstore(instance_key)
          store.transaction { store.roots.each {|r| store.delete(r) } }
        end

        def pstore(instance_key)
          Utilities::SyncedPStore.new(File.join(Dir.tmpdir, instance_key.to_s))
        end

        def db_name(id)
         "redis-#{id}"
        end
      end

      private
      def db_name
        self.class.db_name(@id)
      end
    end
  end
end
