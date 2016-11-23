require "time"
require "forwardable"
require "hashids"
require "securerandom"
require "sequares/version"
require "sequares/configuration"
require "sequares/ext/string"
require "sequares/event_bus/base"
require "sequares/event_bus/memory"
require "sequares/event_bus/redis"
require "sequares/store/base"
require "sequares/store/redis"
require "sequares/store/memory"
require "sequares/command"
require "sequares/entity"
require "sequares/error"
require "sequares/event"
require "sequares/value_object"

module Sequares
  AlreadyLocked = StandardError.new
  class << self
    attr_writer :configuration

    # def_delegators :@configuration, :store

    # delegate :cache_key_for, to: :store

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset
      @configuration = Configuration.new
    end

    def with_lock(entities_array)
      entities = entities_array.each_slice(2).collect do |klass, id|
        entity = klass.load(id)
        configuration.store.lock(entity)
        entity.pending_events = []
        entity
      end

      yield(*entities) if block_given?
      entities
    ensure
      entities.each do |entity|
        configuration.store.save_history_for_aggregate(entity)
        configuration.store.unlock(entity)
        entity.pending_events.each do |event|
          configuration.event_bus.publish(event)
        end
      end
      entities
    end
  end
end
