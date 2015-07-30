require 'rediska/databases/memory'
require 'rediska/databases/pstore'
require 'rediska/sort_method'
require 'rediska/sorted_set_argument_handler'
require 'rediska/sorted_set_store'
require 'rediska/zset'
require 'rediska/bitop'
require 'rediska/driver'
require 'rediska/command_executor'
require 'rediska/transaction_commands'

module Rediska
  class Connection
    include Driver
    include SortMethod
    include Bitop
    include TransactionCommands
    include CommandExecutor


    class << self
      def databases
        @databases ||= Hash.new {|h,k| h[k] = [] }
      end

      def reset
        if @databases
          @databases.values do |db|
            db.class.reset
            db.each(&:clear)
          end

          @databases = nil
        end
      end

      def connect(options = {})
        new(options)
      end
    end

    def initialize(options = {})
      @options = options
      @database_id = 0
    end

    def database_instance_key
      @database_instance_key ||= [@options[:host], @options[:port], Rediska.configuration.namespace].
        compact.join(':')
    end

    def databases
      self.class.databases[database_instance_key]
    end

    def find_database(id = database_id)
      databases[id] ||= db_class.new(database_instance_key, id)
    end

    def data
      find_database
    end

    private
    def db_class
      case Rediska.configuration.database
      when :memory
        Rediska::Databases::Memory
      when :filesystem
        Rediska::Databases::PStore
      else
        raise ArgumentError, "invalid database type: #{Rediska.configuration.database}"
      end
    end
  end
end
