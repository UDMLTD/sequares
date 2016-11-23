# frozen_string_literal: true
require "digest/md5"
require "redis"
module Sequares
  module Store
    class Redis < Base
      attr_accessor :connection

      def initialize(connection=::Redis.new)
        @connection = connection
      end

      def filter_events(*klasses)
        events = []
        connection.keys.each do |key|
          history_events = begin
                             fetch_history_for_uri(key)
                           rescue
                             nil
                           end
          events.concat(history_events) if history_events && history_events.any?
        end

        events.sort_by(&:occurred_at).select do |event|
          event if klasses.any? do |klass|
            event.is_a?(klass) || event.class.to_s.split("::").first.eql?(klass.to_s)
          end
        end
      end

      def reset
        connection.flushdb
      end

      def cache_key_for(klass, id)
        inst = klass.with_history(id, [])
        "#{inst.uri}|#{connection.llen(inst.uri)}"
      end

      def save_history_for_aggregate(obj)
        marshaled_objects = obj.history.to_a.collect do |c|
          ::Marshal.dump(c)
        end
        connection.multi do
          connection.sadd obj.class.name.to_s.downcase, obj.uri
          connection.del obj.uri
          marshaled_objects.each do |mobj|
            connection.rpush obj.uri, mobj
          end
        end
      end

      def fetch_history_for_aggregate(obj)
        fetch_history_for_uri(obj.uri)
      end

      def fetch_history_for_uri(uri)
        connection.lrange(uri, 0, -1).to_a.collect do |hist|
          ::Marshal.load(hist)
        end
      end

      def lock(obj)
        raise ::Sequares::Entity::AlreadyLocked unless connection.setnx(
          obj.uri + ":lock", Time.now.utc
        )
      end

      def unlock(obj)
        connection.del obj.uri + ":lock"
      end
    end
  end
end
