module Sequares
  class Configuration
    attr_accessor :repository, :event_bus, :hashids_salt
    def initialize
      @repository = Sequares::Repository.new(::Redis.new)
      @hashids_salt = "sequares"
      @event_bus = Sequares::EventBus::Redis.new
    end
  end
end
