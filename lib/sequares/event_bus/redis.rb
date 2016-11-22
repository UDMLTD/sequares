module Sequares
  module EventBus
    class Redis < Base
      attr_accessor :connection
      def initialize(connection=::Redis.new)
        @connection = connection
        super
      end

      def publish(event)
        @connection.publish "events", ::Marshal.dump(event)
      end

      def purge
        @connection.del "events"
      end

      def start
        @connection.subscribe("events") do |on|
          on.message do |_channel, event|
            @subscriptions[event.key].each do |subscription|
              subscription.call(event)
            end
          end
        end
      end
    end
  end
end
