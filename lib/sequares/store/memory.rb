module Sequares
  module Store
    class Memory < Base
      class << self
        def cache_key_for(klass, id)
          inst = klass.with_history(id, [])
          "#{inst.uri}|#{histories}"
        end
      end
      attr_accessor :histories, :locks
      def initialize
        @histories = Hash.new { |hash, key| hash[key] = [] }
        @locks = Hash.new { |hash, key| hash[key] = Mutex.new }
      end

      def cache_key_for(klass, id)
        inst = klass.with_history(id, [])
        "#{inst.uri}|#{histories[inst.uri].length}"
      end

      def save_history_for_aggregate(obj)
        histories[obj.uri] = obj.history
      end

      def fetch_history_for_aggregate(obj)
        histories[obj.uri]
      end

      def lock(obj)
        raise ::Sequares::Entity::AlreadyLocked unless locks[obj.uri].try_lock
      end

      def unlock(obj)
        locks[obj.uri].unlock
      end
    end
  end
end
