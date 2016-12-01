module Sequares
  module Store
    class WithCallback < SimpleDelegator
      def callbacks
        @callbacks ||= Set.new
      end

      def add_callback(callable)
        callbacks
        @callbacks << callable
      end

      def save_history_for_aggregate(obj)
        callbacks.each do |callable|
          unsaved_history(obj).each do |event|
            callable.call(obj.class.new(obj.id), event)
          end
        end
        super(obj)
      end
    end
  end
end
