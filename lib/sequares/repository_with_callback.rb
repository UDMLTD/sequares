module Sequares
  class RepositoryWithCallback < SimpleDelegator
    def callbacks
      @callbacks ||= Set.new
    end

    def add_callback(callable)
      callbacks
      @callbacks << callable
    end

    def save_history_for(entity)
      history_copy = entity.history.dup
      super(entity)
      callbacks.each do |callable|
        history_copy.uncommitted.each_slice(1_000) do |events|
          events.each do |event|
            callable.call(entity.class.new(entity.id), event)
          end
        end
      end
    end
  end
end
