module Sequares
  module Store
    class Base
      class << self
        def last_modified_for(klass, id)
          # noop
        end

        def cache_key_for(klass, id)
          # noop
        end
      end

      def initialize
      end

      def cache_keys_for(keypairs)
        keypairs.each_slice(2).collect do |klass, id|
          cache_key_for(klass, id)
        end
      end

      def etag_for(klass, id)
        Digest::MD5.hexdigest(cache_key_for(klass, id))
      end

      def etags_for(keypairs)
        cache_keys_for(keypairs).collect do |key|
          Digest::MD5.hexdigest(key)
        end
      end

      def reset
        # noop
      end

      def save_history_for_aggregate(obj)
        # noop
      end

      def fetch_history_for_aggregate(obj)
        # noop
      end

      def lock(obj)
        # noop
      end

      def unlock(obj)
        # noop
      end
    end
  end
end
