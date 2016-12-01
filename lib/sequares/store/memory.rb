require "byebug"
require "active_support/inflector"
module Sequares
  module Store
    class Memory < Base
      class << self
        def cache_key_for(klass, id)
          inst = klass.with_history(id, [])
          "#{inst.uri}|#{histories.length}"
        end
      end
      attr_accessor :histories, :locks, :all_histories
      def initialize
        @all_histories = {}
        @histories = Hash.new { |hash, key| hash[key] = [] }
        @locks = Hash.new { |hash, key| hash[key] = Mutex.new }
      end

      def klass_in_klasses?(needle, klasses)
        klasses.any? do |klass|
          needle.is_a?(klass) || needle.class.to_s.split("::").first.eql?(klass.to_s)
        end
      end

      def filter_events(*klasses)
        events = {}
        all_histories.each do |event, entity|
          events[entity] = event if klass_in_klasses?(event, klasses)
        end
        events
      end

      def cache_key_for(klass, id)
        inst = klass.with_history(id, [])
        [inst.uri, histories[inst.uri].length].join("#")
      end

      def save_history_for_aggregate(obj)
        histories[obj.uri].concat(unsaved_history(obj))
        obj.history.each do |event|
          all_histories[event] = obj.class.new(obj.id)
        end
      end

      def fetch_history_for_aggregate(obj)
        histories[obj.uri].clone
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
