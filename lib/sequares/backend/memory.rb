require "byebug"
module Sequares
  module Backend
    class Memory
      using HashExtensions
      def initialize
        flushdb
      end

      def rpush(key, values)
        @hashes[key] ||= []
        @hashes[key].concat(Array(values))
      end

      def hset(key, k, v)
        @hashes[key] ||= {}
        @hashes[key].merge!(k => v)
      end

      def hmset(key, *kv_pairs)
        @hashes[key] ||= {}
        @hashes[key].merge!(kv_pairs.each_slice(2).to_h)
      end

      def hmget(key, *keys)
        Array(@hashes[key].slice(*keys).values)
      end

      def get(key)
        @hashes[key]
      end

      def set(key, value)
        @hashes[key] = value
      end

      def lrange(key, from, to)
        Array(Array(@hashes[key])[from..to])
      end

      def llen(key)
        Array(@hashes[key]).length
      end

      def multi
        yield self
      end

      def flushdb
        @hashes = {}
      end
    end
  end
end
