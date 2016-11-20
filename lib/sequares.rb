require "time"
require "forwardable"
require "hashids"
require "securerandom"
require "sequares/version"
require "sequares/configuration"
require "sequares/helpers/structable"
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
  module Core; end
  class << self
    attr_writer :configuration
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
        entity
      end

      yield(*entities) if block_given?
      entities
    ensure
      entities.each do |entity|
        configuration.store.save_history_for_aggregate(entity)
        configuration.store.unlock(entity)
      end
      entities
    end
  end
end
