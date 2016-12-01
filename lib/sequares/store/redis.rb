# frozen_string_literal: true
require "digest/md5"
require "redis"
require "active_support/inflector"

module Sequares
  module Store
    class Redis < Base
      attr_accessor :connection

      def initialize(connection=::Redis.new)
        @connection = connection
      end

      def filter_events(*klasses)
        entity_event_pairs = {}
        connection.keys.each do |key|
          next unless connection.type(key) == "list"
          events = connection.lrange(key, 0, -1).to_a.collect do |hist|
            ::Marshal.load(hist)
          end

          events.each do |event|
            next unless klass_in_klasses?(event, klasses)
            key_split = key.split("|")
            klass = ActiveSupport::Inflector.classify(key_split.first).constantize.new(key_split.last)
            entity_event_pairs[klass] = event
          end
        end
        entity_event_pairs
      end

      def reset
        connection.flushdb
      end

      def cache_key_for(klass, id)
        inst = klass.with_history(id, [])
        "#{inst.uri}##{connection.llen(inst.uri)}"
      end

      def save_history_for_aggregate(obj)
        marshaled_objects = obj.history.to_a.collect do |c|
          ::Marshal.dump(c)
        end
        connection.multi do
          # NOTE use rpush instead of del
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
