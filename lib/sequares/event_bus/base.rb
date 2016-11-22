module Sequares
  module EventBus
    class Base
      attr_accessor :subscriptions
      def initialize(*args)
        @subscriptions = Hash.new { |hash, key| hash[key] = [] }
      end
      def publish(event); end

      def subscribe(event_key, &handler)
        @subscriptions[event_key] << handler
      end

      def perge; end
      def start; end
      def stop; end
    end
  end
end
