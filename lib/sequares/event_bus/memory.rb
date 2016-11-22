module Sequares
  module EventBus
    class Memory < Base
      def publish(event)
        @subscriptions[event.key].each do |subscription|
          subscription.call(event)
        end
      end
    end
  end
end
