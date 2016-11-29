module Sequares
  module EventBus
    class Base
      attr_accessor :subscriptions
      def initialize(*_args)
        @subscriptions = Hash.new { |hash, key| hash[key] = [] }
      end

      def publish(event); end

      def subscribe(event_key, &block)
        @subscriptions[event_key] << block if block_given?
      end

      def perge; end

      def start; end

      def stop; end
    end
  end
end
