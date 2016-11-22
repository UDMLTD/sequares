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

      def filter_events(*klasses)
        events = []
        @histories.each do |key, value|
          events.concat(value)
        end
        events.sort_by do |event|
          event.occurred_at
        end.select do |event|
          event if klasses.any? do |klass|
            event.is_a?(klass) || event.class.to_s.split('::').first.eql?(klass.to_s)
          end
        end
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
