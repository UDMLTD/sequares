module Sequares
  module Backend
    class Memory
      using HashExtensions
      def initialize
        @hashes = {}
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
        @hashes[key].slice(*keys).values
      end

      def set(key, value)
        @hashes[key] = value
      end

      def lrange(key, from, to)
        Array(@hashes[key])[from..to]
      end

      def multi
        yield self
      end
    end
  end
end
