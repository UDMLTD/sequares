module Sequares
  class Configuration
    attr_accessor :store, :event_bus, :use_cache, :cache, :hashids_salt
    def initialize
      @store = Sequares::Store::Redis.new
      @use_cache = true
      @hashids_salt = "sequares"
      @event_bus = Sequares::EventBus::Redis.new
      # @cache = ::Memcached.new('localhost:11211')
    end
  end
end
