module Sequares
  class Configuration
    attr_accessor :repository, :event_bus
    def initialize
      @repository = Sequares::Repository.new(::Redis.new)
      @event_bus = Sequares::EventBus::Redis.new
    end
  end
end
